package com.shahkar.connect.vpn

import android.net.VpnService
import java.lang.reflect.Proxy

/**
 * Starts sagernet libbox via reflection so the app compiles before
 * `tool/build_libbox.sh` produces `libbox.aar`.
 */
object LibboxBridge {
    @Volatile
    private var service: Any? = null

    fun start(vpn: VpnService, configJson: String, tunFd: Int) {
        stop()
        val lib = firstClass(
            "io.nekohasekai.libbox.Libbox",
            "libbox.Libbox",
            "io.github.sagernet.libbox.Libbox",
        )
        val boxClass = firstClass(
            "io.nekohasekai.libbox.BoxService",
            "libbox.BoxService",
            "io.github.sagernet.libbox.BoxService",
        )
        val iface = firstClass(
            "io.nekohasekai.libbox.PlatformInterface",
            "libbox.PlatformInterface",
            "io.github.sagernet.libbox.PlatformInterface",
        )
        if (lib != null && iface != null) {
            val platform = proxyPlatform(iface, vpn, tunFd)
            val created = invokeNamed(lib, null, listOf("newService", "NewService"), configJson, platform)
                ?: invokeNamed(lib, null, listOf("newService", "NewService"), configJson, "", platform)
            if (created != null) {
                invokeNamed(created.javaClass, created, listOf("start", "Start"))
                service = created
                return
            }
        }
        if (boxClass != null) {
            val started = invokeNamed(boxClass, null, listOf("start", "Start"), configJson, tunFd)
            if (started != null) {
                service = started
                return
            }
        }
        throw IllegalStateException(
            "libbox AAR missing; run tool/build_libbox.sh on a machine with Go/NDK",
        )
    }

    fun stop() {
        val current = service ?: return
        service = null
        try {
            invokeNamed(current.javaClass, current, listOf("close", "Close", "stop", "Stop"))
        } catch (_: Exception) {
        }
    }

    private fun proxyPlatform(iface: Class<*>, vpn: VpnService, tunFd: Int): Any {
        return Proxy.newProxyInstance(iface.classLoader, arrayOf(iface)) { _, method, args ->
            when (method.name.lowercase()) {
                "opentun" -> tunFd
                "autodetectinterfacecontrol" -> {
                    val fd = (args?.firstOrNull() as? Number)?.toInt()
                    if (fd != null) vpn.protect(fd)
                    null
                }
                "useplatformautodetectinterfacecontrol" -> true
                "underNetworkextension", "undernetworkextension" -> false
                "includeallnetworks" -> false
                "useprocfs" -> false
                "clearDNSCache", "cleardnscache" -> null
                "writelog" -> null
                else -> defaultValue(method.returnType)
            }
        }
    }

    private fun defaultValue(type: Class<*>): Any? = when (type) {
        java.lang.Boolean.TYPE, java.lang.Boolean::class.java -> false
        java.lang.Integer.TYPE, java.lang.Integer::class.java -> 0
        java.lang.Long.TYPE, java.lang.Long::class.java -> 0L
        java.lang.Float.TYPE, java.lang.Float::class.java -> 0f
        java.lang.Double.TYPE, java.lang.Double::class.java -> 0.0
        java.lang.Void.TYPE, Void::class.java -> null
        String::class.java -> ""
        else -> null
    }

    private fun firstClass(vararg names: String): Class<*>? {
        for (name in names) {
            try {
                return Class.forName(name)
            } catch (_: ClassNotFoundException) {
            }
        }
        return null
    }

    private fun invokeNamed(cls: Class<*>, target: Any?, names: List<String>, vararg args: Any?): Any? {
        val methods = cls.methods
        for (name in names) {
            val matches = methods.filter { it.name.equals(name, ignoreCase = true) }
            for (method in matches) {
                if (method.parameterTypes.size != args.size) continue
                try {
                    return method.invoke(target, *args)
                } catch (_: Exception) {
                }
            }
        }
        return null
    }
}
