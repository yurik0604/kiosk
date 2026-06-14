package com.example.kiosk.kiosk.rfid

import android.content.Context
import android.util.Log
import com.example.kiosk.kiosk.rfid.vendors.sensormatic.SensormaticIdx4000Driver
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Single entry-point between Dart and the active vendor driver.
 *
 * Wired from MainActivity.configureFlutterEngine().
 *
 *  - `kiosk/rfid` (MethodChannel): connect / disconnect / startInventory /
 *    stopInventory / dispose
 *  - `kiosk/rfid/events` (EventChannel): status + tags + errors stream
 *
 * Vendor selection happens in [resolveDriverFactory]. To add a new vendor,
 * implement [VendorDriver] and add a branch there.
 */
class RfidPlugin(private val context: Context) {

    private val eventSink = ReaderEventSink()
    private var driver: VendorDriver? = null

    fun attach(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    eventSink.attach(sink)
                }
                override fun onCancel(args: Any?) {
                    eventSink.detach()
                }
            }
        )
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "connect" -> {
                    val args = call.arguments<Map<String, Any?>>()
                        ?: throw IllegalArgumentException("connect() requires config map")
                    val vendorId = args["vendor"] as? String
                        ?: throw IllegalArgumentException("Missing 'vendor' in config")
                    ensureDriver(vendorId)
                    driver!!.connect(args)
                    result.success(null)
                }
                "disconnect" -> {
                    driver?.disconnect()
                    result.success(null)
                }
                "startInventory" -> {
                    requireDriver().startInventory()
                    result.success(null)
                }
                "stopInventory" -> {
                    requireDriver().stopInventory()
                    result.success(null)
                }
                "dispose" -> {
                    driver?.dispose()
                    driver = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            Log.e(TAG, "RFID call ${call.method} failed", e)
            result.error(
                e.javaClass.simpleName,
                e.message ?: "unknown error",
                null,
            )
        }
    }

    private fun ensureDriver(vendorId: String) {
        val existing = driver
        if (existing != null && existing.vendorId == vendorId) return
        existing?.dispose()
        driver = resolveDriverFactory(vendorId).create(context, eventSink)
    }

    private fun requireDriver(): VendorDriver =
        driver ?: throw IllegalStateException("No active reader; call connect first")

    private fun resolveDriverFactory(vendorId: String): VendorDriverFactory {
        return when (vendorId) {
            VendorDriver.VENDOR_SENSORMATIC_IDX4000 -> VendorDriverFactory { ctx, sink ->
                SensormaticIdx4000Driver(ctx, sink)
            }
            else -> throw IllegalArgumentException("Unknown vendor: $vendorId")
        }
    }

    companion object {
        private const val TAG = "RfidPlugin"
        private const val METHOD_CHANNEL = "kiosk/rfid"
        private const val EVENT_CHANNEL = "kiosk/rfid/events"
    }
}
