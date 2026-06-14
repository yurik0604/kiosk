package com.example.kiosk.kiosk

import com.example.kiosk.kiosk.rfid.RfidPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RfidPlugin(applicationContext).attach(flutterEngine)
    }
}
