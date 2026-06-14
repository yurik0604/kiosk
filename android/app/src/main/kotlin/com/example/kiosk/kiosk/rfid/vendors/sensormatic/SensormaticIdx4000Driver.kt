package com.example.kiosk.kiosk.rfid.vendors.sensormatic

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.IBinder
import com.example.kiosk.kiosk.rfid.ReaderEventSink
import com.example.kiosk.kiosk.rfid.VendorDriver

/**
 * Driver for the Sensormatic IDX-4000 (and family) — communicates over
 * EPCglobal LLRP 1.1 / TCP.
 *
 * The driver itself is a thin shell: it starts a foreground [LlrpForegroundService]
 * which owns the actual socket + LTK client. This way the connection survives
 * Activity recreation (rotation, transient backgrounding) and the OS won't
 * silently kill the long-lived TCP socket.
 */
class SensormaticIdx4000Driver(
    private val context: Context,
    private val eventSink: ReaderEventSink,
) : VendorDriver {

    override val vendorId: String = VendorDriver.VENDOR_SENSORMATIC_IDX4000

    private var binder: LlrpForegroundService.LocalBinder? = null
    private var pendingConfig: Map<String, Any?>? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            val local = service as LlrpForegroundService.LocalBinder
            binder = local
            local.attach(eventSink)
            pendingConfig?.let { local.connect(it) }
            pendingConfig = null
        }

        override fun onServiceDisconnected(name: ComponentName) {
            binder = null
        }
    }

    override fun connect(config: Map<String, Any?>) {
        pendingConfig = config
        val intent = Intent(context, LlrpForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
        if (binder == null) {
            context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
        } else {
            binder?.connect(config)
            pendingConfig = null
        }
    }

    override fun disconnect() {
        binder?.disconnect()
    }

    override fun startInventory() {
        binder?.startInventory()
            ?: throw IllegalStateException("Reader not connected")
    }

    override fun stopInventory() {
        binder?.stopInventory()
            ?: throw IllegalStateException("Reader not connected")
    }

    override fun dispose() {
        try {
            binder?.disconnect()
            binder?.detach(eventSink)
            context.unbindService(connection)
        } catch (_: IllegalArgumentException) {
            // Service was never bound; ignore.
        }
        binder = null
        context.stopService(Intent(context, LlrpForegroundService::class.java))
    }
}
