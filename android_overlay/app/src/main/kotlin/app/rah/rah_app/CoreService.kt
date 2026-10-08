package app.rah.rah_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import hev.htproxy.TProxyService
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/** In-process bridge between the service and the Flutter EventChannel. */
object CoreBus {
    @Volatile
    var state: String = "idle"

    /** Touched on the main thread only. */
    var sink: EventChannel.EventSink? = null

    private val main = Handler(Looper.getMainLooper())

    fun state(s: String, message: String? = null) {
        state = s
        main.post {
            sink?.success(mapOf("type" to "state", "state" to s, "message" to message))
        }
    }

    fun log(line: String) {
        main.post { sink?.success(mapOf("type" to "log", "line" to line)) }
    }
}

private data class CoreConfig(
    val protocol: String,
    val scan: String,
    val noize: String,
    val ip: String,
    val http2: Boolean,
    val vpn: Boolean,
    val shape: String,
    val region: String,
) {
    companion object {
        private val PROTOCOLS = setOf("masque", "wg", "gool", "psiphon")
        private val SHAPES = setOf("auto", "cdn", "direct")
        private val REGION = Regex("^[A-Z]{2}$")
        private val SCANS = setOf("turbo", "balanced", "thorough", "stealth", "ironclad")
        private val NOIZE = setOf("firewall", "gfw", "balanced", "aggressive", "light", "off")
        private val IPS = setOf("4", "6", "dual")

        // Values end up in the environment of the child process, so they are whitelisted.
        fun from(i: Intent): CoreConfig {
            fun pick(key: String, allowed: Set<String>, default: String): String =
                i.getStringExtra(key)?.takeIf { it in allowed } ?: default
            return CoreConfig(
                protocol = pick("protocol", PROTOCOLS, "masque"),
                scan = pick("scan", SCANS, "balanced"),
                noize = pick("noize", NOIZE, "firewall"),
                ip = pick("ip", IPS, "4"),
                http2 = i.getBooleanExtra("http2", false),
                vpn = i.getBooleanExtra("vpn", true),
                shape = pick("shape", SHAPES, "auto"),
                region = i.getStringExtra("region")?.uppercase()?.takeIf { REGION.matches(it) } ?: "",
            )
        }
    }
}

/**
 * Runs the Aether core as a child process (shipped as libaether.so so it is executable from
 * nativeLibraryDir), waits for its local SOCKS5 port, and optionally routes the whole device
 * through it with VpnService + hev-socks5-tunnel.
 */
class CoreService : VpnService() {

    companion object {
        const val ACTION_START = "app.rah.action.START"
        const val ACTION_STOP = "app.rah.action.STOP"

        private const val SOCKS_HOST = "127.0.0.1"
        private const val SOCKS_PORT = 1819
        private const val PSIPHON_HTTP_PORT = 1820
        private const val MAP_DNS = "198.18.0.2"
        private const val READY_TIMEOUT_MS = 600_000L
        private const val CHANNEL_ID = "rah_core"
        private const val NOTIF_ID = 1
        private const val TUN_ADDR = "198.18.0.1"
        private const val TUN_ADDR6 = "fc00::1"
        private const val TUN_MTU = 1500
    }

    private val lock = Any()
    private var process: Process? = null
    private var tun: ParcelFileDescriptor? = null
    private var worker: Thread? = null

    /** Bumped on every teardown so stale worker threads can tell they were replaced. */
    @Volatile
    private var generation = 0

    /** Set when the core says psiphon has a tunnel; its SOCKS port opens earlier than that. */
    @Volatile
    private var psiphonReady = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> start(intent)
            ACTION_STOP -> stopAll()
            else -> if (worker == null) stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onRevoke() {
        // The user turned the VPN off from system settings.
        stopAll()
    }

    override fun onDestroy() {
        generation++
        stopTun()
        process?.destroy()
        super.onDestroy()
    }

    // ---------------------------------------------------------------- start / stop

    private fun start(intent: Intent) {
        synchronized(lock) {
            if (worker != null) return
            val cfg = CoreConfig.from(intent)
            startInForeground("Connecting…")
            CoreBus.state("starting")
            val gen = ++generation
            worker = thread(name = "core-supervisor") { supervise(cfg, gen) }
        }
    }

