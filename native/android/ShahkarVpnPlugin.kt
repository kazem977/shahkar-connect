package com.shahkar.connect.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class ShahkarVpnPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {
    companion object {
        const val METHODS = "com.shahkar.connect/vpn"
        const val STATE = "com.shahkar.connect/vpn_state"
        const val STATS = "com.shahkar.connect/vpn_stats"
        const val REQUEST_VPN = 0x51A1

        fun register(activity: Activity, engine: FlutterEngine) {
            engine.plugins.add(ShahkarVpnPlugin())
        }
    }

    private var activity: Activity? = null
    private var channel: MethodChannel? = null
    private var stateSink: EventChannel.EventSink? = null
    private var pendingJson: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        channel = MethodChannel(messenger, METHODS).also { it.setMethodCallHandler(this) }
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "VPN plugin has no activity", null)
            return
        }
        when (call.method) {
            "start" -> {
                val json = call.argument<String>("json") ?: ""
                val prep = VpnService.prepare(act)
                if (prep != null) {
                    pendingJson = json
                    pendingResult = result
                    act.startActivityForResult(prep, REQUEST_VPN)
                    return
                }
                startService(act, json, result)
            }
            "stop" -> {
                val stop = Intent(act, ShahkarVpnService::class.java)
                stop.action = ShahkarVpnService.ACTION_STOP
                act.startService(stop)
                act.stopService(Intent(act, ShahkarVpnService::class.java))
                stateSink?.success(mapOf("kind" to "idle"))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_VPN) return false
        val json = pendingJson
        val pending = pendingResult
        pendingJson = null
        pendingResult = null
        val act = activity
        if (pending == null || act == null) return true
        if (resultCode != Activity.RESULT_OK || json == null) {
            pending.error("NEED_PERMISSION", "VPN permission required", null)
            return true
        }
        startService(act, json, pending)
        return true
    }

    private fun startService(act: Activity, json: String, result: MethodChannel.Result) {
        val intent = Intent(act, ShahkarVpnService::class.java)
        intent.putExtra(ShahkarVpnService.EXTRA_CONFIG, json)
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                act.startForegroundService(intent)
            } else {
                act.startService(intent)
            }
            stateSink?.success(mapOf("kind" to "connected"))
            result.success(null)
        } catch (e: Exception) {
            stateSink?.success(mapOf("kind" to "error", "message" to (e.message ?: "vpn")))
            result.error("START", e.message, null)
        }
    }
}
