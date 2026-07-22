/*
 *
 *  *
 *  *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *  *
 *  *  * This source code is licensed under the GPL-2.0 license license found in the
 *  *  * LICENSE file in the root directory of this source tree.
 *  *
 *
 */
package com.mindful.android.utils

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import org.jetbrains.annotations.Contract
import java.net.URI
import java.util.Locale
import kotlin.math.abs

/**
 * A utility class containing static helper methods for various common tasks such as
 * checking if a service is running, encoding images, parsing JSON strings, and manipulating URLs.
 */
object Utils {
    private const val TAG = "Mindful.Utils"

    /**
     * Checks if a service with the given class name is currently running.
     *
     * @param context          The application context.
     * @param serviceClass The class of the service  (e.g., MindfulAppsTrackerService.class)).
     * @return True if the service is running, false otherwise.
     */
    fun isServiceRunning(context: Context, serviceClass: Class<*>): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (serviceInfo in activityManager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceInfo.service.className == serviceClass.name) {
                return true
            }
        }

        return false
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    fun safelyRegisterReceiver(
        context: Context,
        receiver: BroadcastReceiver,
        intentFilter: IntentFilter,
        exported: Boolean = false,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val flag = if (exported) Context.RECEIVER_EXPORTED
            else Context.RECEIVER_NOT_EXPORTED
            context.registerReceiver(receiver, intentFilter, flag)
        } else {
            context.registerReceiver(receiver, intentFilter)
        }
    }

    fun vibrateDevice(context: Context, durationMs: Long) {
        val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager =
                context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        vibrator.cancel()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    durationMs,
                    VibrationEffect.DEFAULT_AMPLITUDE
                )
            )
        } else {
            vibrator.vibrate(durationMs)
        }
    }

    /**
     * Formats the total data usage into a human-readable string.
     * Example: 12.35 GB
     *
     * @param totalMBs The total data usage in megabytes (MB).
     * @return A string representing the formatted data usage.
     */
    @Contract(pure = true)
    fun formatDataMBs(totalMBs: Int): String {
        val totalMBsAbs = abs(totalMBs)

        if (totalMBsAbs >= 1024) {
            val gbs = totalMBsAbs / 1024f
            val formattedGBs = String.format(Locale.getDefault(), "%.2f", gbs)
            return "${formattedGBs}gb"
        } else {
            return "${totalMBsAbs}mb"
        }
    }


    /**
     * Ensures the given URL uses the HTTPS protocol.
     *
     *
     * If the URL starts with "https://", it is returned unchanged. If it starts with
     * "http://", the protocol is changed to "https://". If no protocol is present,
     * "https://" is added.
     *
     * @param url The URL to validate (must not be null).
     * @return A URL that starts with "https://".
     */
    fun validateHttpsProtocol(url: String): String {
        return if (url.startsWith("https://")) url else if (url.startsWith("http://")) url.replace(
            "http://",
            "https://"
        ) else ("https://$url")
    }

    /**
     * Parses the host name from a URL string.
     *
     * @param url The URL string to parse.
     * @return The host name extracted from the URL.
     */
    fun parseHostNameFromUrl(url: String): String? {
        // First try using URI class for proper URL parsing
        runCatching { URI(url).host }
            .onSuccess { host ->
                host?.let { return normalizeHost(it) }
            }
            .onFailure { e ->
                Log.w(
                    TAG,
                    "parseHostNameFromUrl: Cannot parse url using URI method, trying fallback",
                    e
                )
            }

        // Fallback manual parsing
        return buildString {
            // Remove common prefixes
            append(url.removePrefix("https://").removePrefix("http://").removePrefix("www."))

            // Handle mobile prefixes
            when {
                startsWith("mobile.") -> delete(0, 7)
                startsWith("m.") -> delete(0, 2)
            }

            // Trim everything after first slash
            val slashIndex = indexOf('/')
            if (slashIndex > 0) setLength(slashIndex)
        }.takeIf { it.isNotEmpty() }?.let { normalizeHost(it) }
    }

    /**
     * Lowercases and strips common mobile/www prefixes from a host.
     */
    fun normalizeHost(host: String): String {
        var h = host.lowercase().trim().trimEnd('.')
        when {
            h.startsWith("www.") -> h = h.substring(4)
            h.startsWith("mobile.") -> h = h.substring(7)
            h.startsWith("m.") -> h = h.substring(2)
        }
        return h
    }

    /**
     * Label-safe domain match: [host] equals [blocked] or is a subdomain of [blocked].
     * e.g. m.pornhub.com matches pornhub.com; notpornhub.com does not.
     */
    fun hostMatchesBlockedDomain(host: String, blockedDomain: String): Boolean {
        val h = normalizeHost(host)
        val b = normalizeHost(blockedDomain)
        if (h.isEmpty() || b.isEmpty()) return false
        return h == b || h.endsWith(".$b")
    }

    /**
     * True if [host] or any of its parent domains appears in [blockedHosts].
     * Walks labels upward (a.b.example.com → b.example.com → example.com) so lookup
     * stays O(labels) instead of scanning the full blocklist.
     */
    fun isHostBlockedBySet(host: String, blockedHosts: Set<String>): Boolean {
        var candidate = normalizeHost(host)
        if (candidate.isEmpty()) return false
        while (true) {
            if (blockedHosts.contains(candidate)) return true
            val dot = candidate.indexOf('.')
            if (dot < 0) break
            candidate = candidate.substring(dot + 1)
            // Stop before matching a bare TLD like "com"
            if (!candidate.contains('.')) break
        }
        return false
    }

    /**
     * Same as [isHostBlockedBySet] for a Map used as a domain set (values ignored).
     */
    fun isHostBlockedByMap(host: String, blockedHosts: Map<String, Boolean>): Boolean {
        var candidate = normalizeHost(host)
        if (candidate.isEmpty()) return false
        while (true) {
            if (blockedHosts[candidate] == true) return true
            val dot = candidate.indexOf('.')
            if (dot < 0) break
            candidate = candidate.substring(dot + 1)
            if (!candidate.contains('.')) break
        }
        return false
    }
}