    private fun stopAll() {
        CoreBus.state("stopping")
        thread(name = "core-stop") {
            teardown()
            CoreBus.state("idle")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun teardown() {
        synchronized(lock) {
            generation++
            stopTun()
            process?.let { p ->
                p.destroy()
                // Give Aether time to stop its embedded Psiphon child before killing the parent.
                if (!p.waitFor(10, TimeUnit.SECONDS)) p.destroyForcibly()
            }
            process = null
            worker = null
        }
    }

    // ---------------------------------------------------------------- supervisor

    private fun supervise(cfg: CoreConfig, gen: Int) {
        try {
            val bin = File(applicationInfo.nativeLibraryDir, "libaether.so")
            check(bin.exists()) {
                "libaether.so not found in ${bin.parent} (run tools/android/fetch_deps.sh and keep extractNativeLibs=true)"
            }

            val psiphon = cfg.protocol == "psiphon"
            val psiBin = File(applicationInfo.nativeLibraryDir, "libpsiphon.so")
            if (psiphon) {
                check(psiBin.exists()) {
                    "libpsiphon.so not found in ${psiBin.parent} (run tools/android/fetch_deps.sh)"
                }
            }
            psiphonReady = false

            val pb = ProcessBuilder(bin.absolutePath)
                .directory(filesDir)
                .redirectErrorStream(true)
            pb.environment().apply {
                put("HOME", filesDir.absolutePath)
                put("AETHER_CONFIG", File(filesDir, "aether.toml").absolutePath)
                put("AETHER_MASQUE_CONFIG", File(filesDir, "aether-masque.toml").absolutePath)
                put("AETHER_SOCKS", "$SOCKS_HOST:$SOCKS_PORT")
                if (psiphon) {
                    // No WARP tunnel: the SOCKS5 port is psiphon itself. The binary ships as a .so so it can be executed.
                    put("AETHER_PSIPHON", "only")
                    put("AETHER_PSIPHON_BIN", psiBin.absolutePath)
                    put("AETHER_PSIPHON_DIR", File(filesDir, "psiphon").absolutePath)
                    put("AETHER_PSIPHON_HTTP", "$SOCKS_HOST:$PSIPHON_HTTP_PORT")
                    put("AETHER_PSIPHON_MODE", cfg.shape)
                    put("AETHER_PSIPHON_CONFIG", writePsiphonOverride().absolutePath) // psiphon-dns-fix
                    if (cfg.region.isNotEmpty()) put("AETHER_PSIPHON_REGION", cfg.region)
                } else {
                    put("AETHER_PROTOCOL", cfg.protocol)
                    // Aether 2.3 gool carries WireGuard inside MASQUE. Reject Iranian exits.
                    if (cfg.protocol == "gool") put("AETHER_EXIT_LOC", "!IR")
                    put("AETHER_SCAN", cfg.scan)
                    put("AETHER_NOIZE", cfg.noize)
                    put("AETHER_IP", cfg.ip)
                    put("AETHER_QUICK_RECONNECT", "1")
                    if (cfg.protocol in setOf("masque", "gool") && cfg.http2) {
                        put("AETHER_MASQUE_HTTP2", "1")
                    }
                }
            }

            val p = pb.start()
            synchronized(lock) {
                if (gen != generation) {
                    p.destroy()
                    return
                }
                process = p
            }

            thread(name = "core-log", isDaemon = true) {
                runCatching {
                    p.inputStream.bufferedReader().useLines { lines ->
                        lines.forEach {
                            if (psiphon && it.contains("psiphon is ready")) psiphonReady = true
                            CoreBus.log(it)
                        }
                    }
                }
            }

            // WireGuard/MASQUE: Aether opens the SOCKS5 port only after real data has crossed the tunnel.
            // Psiphon: the client binds its port at launch, so wait for the core's "psiphon is ready" line.
            val deadline = System.currentTimeMillis() + READY_TIMEOUT_MS
            var ready = false
            while (gen == generation && System.currentTimeMillis() < deadline) {
                check(p.isAlive) { "core exited with code ${p.exitValue()}" }
                if ((!psiphon || psiphonReady) && socksOpen()) {
                    ready = true
                    break
                }
                Thread.sleep(500)
            }
            if (gen != generation) return
            check(ready) { "timed out waiting for the SOCKS5 port" }

            if (cfg.vpn) startTun(psiphon)
            if (gen != generation) return

            updateNotification(if (cfg.vpn) "VPN active" else "SOCKS5 on $SOCKS_HOST:$SOCKS_PORT")
            CoreBus.state("connected")

            p.waitFor()
            if (gen == generation) error("core exited with code ${p.exitValue()}")
        } catch (e: Exception) {
            if (gen != generation) return
            CoreBus.log("error: ${e.message}")
            teardown()
            CoreBus.state("error", e.message)
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    /**
     * Prefer public resolvers so poisoned carrier DNS answers do not send Psiphon to bogon IPs.
     * // psiphon-dns-fix
     */
    private fun writePsiphonOverride(): File {
        val f = File(filesDir, "psiphon-override.json")
        f.writeText(
            "{\"DNSResolverAlternateServers\":[\"1.1.1.1\",\"8.8.8.8\",\"9.9.9.9\"]," +
                "\"DNSResolverPreferredAlternateServers\":[\"1.1.1.1\",\"8.8.8.8\",\"9.9.9.9\"]," +
                "\"DNSResolverPreferAlternateServerProbability\":1.0}\n"
        )
        return f
    }

    private fun socksOpen(): Boolean = try {
        Socket().use { it.connect(InetSocketAddress(SOCKS_HOST, SOCKS_PORT), 300) }
        true
    } catch (_: Exception) {
        false
    }

    // ---------------------------------------------------------------- VPN + tun2socks

    private fun startTun(psiphon: Boolean) {
        val iface = Builder()
            .setSession("Rah")
            .setMtu(TUN_MTU)
            .addAddress(TUN_ADDR, 32)
            .addAddress(TUN_ADDR6, 128)
            // Route IPv6 into the tun too: otherwise v6 traffic bypasses the VPN and leaks the real address.
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)
            // Psiphon's SOCKS5 has no UDP, so DNS is answered by hev (mapdns) and resolved remotely by name.
            .addDnsServer(if (psiphon) MAP_DNS else "1.1.1.1")
            // The core runs in our own UID: excluding the app keeps its tunnel traffic off the VPN.
            .addDisallowedApplication(packageName)
            .establish() ?: error("VpnService.establish() returned null (VPN permission missing?)")
        tun = iface

        val conf = File(filesDir, "hev-socks5-tunnel.yml")
        val mapDns = if (psiphon) {
            """
            mapdns:
              address: $MAP_DNS
              port: 53
              network: 100.64.0.0
              netmask: 255.192.0.0
              cache-size: 10000
            """.trimIndent() + "\n"
        } else {
            ""
        }
        conf.writeText(
            """
            tunnel:
              mtu: $TUN_MTU
              ipv4: $TUN_ADDR
              ipv6: '$TUN_ADDR6'
            socks5:
              port: $SOCKS_PORT
              address: $SOCKS_HOST
              udp: 'udp'
            """.trimIndent() + "\n" + mapDns + "misc:\n  log-level: warn\n"
        )
        // The call returns false when the tunnel could not start; do not report "connected" then.
        check(TProxyService.TProxyStartService(conf.absolutePath, iface.fd)) {
            "hev-socks5-tunnel failed to start (config: ${conf.absolutePath})"
        }
    }

    private fun stopTun() {
        runCatching { TProxyService.TProxyStopService() }
        runCatching { tun?.close() }
        tun = null
    }

    // ---------------------------------------------------------------- notification

    private fun buildNotification(text: String): Notification {
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE
        )
        val stop = PendingIntent.getService(
            this, 1,
            Intent(this, CoreService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Rah")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
                    "Disconnect",
                    stop
                ).build()
            )
            .build()
    }

    private fun startInForeground(text: String) {
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Connection", NotificationManager.IMPORTANCE_LOW)
        )
        val n = buildNotification(text)
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun updateNotification(text: String) {
        getSystemService(NotificationManager::class.java).notify(NOTIF_ID, buildNotification(text))
    }
}
