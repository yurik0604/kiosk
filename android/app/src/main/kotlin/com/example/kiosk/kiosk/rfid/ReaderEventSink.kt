package com.example.kiosk.kiosk.rfid

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

/**
 * Thin wrapper around the EventChannel sink that:
 *   - hops to the main thread (EventChannel requires it),
 *   - tolerates a null sink (events before Dart subscribes are dropped),
 *   - exposes a small typed API matching the Dart `ReaderEvent` sealed class.
 */
class ReaderEventSink {
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var sink: EventChannel.EventSink? = null

    /** EPCs already seen during the current inventory run. */
    private val seenEpcs: MutableSet<String> = ConcurrentHashMap.newKeySet()
    @Volatile
    private var preventDuplicates: Boolean = true

    fun attach(sink: EventChannel.EventSink) {
        this.sink = sink
    }

    fun detach() {
        sink = null
    }

    /** Toggle dedup at runtime. Does not clear the existing seen-set. */
    fun setPreventDuplicates(enabled: Boolean) {
        preventDuplicates = enabled
    }

    /**
     * Reset the seen-set. Drivers MUST call this at the start of every
     * inventory run so the next start is fresh.
     */
    fun resetDedup() {
        seenEpcs.clear()
    }

    fun emitStatus(status: String, message: String? = null) {
        send(
            mapOf(
                "type" to "status",
                "status" to status,
                "message" to message,
            )
        )
    }

    /**
     * @param tags list of maps; each must contain `epc` and `readTime`
     *             (ISO-8601 UTC string). Other fields optional.
     *
     * If duplicate prevention is enabled, EPCs already seen in this inventory
     * run are dropped. `HashSet.add()` is O(1) and atomically tests-and-inserts,
     * so we do one operation per tag rather than separate contains+put.
     */
    fun emitTags(tags: List<Map<String, Any?>>) {
        if (tags.isEmpty()) return
        val outbound = if (!preventDuplicates) {
            tags
        } else {
            tags.filter { t ->
                val epc = t["epc"] as? String ?: return@filter true
                seenEpcs.add(epc) // true => newly inserted (not a duplicate)
            }
        }
        if (outbound.isEmpty()) return
        for (t in outbound) {
            Log.d(
                TAG,
                "tag epc=${t["epc"]} ant=${t["antenna"]} rssi=${t["rssi"]} " +
                    "ch=${t["channelIndex"]} seen=${t["tagSeenCount"]} t=${t["readTime"]}",
            )
        }
        send(
            mapOf(
                "type" to "tags",
                "tags" to outbound,
            )
        )
    }

    fun emitError(message: String, code: String? = null, fatal: Boolean = false) {
        send(
            mapOf(
                "type" to "error",
                "message" to message,
                "code" to code,
                "fatal" to fatal,
            )
        )
    }

    private fun send(payload: Map<String, Any?>) {
        val s = sink ?: return
        mainHandler.post { s.success(payload) }
    }

    companion object {
        private const val TAG = "RfidReader"
    }

    object Status {
        const val OFFLINE = "offline"
        const val CONNECTING = "connecting"
        const val CONNECTED = "connected"
        const val READING = "reading"
        const val IDLE = "idle"
        const val DISCONNECTED = "disconnected"
        const val ERROR = "error"
    }
}
