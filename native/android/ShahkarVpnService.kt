package com.shahkar.connect.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
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
        val json = intent?.getStringExtra(EXTRA_CONFIG) ?: return START_NOT_STICKY
        startForeground(NOTIF_ID, notification())
        val builder = Builder()
            .setSession("Shahkar")
            .setMtu(1500)
            .addAddress("172.19.0.1", 30)
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)
        tun = builder.establish()
        val fd = tun?.fd ?: return START_NOT_STICKY
        val cfg = File(cacheDir, "sing-box.json")
        cfg.writeText(json)
        startLibbox(cfg.absolutePath, fd)
        return START_STICKY
    }

    override fun onDestroy() {
        stopLibbox()
        tun?.close()
        tun = null
        super.onDestroy()
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
        return b.setContentTitle("Shahkar")
            .setContentText("VPN")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .build()
    }

    private fun startLibbox(configPath: String, tunFd: Int) {
        val cls = libboxClass() ?: throw IllegalStateException(
            "libbox AAR missing; run tool/build_libbox.sh on a machine with Go/NDK",
        )
        val start = cls.methods.firstOrNull { it.name == "start" || it.name == "Start" }
            ?: throw IllegalStateException("libbox has no start method")
        start.invoke(null, configPath, tunFd)
    }

    private fun stopLibbox() {
        val cls = libboxClass() ?: return
        cls.methods.firstOrNull { it.name.equals("stop", ignoreCase = true) }?.invoke(null)
    }

    private fun libboxClass(): Class<*>? {
        val names = arrayOf(
            "io.nekohasekai.libbox.BoxService",
            "libbox.BoxService",
            "io.github.sagernet.libbox.BoxService",
        )
        for (n in names) {
            try {
                return Class.forName(n)
            } catch (_: ClassNotFoundException) {
            }
        }
        return null
    }

    companion object {
        const val EXTRA_CONFIG = "config"
        private const val CHANNEL = "shahkar.vpn"
        private const val NOTIF_ID = 42
    }
}
