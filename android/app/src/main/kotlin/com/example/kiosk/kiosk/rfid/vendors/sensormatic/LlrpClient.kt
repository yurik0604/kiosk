package com.example.kiosk.kiosk.rfid.vendors.sensormatic

import android.util.Log
import com.example.kiosk.kiosk.rfid.ReaderEventSink
import org.llrp.ltk.generated.enumerations.GetReaderCapabilitiesRequestedData
import org.llrp.ltk.generated.enumerations.KeepaliveTriggerType
import org.llrp.ltk.generated.enumerations.StatusCode
import org.llrp.ltk.generated.messages.ADD_ROSPEC
import org.llrp.ltk.generated.messages.ADD_ROSPEC_RESPONSE
import org.llrp.ltk.generated.messages.DELETE_ROSPEC
import org.llrp.ltk.generated.messages.DISABLE_ROSPEC
import org.llrp.ltk.generated.messages.ENABLE_ROSPEC
import org.llrp.ltk.generated.messages.GET_READER_CAPABILITIES
import org.llrp.ltk.generated.messages.GET_READER_CAPABILITIES_RESPONSE
import org.llrp.ltk.generated.messages.KEEPALIVE
import org.llrp.ltk.generated.messages.READER_EVENT_NOTIFICATION
import org.llrp.ltk.generated.messages.RO_ACCESS_REPORT
import org.llrp.ltk.generated.messages.SET_READER_CONFIG
import org.llrp.ltk.generated.messages.START_ROSPEC
import org.llrp.ltk.generated.messages.STOP_ROSPEC
import org.llrp.ltk.generated.parameters.EPCData
import org.llrp.ltk.generated.parameters.EPC_96
import org.llrp.ltk.generated.parameters.KeepaliveSpec
import org.llrp.ltk.generated.parameters.ReaderEventNotificationSpec
import org.llrp.ltk.generated.parameters.RegulatoryCapabilities
import org.llrp.ltk.generated.parameters.TagReportData
import org.llrp.ltk.generated.parameters.UHFBandCapabilities
import org.llrp.ltk.net.LLRPConnectionAttemptFailedException
import org.llrp.ltk.net.LLRPConnector
import org.llrp.ltk.net.LLRPEndpoint
import org.llrp.ltk.types.Bit
import org.llrp.ltk.types.LLRPMessage
import org.llrp.ltk.types.UnsignedInteger
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * LLRP client for the IDX-4000 family. Pure LTK — no vendor extensions.
 *
 * Lifecycle:
 *   connect() → opens TCP, configures reader, adds the ROSpec (disabled),
 *               emits CONNECTED, then IDLE.
 *   startInventory() → enables + starts the ROSpec, emits READING.
 *   stopInventory()  → stops + disables the ROSpec, emits IDLE.
 *   close()          → deletes the ROSpec, closes the socket.
 *
 * RO_ACCESS_REPORT batches are forwarded to [sink] as tag events. Duplicate
 * suppression (if requested) is centralised in [ReaderEventSink].
 */
