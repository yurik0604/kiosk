package com.example.kiosk.kiosk.rfid

import android.content.Context

/**
 * Common interface every vendor implementation must satisfy.
 *
 * The plugin holds at most one active driver at a time. Switching readers =
 * dispose the previous driver and create a new one.
 *
 * Drivers MUST NOT touch the EventChannel directly — they emit through
 * [ReaderEventSink], which the plugin marshals back to Dart on the main thread.
 */
interface VendorDriver {
    val vendorId: String

    /** Open the transport and prepare the reader. */
    fun connect(config: Map<String, Any?>)

    /** Close the transport. Should be idempotent. */
    fun disconnect()

    /**
     * Abort an in-flight [connect] attempt. Must take effect promptly (i.e.
     * without waiting out the full connect timeout) and be a no-op if no
     * connect is in progress.
     */
    fun cancelConnect()

    /** Begin inventory (LLRP ENABLE_ROSPEC / SDK start). */
    fun startInventory()

    /** Halt inventory but keep the transport open. */
    fun stopInventory()

    /** Final teardown; instance is unusable after this returns. */
    fun dispose()

    companion object {
        const val VENDOR_SENSORMATIC_IDX4000 = "sensormatic_idx4000"
    }
}

/** Driver factory — pure function from vendor id to a fresh driver. */
fun interface VendorDriverFactory {
    fun create(context: Context, eventSink: ReaderEventSink): VendorDriver
}
