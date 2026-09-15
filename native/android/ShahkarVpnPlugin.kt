package com.shahkar.connect.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object ShahkarVpnPlugin {
    const val METHODS = "com.shahkar.connect/vpn"
    const val STATE = "com.shahkar.connect/vpn_state"
    const val STATS = "com.shahkar.connect/vpn_stats"
    const val REQUEST_VPN = 0x51A1

    fun register(activity: Activity, engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger
        var stateSink: EventChannel.EventSink? = null
        MethodChannel(messenger, METHODS).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "start" -> {
                    val json = call.argument<String>("json") ?: ""
                    val prep = VpnService.prepare(activity)
                    if (prep != null) {
                        activity.startActivityForResult(prep, REQUEST_VPN)
                        result.error("NEED_PERMISSION", "VPN permission required", null)
                        return@setMethodCallHandler
                    }
                    val i = Intent(activity, ShahkarVpnService::class.java)
                    i.putExtra(ShahkarVpnService.EXTRA_CONFIG, json)
                    activity.startForegroundService(i)
                    stateSink?.success(mapOf("kind" to "connected"))
                    result.success(null)
                }
                "stop" -> {
                    activity.stopService(Intent(activity, ShahkarVpnService::class.java))
                    stateSink?.success(mapOf("kind" to "idle"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, STATE).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                stateSink = events
            }
            override fun onCancel(arguments: Any?) {
                stateSink = null
            }
        })
        EventChannel(messenger, STATS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {}
            override fun onCancel(arguments: Any?) {}
        })
    }
}