class LlrpClient(
    private val host: String,
    private val port: Int,
    private val antennaMask: Int,
    private val txPowerDbm: Double,
    private val sink: ReaderEventSink,
) : LLRPEndpoint {

    private val connector = LLRPConnector(this, host, port)
    @Volatile private var closed = false

    fun connect() {
        try {
            connector.connect(CONNECT_TIMEOUT_MS.toLong())
        } catch (e: LLRPConnectionAttemptFailedException) {
            throw IllegalStateException("LLRP connect to $host:$port failed: ${e.message}", e)
        }

        sink.emitStatus(ReaderEventSink.Status.CONNECTED)

        val caps = fetchCapabilitiesAndLog()
        configureReader()
        addRoSpec(caps)
        sink.emitStatus(ReaderEventSink.Status.IDLE)
    }

    fun startInventory() {
        // Clear dedup state so each inventory run starts fresh.
        sink.resetDedup()
        send(ENABLE_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) })
        send(START_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) })
        sink.emitStatus(ReaderEventSink.Status.READING)
    }

    fun stopInventory() {
        try { send(STOP_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) }) } catch (_: Throwable) {}
        try { send(DISABLE_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) }) } catch (_: Throwable) {}
        sink.emitStatus(ReaderEventSink.Status.IDLE)
    }

    fun close() {
        if (closed) return
        closed = true
        try {
            send(STOP_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) })
            send(DISABLE_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) })
            send(DELETE_ROSPEC().apply { roSpecID = UnsignedInteger(ROSPEC_ID) })
        } catch (_: Throwable) {
            // best-effort cleanup
        }
        try { connector.disconnect() } catch (_: Throwable) {}
        sink.emitStatus(ReaderEventSink.Status.OFFLINE)
    }

    // --- setup helpers -----------------------------------------------------

    /**
     * Pulls device + regulatory caps so we know the antenna count and (if
     * the firmware reports it) the actual TransmitPowerLevelTable for a
     * better dBm→index mapping. The IDX-4000 firmware tested in the field
     * returns empty responses — that's tolerated and we fall back to a
     * conservative default.
     */
    private fun fetchCapabilitiesAndLog(): CapabilitiesSummary {
        var maxIndex = DEFAULT_POWER_INDEX
        var antennaCount = 1
        var powerTable: List<Pair<Int, Int>> = emptyList()

        queryCaps(GetReaderCapabilitiesRequestedData.General_Device_Capabilities)
            ?.getGeneralDeviceCapabilities()?.let { gen ->
                antennaCount = gen.getMaxNumberOfAntennaSupported()?.toInteger() ?: 1
                Log.i(
                    TAG,
                    "reader: mfr=${gen.getDeviceManufacturerName()?.toInteger()} " +
                        "model=${gen.getModelName()?.toInteger()} " +
                        "fw=${gen.getReaderFirmwareVersion()} antennas=$antennaCount",
                )
            } ?: Log.w(TAG, "reader did not report GeneralDeviceCapabilities")

        val reg: RegulatoryCapabilities? =
            queryCaps(GetReaderCapabilitiesRequestedData.Regulatory_Capabilities)
                ?.getRegulatoryCapabilities()
        val uhf: UHFBandCapabilities? = reg?.getUHFBandCapabilities()
        uhf?.getTransmitPowerLevelTableEntryList()?.let { table ->
            powerTable = table.mapNotNull { entry ->
                val idx = entry.getIndex()?.toInteger() ?: return@mapNotNull null
                val cdbm = entry.getTransmitPowerValue()?.toInteger() ?: return@mapNotNull null
                idx to cdbm
            }
            Log.i(TAG, "powerTable: ${powerTable.joinToString(", ") { "idx=${it.first}:${it.second}cdBm" }}")
            powerTable.maxOfOrNull { it.first }?.let { maxIndex = it }
        } ?: Log.w(TAG, "reader did not report TransmitPowerLevelTable")

        return CapabilitiesSummary(
            maxPowerIndex = maxIndex,
            antennaCount = antennaCount,
            powerTable = powerTable,
        )
    }

    private fun queryCaps(which: Int): GET_READER_CAPABILITIES_RESPONSE? {
        return try {
            val req = GET_READER_CAPABILITIES().apply {
                requestedData = GetReaderCapabilitiesRequestedData(which)
            }
            send(req) as? GET_READER_CAPABILITIES_RESPONSE
        } catch (t: Throwable) {
            Log.w(TAG, "GET_READER_CAPABILITIES($which) failed: ${t.message}")
            null
        }
    }

    /**
     * Bare-minimum reader config: keepalives only. We deliberately do NOT
     * push session/power through SET_READER_CONFIG — on the IDX-4000 the
     * firmware rejects such overrides with M_OverflowParameter. Per-antenna
     * power instead rides on the AntennaConfiguration inside each
     * InventoryParameterSpec (see LlrpRoSpecBuilder).
     */
    private fun configureReader() {
        val cfg = SET_READER_CONFIG().apply {
            resetToFactoryDefault = Bit(false)
            keepaliveSpec = KeepaliveSpec().apply {
                keepaliveTriggerType = KeepaliveTriggerType(KeepaliveTriggerType.Periodic)
                periodicTriggerValue = UnsignedInteger(KEEPALIVE_MS)
            }
            readerEventNotificationSpec = ReaderEventNotificationSpec()
        }
        try {
            send(cfg)
        } catch (t: Throwable) {
            Log.w(TAG, "SET_READER_CONFIG (keepalive) warning: ${t.message}")
        }
    }

    private fun addRoSpec(caps: CapabilitiesSummary) {
        // Clamp the user's mask to antennas that actually exist — an
        // AntennaConfiguration referencing a non-existent antenna is a common
        // cause of M_ParameterError on ADD_ROSPEC.
        val effectiveMask = if (caps.antennaCount > 0) {
            val readerMask = (1 shl caps.antennaCount) - 1
            antennaMask and readerMask
        } else antennaMask
        val powerIndex = mapDbmToIndex(txPowerDbm, caps)
        Log.i(
            TAG,
            "ROSpec: powerDbm=$txPowerDbm → powerIdx=$powerIndex " +
                "rawMask=0x${antennaMask.toString(16)} effMask=0x${effectiveMask.toString(16)} " +
                "antennaCount=${caps.antennaCount}",
        )
        val spec = LlrpRoSpecBuilder.continuousInventory(
            roSpecId = ROSPEC_ID,
            antennaMask = effectiveMask,
            txPowerIndex = powerIndex,
        )
        val req = ADD_ROSPEC().apply { setROSpec(spec) }
        val resp = send(req) as? ADD_ROSPEC_RESPONSE
        val llrpStatus = resp?.getLLRPStatus()
        val statusInt = llrpStatus?.getStatusCode()?.toInteger()
        if (statusInt != null && statusInt != StatusCode.M_Success) {
            throw IllegalStateException(
                "ADD_ROSPEC failed: ${describeLlrpStatus(llrpStatus)}"
            )
        }
    }

    /**
     * If the reader reported a power table, pick the entry whose advertised
     * dBm is closest to the requested value. Otherwise return a conservative
     * default (1 = lowest valid index per LLRP) and let the reader clamp.
     *
     * Power table values are in centi-dBm per LLRP 1.1.
     */
    private fun mapDbmToIndex(dbm: Double, caps: CapabilitiesSummary): Int {
        if (caps.powerTable.isEmpty()) return DEFAULT_POWER_INDEX
        val targetCdbm = (dbm * 100).toInt()
        return caps.powerTable
            .minByOrNull { kotlin.math.abs(it.second - targetCdbm) }
            ?.first
            ?: DEFAULT_POWER_INDEX
    }

    private fun describeLlrpStatus(
        status: org.llrp.ltk.generated.parameters.LLRPStatus,
    ): String {
        val parts = mutableListOf<String>()
        status.getStatusCode()?.let { parts += "code=$it" }
        status.getErrorDescription()?.toString()?.takeIf { it.isNotBlank() }?.let {
            parts += "desc=\"$it\""
        }
        status.getParameterError()?.let { pe ->
            parts += "paramErr(type=${pe.getParameterType()?.toInteger()}, " +
                "code=${pe.getErrorCode()})"
            pe.getFieldError()?.let { fe ->
                parts += "fieldErr(num=${fe.getFieldNum()?.toInteger()}, " +
                    "code=${fe.getErrorCode()})"
            }
        }
        status.getFieldError()?.let { fe ->
            parts += "fieldErr(num=${fe.getFieldNum()?.toInteger()}, " +
                "code=${fe.getErrorCode()})"
        }
        return parts.joinToString(" ")
    }

    private fun send(msg: LLRPMessage): LLRPMessage? {
        if (closed) throw IllegalStateException("Client closed")
        return connector.transact(msg, TRANSACT_TIMEOUT_MS.toLong())
    }

    // --- LLRPEndpoint callbacks (LTK invokes these on its own thread) ----

    override fun messageReceived(message: LLRPMessage) {
        when (message) {
            is RO_ACCESS_REPORT -> handleReport(message)
            is READER_EVENT_NOTIFICATION -> { /* could surface connection events here */ }
            is KEEPALIVE -> { /* LTK ACKs automatically */ }
            else -> { /* other async messages ignored */ }
        }
    }

    override fun errorOccured(s: String) {
        Log.e(TAG, "LTK error: $s")
        sink.emitError(s, code = "LTK_ERROR", fatal = false)
    }

    private fun handleReport(report: RO_ACCESS_REPORT) {
        val tags = report.tagReportDataList ?: return
        if (tags.isEmpty()) return
        val out = ArrayList<Map<String, Any?>>(tags.size)
        for (data in tags) {
            out += toTagMap(data) ?: continue
        }
        sink.emitTags(out)
    }

    private fun toTagMap(data: TagReportData): Map<String, Any?>? {
        val epcParam = data.getEPCParameter() ?: return null
        val epcHex = when (epcParam) {
            is EPC_96 -> epcParam.getEPC().toString().uppercase(Locale.US)
            is EPCData -> epcParam.getEPC().toString().uppercase(Locale.US)
            else -> epcParam.toString().uppercase(Locale.US)
        }
        val readMicros = data.getFirstSeenTimestampUTC()?.getMicroseconds()?.toLong()
        return mapOf(
            "epc" to epcHex,
            "readTime" to (readMicros?.let { microsToIso(it) } ?: nowIso()),
            "rssi" to data.getPeakRSSI()?.getPeakRSSI()?.toInteger(),
            "antenna" to data.getAntennaID()?.getAntennaID()?.toInteger(),
            "channelIndex" to data.getChannelIndex()?.getChannelIndex()?.toInteger(),
            "tagSeenCount" to data.getTagSeenCount()?.getTagCount()?.toInteger(),
        )
    }

    private fun microsToIso(micros: Long): String {
        val date = Date(micros / 1000L)
        return isoFormatter.get()!!.format(date)
    }

    private fun nowIso(): String = isoFormatter.get()!!.format(Date())

    private data class CapabilitiesSummary(
        val maxPowerIndex: Int,
        val antennaCount: Int,
        /** (index, centi-dBm) pairs from the reader, in declaration order. */
        val powerTable: List<Pair<Int, Int>>,
    )

    companion object {
        private const val TAG = "LlrpClient"
        private const val ROSPEC_ID = 1L
        private const val CONNECT_TIMEOUT_MS = 8_000
        private const val TRANSACT_TIMEOUT_MS = 8_000
        private const val KEEPALIVE_MS = 10_000L
        private const val DEFAULT_POWER_INDEX = 1

        private val isoFormatter = object : ThreadLocal<SimpleDateFormat>() {
            override fun initialValue(): SimpleDateFormat {
                return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
            }
        }
    }
}
