package com.mindful.android.utils

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Maintained NSFW domain blocklist for accessibility URL / content checks.
 *
 * Primary source: Blocklist Project porn list (daily Wi-Fi refresh).
 * Fallback: last cached copy, then embedded [NsfwDomains].
 */
object NsfwDomainRepository {
    private const val TAG = "Mindful.NsfwDomainRepo"
    private const val BLOCKLIST_URL =
        "https://raw.githubusercontent.com/blocklistproject/Lists/master/porn.txt"
    private const val CACHE_FILE = "nsfw_blocklistproject_porn.txt"
    private const val PREFS_NAME = "nsfw_domain_repo_prefs"
    private const val PREF_LAST_UPDATE_MS = "lastUpdateMs"
    private const val REFRESH_INTERVAL_MS = 24L * 60L * 60L * 1000L

    private val blockedDomains = ConcurrentHashMap.newKeySet<String>()
    private val isLoaded = AtomicBoolean(false)
    private val isRefreshing = AtomicBoolean(false)

    fun initialize(context: Context) {
        if (isLoaded.get()) return
        synchronized(this) {
            if (isLoaded.get()) return
            loadFromCache(context)
            if (blockedDomains.isEmpty()) {
                loadEmbeddedFallback()
            }
            isLoaded.set(true)
            Log.d(TAG, "initialize: ${blockedDomains.size} domains in memory")
        }
    }

    fun domainCount(): Int = blockedDomains.size

    fun isBlocked(hostname: String): Boolean {
        val host = Utils.normalizeHost(hostname)
        if (host.isEmpty()) return false
        return Utils.isHostBlockedBySet(host, blockedDomains)
    }

    fun mergeUserDomains(domains: Set<String>) {
        domains.map { Utils.normalizeHost(it) }
            .filter { it.isNotEmpty() }
            .forEach { blockedDomains.add(it) }
    }

    fun refreshIfNeeded(context: Context, force: Boolean = false) {
        if (!isRefreshing.compareAndSet(false, true)) return
        Thread {
            try {
                val prefs = context.applicationContext
                    .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val lastUpdate = prefs.getLong(PREF_LAST_UPDATE_MS, 0L)
                val stale = System.currentTimeMillis() - lastUpdate > REFRESH_INTERVAL_MS
                if (!force && !stale) return@Thread
                if (!force && !isOnWifi(context)) {
                    Log.d(TAG, "refreshIfNeeded: skipping — not on Wi-Fi")
                    return@Thread
                }
                fetchAndMerge(context)
            } catch (e: Exception) {
                Log.e(TAG, "refreshIfNeeded failed", e)
            } finally {
                isRefreshing.set(false)
            }
        }.start()
    }

    private fun isOnWifi(context: Context): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    private fun fetchAndMerge(context: Context) {
        Log.d(TAG, "fetchAndMerge: downloading Blocklist Project porn list")
        val connection = (URL(BLOCKLIST_URL).openConnection() as HttpURLConnection).apply {
            connectTimeout = 20_000
            readTimeout = 120_000
            instanceFollowRedirects = true
        }

        connection.inputStream.use { input ->
            val domains = HashSet<String>()
            BufferedReader(InputStreamReader(input)).useLines { lines ->
                lines.forEach { line ->
                    parseLine(line)?.let { domains.add(it) }
                }
            }
            if (domains.isEmpty()) {
                Log.w(TAG, "fetchAndMerge: empty response, keeping cached list")
                return
            }

            blockedDomains.clear()
            blockedDomains.addAll(domains)
            saveToCache(context, domains)
            context.applicationContext
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putLong(PREF_LAST_UPDATE_MS, System.currentTimeMillis())
                .apply()
            isLoaded.set(true)
            Log.d(TAG, "fetchAndMerge: updated to ${domains.size} domains")
        }
    }

    /** Parses Blocklist Project hosts-style lines (domain only or 0.0.0.0 domain). */
    internal fun parseLine(line: String): String? {
        var raw = line.trim()
        if (raw.isEmpty() || raw.startsWith("#")) return null

        if (raw.startsWith("0.0.0.0 ")) raw = raw.removePrefix("0.0.0.0 ").trim()
        if (raw.startsWith("127.0.0.1 ")) raw = raw.removePrefix("127.0.0.1 ").trim()

        val host = raw.split("\\s+".toRegex()).firstOrNull() ?: return null
        val normalized = Utils.normalizeHost(host)
        if (normalized.isEmpty() || !normalized.contains('.')) return null
        return normalized
    }

    private fun loadFromCache(context: Context) {
        val file = cacheFile(context)
        if (!file.exists()) return
        file.readLines().forEach { line ->
            parseLine(line)?.let { blockedDomains.add(it) }
        }
    }

    private fun saveToCache(context: Context, domains: Set<String>) {
        cacheFile(context).writeText(domains.sorted().joinToString("\n"))
    }

    private fun cacheFile(context: Context): File =
        File(context.filesDir, CACHE_FILE)

    private fun loadEmbeddedFallback() {
        blockedDomains.addAll(NsfwDomains.init().keys)
        Log.d(TAG, "loadEmbeddedFallback: ${blockedDomains.size} embedded domains")
    }
}
