package com.example.kiosk.kiosk.rfid.vendors.sensormatic

import org.llrp.ltk.generated.enumerations.AISpecStopTriggerType
import org.llrp.ltk.generated.enumerations.AirProtocols
import org.llrp.ltk.generated.enumerations.ROReportTriggerType
import org.llrp.ltk.generated.enumerations.ROSpecStartTriggerType
import org.llrp.ltk.generated.enumerations.ROSpecState
import org.llrp.ltk.generated.enumerations.ROSpecStopTriggerType
import org.llrp.ltk.generated.parameters.AISpec
import org.llrp.ltk.generated.parameters.AISpecStopTrigger
import org.llrp.ltk.generated.parameters.InventoryParameterSpec
import org.llrp.ltk.generated.parameters.ROBoundarySpec
import org.llrp.ltk.generated.parameters.ROReportSpec
import org.llrp.ltk.generated.parameters.ROSpec
import org.llrp.ltk.generated.parameters.ROSpecStartTrigger
import org.llrp.ltk.generated.parameters.ROSpecStopTrigger
import org.llrp.ltk.generated.parameters.TagReportContentSelector
import org.llrp.ltk.types.Bit
import org.llrp.ltk.types.UnsignedInteger
import org.llrp.ltk.types.UnsignedShort
import org.llrp.ltk.types.UnsignedShortArray

/**
 * Builds the "continuous inventory" ROSpec the kiosk uses:
 *   - start immediately on ENABLE_ROSPEC,
 *   - never auto-stop (host-driven via STOP_ROSPEC),
 *   - one InventoryParameterSpec with protocolID only — the IDX-4000
 *     firmware rejects ANY AntennaConfiguration here (M_ParameterError) and
 *     rejects per-antenna power/session overrides via SET_READER_CONFIG
 *     (M_OverflowParameter). Power and session are reader-side configuration.
 *   - report on every tag (N=1) with RSSI, antenna, channel, timestamp and
 *     seen-count.
 *
 * `txPowerIndex` is currently unused by the Sensormatic driver; kept in the
 * signature so other vendors with stricter LLRP conformance can plug in.
 */
object LlrpRoSpecBuilder {

    fun continuousInventory(
        roSpecId: Long,
        antennaMask: Int,
        txPowerIndex: Int,
    ): ROSpec {
        return ROSpec().apply {
            roSpecID = UnsignedInteger(roSpecId)
            priority = org.llrp.ltk.types.UnsignedByte(0)
            currentState = ROSpecState(ROSpecState.Disabled)
            roBoundarySpec = buildBoundary()
            addToSpecParameterList(buildAiSpec(antennaMask, txPowerIndex))
            roReportSpec = buildReportSpec()
        }
    }

    private fun buildBoundary(): ROBoundarySpec = ROBoundarySpec().apply {
        roSpecStartTrigger = ROSpecStartTrigger().apply {
            roSpecStartTriggerType = ROSpecStartTriggerType(ROSpecStartTriggerType.Immediate)
        }
        roSpecStopTrigger = ROSpecStopTrigger().apply {
            roSpecStopTriggerType = ROSpecStopTriggerType(ROSpecStopTriggerType.Null)
            durationTriggerValue = UnsignedInteger(0)
        }
    }

    private fun buildAiSpec(antennaMask: Int, txPowerIndex: Int): AISpec {
        val antennas = expandMask(antennaMask)
        val antennaIds = UnsignedShortArray()
        if (antennas.isEmpty()) {
            // "0" means "all antennas" in LLRP.
            antennaIds.add(UnsignedShort(0))
        } else {
            antennas.forEach { antennaIds.add(UnsignedShort(it)) }
        }
        return AISpec().apply {
            this.antennaIDs = antennaIds
            aiSpecStopTrigger = AISpecStopTrigger().apply {
                aiSpecStopTriggerType = AISpecStopTriggerType(AISpecStopTriggerType.Null)
                durationTrigger = UnsignedInteger(0)
            }
            addToInventoryParameterSpecList(
                InventoryParameterSpec().apply {
                    inventoryParameterSpecID = UnsignedShort(1)
                    protocolID = AirProtocols(AirProtocols.EPCGlobalClass1Gen2)
                    // NOTE: IDX-4000 firmware rejects ANY AntennaConfiguration
                    // here with M_ParameterError — power/session control via
                    // LLRP is firmware-locked. Reader uses its own configured
                    // power (set on the reader's web UI). txPowerIndex is
                    // intentionally unused for this vendor.
                }
            )
        }
    }

    private fun buildReportSpec(): ROReportSpec = ROReportSpec().apply {
        roReportTrigger = ROReportTriggerType(
            ROReportTriggerType.Upon_N_Tags_Or_End_Of_ROSpec
        )
        n = UnsignedShort(1) // report every tag
        tagReportContentSelector = TagReportContentSelector().apply {
            enableROSpecID = Bit(false)
            enableSpecIndex = Bit(false)
            enableInventoryParameterSpecID = Bit(false)
            enableAntennaID = Bit(true)
            enableChannelIndex = Bit(true)
            enablePeakRSSI = Bit(true)
            enableFirstSeenTimestamp = Bit(true)
            enableLastSeenTimestamp = Bit(false)
            enableTagSeenCount = Bit(true)
            enableAccessSpecID = Bit(false)
        }
    }

    private fun expandMask(mask: Int): List<Int> {
        if (mask <= 0) return emptyList()
        val out = ArrayList<Int>()
        for (bit in 0 until 16) {
            if ((mask shr bit) and 0x1 == 1) out += (bit + 1)
        }
        return out
    }
}
