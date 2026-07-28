package com.mindful.android.utils

import androidx.core.net.toUri

/**
 * Forces strict SafeSearch on major search engines while NSFW blocking is enabled.
 * Users cannot disable it from the browser while the blocker is on — any attempt
 * to turn SafeSearch off or open its settings page is redirected back to strict mode.
 */
object SafeSearchHelper {

    private val googleHosts = setOf(
        "google.com",
        "google.lk",
        "google.co.uk",
        "google.ca",
        "google.com.au",
        "google.de",
        "google.fr",
        "google.co.in",
    )

    private val bingHosts = setOf(
        "bing.com",
        "www.bing.com",
    )

    private val duckDuckGoHosts = setOf(
        "duckduckgo.com",
        "html.duckduckgo.com",
    )

    private val yahooHosts = setOf(
        "search.yahoo.com",
        "yahoo.com",
    )

    /** Pages where users can turn SafeSearch off — block while NSFW filter is on. */
    private val safeSearchSettingsPatterns = listOf(
        "/preferences",
        "/safesearch",
        "safe=off",
        "safe=images", // "blur" mode — treat as not strict enough
        "adlt=off",
        "adlt=moderate",
        "kp=-1",
        "kp=-2",
        "vm=i", // Yahoo moderate
    )

    fun isSearchEngineHost(host: String): Boolean {
        val h = Utils.normalizeHost(host)
        return googleHosts.any { h == it || h.endsWith(".$it") }
                || bingHosts.any { h == it || h.endsWith(".$it") }
                || duckDuckGoHosts.any { h == it || h.endsWith(".$it") }
                || yahooHosts.any { h == it || h.endsWith(".$it") }
    }

    fun isSafeSearchSettingsPage(url: String): Boolean {
        val lower = url.lowercase()
        return safeSearchSettingsPatterns.any { lower.contains(it) }
    }

    /**
     * Returns true when the URL is a search-engine page that is not using strict SafeSearch.
     */
    fun needsStrictSafeSearch(url: String, host: String): Boolean {
        val h = Utils.normalizeHost(host)
        val lower = url.lowercase()

        if (isSafeSearchSettingsPage(lower)) return true

        when {
            googleHosts.any { h == it || h.endsWith(".$it") } -> {
                if (!lower.contains("/search") && !lower.contains("?q=") && !lower.contains("&q=")) {
                    return false
                }
                val safe = runCatching {
                    lower.toUri().getQueryParameter("safe")
                }.getOrNull()
                // Missing safe= also defaults to user preference — force strict
                return safe.isNullOrBlank() || safe == "off" || safe == "images"
            }

            bingHosts.any { h == it || h.endsWith(".$it") } -> {
                if (!lower.contains("/search") && !lower.contains("?q=")) return false
                val adlt = runCatching {
                    lower.toUri().getQueryParameter("adlt")
                }.getOrNull()
                return adlt.isNullOrBlank() || adlt != "strict"
            }

            duckDuckGoHosts.any { h == it || h.endsWith(".$it") } -> {
                val kp = runCatching {
                    lower.toUri().getQueryParameter("kp")
                }.getOrNull()
                return kp.isNullOrBlank() || kp != "1"
            }

            yahooHosts.any { h == it || h.endsWith(".$it") } -> {
                if (!lower.contains("/search") && !lower.contains("?p=")) return false
                val vm = runCatching {
                    lower.toUri().getQueryParameter("vm")
                }.getOrNull()
                return vm.isNullOrBlank() || vm != "r"
            }
        }
        return false
    }

    /**
     * Rewrites [url] to use strict SafeSearch parameters for the detected engine.
     */
    fun buildStrictSafeSearchUrl(url: String, host: String): String? {
        val h = Utils.normalizeHost(host)
        val uri = runCatching { url.toUri() }.getOrNull() ?: return null
        val builder = uri.buildUpon()

        when {
            googleHosts.any { h == it || h.endsWith(".$it") } -> {
                if (isSafeSearchSettingsPage(url)) {
                    return "https://www.google.com/"
                }
                val existing = uri.queryParameterNames
                val params = existing.associateWith { uri.getQueryParameter(it) ?: "" }.toMutableMap()
                params["safe"] = "active"
                builder.clearQuery()
                params.forEach { (k, v) -> if (v.isNotEmpty()) builder.appendQueryParameter(k, v) }
                return builder.build().toString()
            }

            bingHosts.any { h == it || h.endsWith(".$it") } -> {
                val params = uri.queryParameterNames.associateWith {
                    uri.getQueryParameter(it) ?: ""
                }.toMutableMap()
                params["adlt"] = "strict"
                builder.clearQuery()
                params.forEach { (k, v) -> if (v.isNotEmpty()) builder.appendQueryParameter(k, v) }
                return builder.build().toString()
            }

            duckDuckGoHosts.any { h == it || h.endsWith(".$it") } -> {
                val params = uri.queryParameterNames.associateWith {
                    uri.getQueryParameter(it) ?: ""
                }.toMutableMap()
                params["kp"] = "1"
                builder.clearQuery()
                params.forEach { (k, v) -> if (v.isNotEmpty()) builder.appendQueryParameter(k, v) }
                return builder.build().toString()
            }

            yahooHosts.any { h == it || h.endsWith(".$it") } -> {
                val params = uri.queryParameterNames.associateWith {
                    uri.getQueryParameter(it) ?: ""
                }.toMutableMap()
                params["vm"] = "r"
                builder.clearQuery()
                params.forEach { (k, v) -> if (v.isNotEmpty()) builder.appendQueryParameter(k, v) }
                return builder.build().toString()
            }
        }
        return null
    }
}
