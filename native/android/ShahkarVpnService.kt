package com.shahkar.connect.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.io.File

/**
 * TUN wrapper. libbox (compiled AAR from tool/build_libbox.sh) is loaded by
 * reflection so the app still compiles before the laptop produces the AAR.
 */
class ShahkarVpnService : VpnService() {
    private var tun: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTunnel()
            stopSelf()
            return START_NOT_STICKY
        }
        val json = intent?.getStringExtra(EXTRA_CONFIG) ?: return START_NOT_STICKY
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, notification())
        }
        stopLibboxOnly()
        val builder = Builder()
            .setSession("Shahkar")
            .setMtu(1500)
            .addAddress("172.19.0.1", 30)
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)
        if (Build.VERSION.SDK_INT >= 29) {
            builder.setMetered(false)
        }
        val established = try {
            builder.establish()
        } catch (e: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        tun = established
        val fd = established?.fd
        if (fd == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val cfg = File(cacheDir, "sing-box.json")
        cfg.writeText(json)
        try {
            LibboxBridge.start(this, json, fd)
        } catch (e: Exception) {
            stopTunnel()
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    override fun onRevoke() {
        stopTunnel()
        stopSelf()
        super.onRevoke()
    }

    private fun stopTunnel() {
        stopLibboxOnly()
        try {
            tun?.close()
        } catch (_: Exception) {
        }
        tun = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun stopLibboxOnly() {
        try {
            LibboxBridge.stop()
        } catch (_: Exception) {
        }
    }

    private fun notification(): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Shahkar VPN", NotificationManager.IMPORTANCE_LOW),
            )
        }
        val b = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return b.setContentTitle("شاهکار")
            .setContentText("VPN")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .build()
    }

    companion object {
        const val EXTRA_CONFIG = "config"
        const val ACTION_STOP = "com.shahkar.connect.vpn.STOP"
        private const val CHANNEL = "shahkar.vpn"
        private const val NOTIF_ID = 42
    }
}
