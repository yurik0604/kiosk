package com.example.kiosk.kiosk.rfid.vendors.sensormatic

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.kiosk.kiosk.rfid.ReaderEventSink
import java.util.concurrent.Executors

/**
 * Holds the LLRP socket + LTK client across Activity recreation. The Service
 * is bound by `SensormaticIdx4000Driver`; commands flow through the binder.
 *
 * Why a foreground service rather than a plain coroutine:
 *  - the kiosk app is the only user-facing app on the device but Android can
 *    still freeze background sockets,
 *  - LLRP keepalives must keep flowing or the reader will tear down the session,
 *  - we want to survive transient Activity recreation without dropping the
 *    inventory stream.
 */
class LlrpForegroundService : Service() {

    private val executor = Executors.newSingleThreadExecutor()
    private var client: LlrpClient? = null

    // The client for the CURRENT connect attempt. Held in a @Volatile field —
    // separate from [client], which is only set on a *successful* connect — so
    // that cancelConnect() can reach and abort an in-flight attempt from the
    // binder thread while the executor thread is blocked inside connect().
    @Volatile
    private var connectingClient: LlrpClient? = null

    @Volatile
    private var sink: ReaderEventSink? = null

    inner class LocalBinder : Binder() {
        fun attach(s: ReaderEventSink) { sink = s }
        fun detach(s: ReaderEventSink) {
            if (sink === s) sink = null
        }
        fun connect(config: Map<String, Any?>) = this@LlrpForegroundService.handleConnect(config)
        fun disconnect() = this@LlrpForegroundService.handleDisconnect()
        fun cancelConnect() = this@LlrpForegroundService.handleCancelConnect()
        fun startInventory() = this@LlrpForegroundService.handleStart()
        fun stopInventory() = this@LlrpForegroundService.handleStop()
    }

    private val binder = LocalBinder()

    override fun onCreate() {
        super.onCreate()
        ensureChannel(this)
        val notif = buildNotification("Idle")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        executor.execute {
            try { client?.close() } catch (_: Throwable) { /* ignore */ }
            client = null
        }
        executor.shutdown()
        super.onDestroy()
    }

    private fun handleConnect(config: Map<String, Any?>) {
        executor.execute {
            try {
                client?.close()
                val host = (config["host"] as? String).orEmpty()
                if (host.isBlank()) {
                    sink?.emitError("host is empty", code = "INVALID_CONFIG", fatal = true)
                    return@execute
                }
                val port = (config["port"] as? Number)?.toInt() ?: 5084
                val antennaMask = (config["antennaMask"] as? Number)?.toInt() ?: 0xFFFF
                val txPowerDbm = (config["txPowerDbm"] as? Number)?.toDouble() ?: 30.0
                val preventDuplicates = (config["preventDuplicates"] as? Boolean) ?: true

                val s = requireNotNull(sink) { "EventSink not attached" }
                s.setPreventDuplicates(preventDuplicates)
                s.emitStatus(ReaderEventSink.Status.CONNECTING)
                updateNotification("Connecting to $host:$port")
                val c = LlrpClient(
                    host = host,
                    port = port,
                    antennaMask = antennaMask,
                    txPowerDbm = txPowerDbm,
                    sink = s,
                )
                // Publish BEFORE the blocking connect so cancelConnect() can
                // reach it while this thread is parked inside connect().
                connectingClient = c
                c.connect()
                client = c
                connectingClient = null
                updateNotification("Connected to $host")
            } catch (t: LlrpClient.CancelledException) {
                // User aborted the attempt — not an error.
                Log.i(TAG, "LLRP connect cancelled by user")
                connectingClient = null
                sink?.emitStatus(ReaderEventSink.Status.DISCONNECTED)
                updateNotification("Cancelled")
            } catch (t: Throwable) {
                Log.e(TAG, "LLRP connect failed", t)
                connectingClient = null
                sink?.emitError(t.message ?: t.toString(), code = "CONNECT_FAILED", fatal = true)
                updateNotification("Connect failed")
            }
        }
    }

    /**
     * Abort an in-flight connect. Runs the abort DIRECTLY on the binder thread
     * (not the single-thread executor, which is blocked inside connect()) so it
     * takes effect immediately instead of waiting out the connect timeout.
     */
    private fun handleCancelConnect() {
        connectingClient?.cancelConnect()
    }

    private fun handleDisconnect() {
        // Abort any in-flight attempt first, off the (possibly blocked) executor.
        connectingClient?.cancelConnect()
        executor.execute {
            try {
                client?.close()
            } catch (t: Throwable) {
                Log.w(TAG, "Disconnect: $t")
            } finally {
                client = null
                connectingClient = null
                sink?.emitStatus(ReaderEventSink.Status.DISCONNECTED)
                updateNotification("Disconnected")
            }
        }
    }

    private fun handleStart() {
        executor.execute {
            try {
                client?.startInventory()
                    ?: throw IllegalStateException("Not connected")
                updateNotification("Reading")
            } catch (t: Throwable) {
                Log.e(TAG, "Start inventory failed", t)
                sink?.emitError(t.message ?: t.toString(), code = "START_FAILED")
            }
        }
    }

    private fun handleStop() {
        executor.execute {
            try {
                client?.stopInventory()
                updateNotification("Connected")
            } catch (t: Throwable) {
                Log.w(TAG, "Stop inventory: $t")
                sink?.emitError(t.message ?: t.toString(), code = "STOP_FAILED")
            }
        }
    }

    private fun updateNotification(state: String) {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(state))
    }

    private fun buildNotification(state: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("RFID Reader")
            .setContentText(state)
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val TAG = "LlrpService"
        private const val CHANNEL_ID = "rfid_reader"
        private const val NOTIF_ID = 0xF1D

        private fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "RFID Reader",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Keeps the LLRP connection to the RFID reader alive"
                    setShowBadge(false)
                }
            )
        }
    }
}
