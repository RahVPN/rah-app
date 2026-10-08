package com.example.rah_app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private companion object {
        const val REQ_VPN = 4242
    }

    private var pendingStart: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "rah/control").setMethodCallHandler { call, result ->
            when (call.method) {
                "state" -> result.success(CoreBus.state)
                "start" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("bad_args", "expected a map", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(this, CoreService::class.java)
                        .setAction(CoreService.ACTION_START)
                        .putExtra("protocol", args["protocol"] as? String)
                        .putExtra("scan", args["scan"] as? String)
                        .putExtra("noize", args["noize"] as? String)
                        .putExtra("ip", args["ip"] as? String)
                        .putExtra("http2", args["http2"] as? Boolean ?: false)
                        .putExtra("vpn", args["vpn"] as? Boolean ?: true)
                        .putExtra("shape", args["shape"] as? String)
                        .putExtra("region", args["region"] as? String)
                    beginStart(intent)
                    result.success(null)
                }
                "stop" -> {
                    startService(
                        Intent(this, CoreService::class.java).setAction(CoreService.ACTION_STOP)
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "rah/events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                CoreBus.sink = events
            }

            override fun onCancel(arguments: Any?) {
                CoreBus.sink = null
            }
        })
    }

    private fun beginStart(intent: Intent) {
        if (intent.getBooleanExtra("vpn", true)) {
            val prepare = VpnService.prepare(this)
            if (prepare != null) {
                pendingStart = intent
                @Suppress("DEPRECATION")
                startActivityForResult(prepare, REQ_VPN)
                return
            }
        }
        launch(intent)
    }

    private fun launch(intent: Intent) {
        if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQ_VPN) {
            val intent = pendingStart
            pendingStart = null
            if (resultCode == Activity.RESULT_OK && intent != null) {
                launch(intent)
            } else {
                CoreBus.state("error", "VPN permission was denied")
            }
            return
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
