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
package com.mindful.android.services.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.provider.Browser
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.core.net.toUri
import com.mindful.android.models.Wellbeing
import com.mindful.android.utils.NsfwDomainRepository
import com.mindful.android.utils.NsfwKeywords
import com.mindful.android.utils.SafeSearchHelper
import com.mindful.android.utils.ThreadUtils
import com.mindful.android.utils.Utils

/**
 * NSFW blocking via Accessibility — URL bar, search queries, SERP text,
 * image alt/contentDescription, and domain list.
 *
 * Performance: URL checks every call; full tree scans are rate-limited.
 */
class BrowserManager(
    private val context: Context,
    private val shortsPlatformManager: ShortsPlatformManager,
    private val exitBlockedContent: (action: Int, immediate: Boolean) -> Unit,
) {
    private var stickyBrowserPackage: String = ""
    private var stickyBlockedHost: String = ""
    private var stickyBlockedQuery: String = ""
    private var stickyActivatedAtMs: Long = 0L

    private var mLastCleanRedirectUrl = ""
    private var mLastSafeSearchRedirectUrl = ""
    private var lastSafeSearchRedirectAtMs = 0L
    private var lastHardExitAtMs = 0L
    private var lastFullScanAtMs = 0L
    private var lastUrlChecked: String = ""
    private var lastUrlCheckedAtMs = 0L

    fun blockDistraction(
        packageName: String,
        node: AccessibilityNodeInfo,
        wellbeing: Wellbeing,
    ) {
        val nsfwOn = wellbeing.blockNsfwSites
        if (!nsfwOn
            && wellbeing.blockedWebsites.isEmpty()
            && wellbeing.nsfwWebsites.isEmpty()
        ) {
            // Still allow shorts below
        }

        val raw = extractBrowserUrl(node, packageName)
        val now = System.currentTimeMillis()

        // Sticky: blocked porn host while URL bar empty (fullscreen video)
        if (raw.isBlank()) {
            if (nsfwOn && isStickyActive() && stickyBlockedHost.isNotEmpty()) {
                hardExitNsfw(packageName)
                return
            }
            if (nsfwOn && isStickyActive() && stickyBlockedQuery.isNotEmpty()) {
                hardExitNsfw(packageName, openCleanHome = true)
                return
            }
            // Still scan page if NSFW on (URL bar hidden / WebView)
            if (nsfwOn && shouldRunFullScan(now) && scanVisibleContentForNsfw(node)) {
                hardExitNsfw(packageName, openCleanHome = true)
            }
            return
        }

        // Skip duplicate URL checks within a short window (perf)
        if (raw == lastUrlChecked && now - lastUrlCheckedAtMs < 80L) {
            if (nsfwOn && shouldRunFullScan(now) && isSearchResultsContext(raw)
                && scanVisibleContentForNsfw(node)
            ) {
                hardExitNsfw(packageName, openCleanHome = true)
            }
            return
        }
        lastUrlChecked = raw
        lastUrlCheckedAtMs = now

        // Pre-submit: porn query in omnibox
        if (nsfwOn && looksLikeSearchQuery(raw) && NsfwKeywords.isPornSearchQuery(raw)) {
            Log.d(TAG, "Pre-submit block: $raw")
            activateSticky(packageName, host = "", query = NsfwKeywords.normalizeForMatch(raw))
            hardExitNsfw(packageName, openCleanHome = true)
            return
        }

        val url = raw.replace("google.com/amp/s/amp.", "")
        if (url.contains(" ") || !url.contains(".")) {
            // Typing mid-query — also scan SERP if already on a results page underneath
            if (nsfwOn && shouldRunFullScan(now) && scanVisibleContentForNsfw(node)) {
                activateSticky(packageName, host = "", query = "scan")
                hardExitNsfw(packageName, openCleanHome = true)
            }
            return
        }

        val host = Utils.parseHostNameFromUrl(url) ?: return

        // Sticky re-hit
        if (nsfwOn && isStickyActive()) {
            if (stickyBlockedHost.isNotEmpty()
                && Utils.hostMatchesBlockedDomain(host, stickyBlockedHost)
            ) {
                hardExitNsfw(packageName)
                return
            }
            val queryNow = extractSearchQuery(url)
            if (stickyBlockedQuery.isNotEmpty()
                && !queryNow.isNullOrBlank()
                && NsfwKeywords.isPornSearchQuery(queryNow)
            ) {
                hardExitNsfw(packageName, openCleanHome = true)
                return
            }
        }

        if (nsfwOn && SafeSearchHelper.isSafeSearchSettingsPage(url)) {
            hardExitNsfw(packageName, openCleanHome = true)
            return
        }

        // Search URL q= porn query
        if (nsfwOn) {
            val query = extractSearchQuery(url)
            if (!query.isNullOrBlank() && NsfwKeywords.isPornSearchQuery(query)) {
                Log.d(TAG, "Search URL block: $query")
                activateSticky(packageName, host = host, query = NsfwKeywords.normalizeForMatch(query))
                hardExitNsfw(packageName, openCleanHome = true)
                return
            }
        }

        // Domain blocklist
        val hostBlocked = Utils.isHostBlockedBySet(host, wellbeing.blockedWebsites)
                || Utils.isHostBlockedBySet(host, wellbeing.nsfwWebsites)
                || (nsfwOn && NsfwDomainRepository.isBlocked(host))

        if (hostBlocked) {
            Log.d(TAG, "Domain block: $host")
            if (nsfwOn) {
                activateSticky(packageName, host = host, query = "")
                hardExitNsfw(packageName)
            } else {
                exitBlockedContent(AccessibilityService.GLOBAL_ACTION_BACK, false)
            }
            return
        }

        if (shortsPlatformManager.checkAndBlockShortsOnBrowser(wellbeing, url)) return

        // Screen scan on EVERY search results page (no keyword gate) + WebViews
        if (nsfwOn && shouldRunFullScan(now)) {
            val onSearch = isSearchResultsContext(url) || SafeSearchHelper.isSearchEngineHost(host)
            if ((onSearch || looksLikeWebContent(url)) && scanVisibleContentForNsfw(node)) {
                Log.d(TAG, "Screen scan block on $host")
                val q = extractSearchQuery(url)?.let { NsfwKeywords.normalizeForMatch(it) }
                    ?: "scan"
                activateSticky(packageName, host = "", query = q)
                hardExitNsfw(packageName, openCleanHome = true)
                return
            }
        }

        // SafeSearch soft layer
        if (nsfwOn && SafeSearchHelper.isSearchEngineHost(host)) {
            if (SafeSearchHelper.needsStrictSafeSearch(url, host)) {
                SafeSearchHelper.buildStrictSafeSearchUrl(url, host)?.let { strictUrl ->
                    if (strictUrl != url) redirectBrowserToUrl(packageName, strictUrl)
                }
            }
        }
    }

    /**
     * SystemUI / QS / notification shade should NOT clear sticky NSFW state.
     */
    fun onForegroundPackageChanged(packageName: String) {
        if (isTransientSystemUi(packageName)) return
        if (stickyBrowserPackage.isNotEmpty() && packageName != stickyBrowserPackage) {
            clearSticky()
        }
    }

    fun isStickyBrowser(packageName: String): Boolean =
        isStickyActive() && stickyBrowserPackage == packageName

    fun hasActiveSticky(): Boolean = isStickyActive()

    fun stickyBrowserPackageOrEmpty(): String = stickyBrowserPackage

    private fun shouldRunFullScan(now: Long): Boolean {
        if (now - lastFullScanAtMs < FULL_SCAN_MIN_INTERVAL_MS) return false
        lastFullScanAtMs = now
        return true
    }

    private fun redirectBrowserToUrl(browserPackage: String, targetUrl: String) {
        val now = System.currentTimeMillis()
        if (targetUrl == mLastSafeSearchRedirectUrl && now - lastSafeSearchRedirectAtMs < 1200L) {
            return
        }
        mLastSafeSearchRedirectUrl = targetUrl
        lastSafeSearchRedirectAtMs = now

        ThreadUtils.runOnMainThread {
            val intent = Intent(Intent.ACTION_VIEW, targetUrl.toUri()).apply {
                putExtra(Browser.EXTRA_APPLICATION_ID, browserPackage)
                setPackage(browserPackage)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            runCatching {
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                }
            }
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                mLastSafeSearchRedirectUrl = ""
            }, 1500L)
        }
    }

    private fun hardExitNsfw(packageName: String, openCleanHome: Boolean = false) {
        val now = System.currentTimeMillis()
        if (now - lastHardExitAtMs < 280L) return
        lastHardExitAtMs = now

        exitBlockedContent(AccessibilityService.GLOBAL_ACTION_HOME, true)
        if (openCleanHome) redirectToCleanHome(packageName)
    }

    private fun redirectToCleanHome(browserPackage: String) {
        val cleanUrl = "https://www.google.com/"
        if (mLastCleanRedirectUrl == cleanUrl) return
        mLastCleanRedirectUrl = cleanUrl

        ThreadUtils.runOnMainThread {
            val intent = Intent(Intent.ACTION_VIEW, cleanUrl.toUri()).apply {
                putExtra(Browser.EXTRA_APPLICATION_ID, browserPackage)
                setPackage(browserPackage)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            runCatching {
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                }
            }
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                mLastCleanRedirectUrl = ""
            }, 1500L)
        }
    }

    private fun activateSticky(packageName: String, host: String, query: String) {
        stickyBrowserPackage = packageName
        if (host.isNotEmpty()) stickyBlockedHost = Utils.normalizeHost(host)
        if (query.isNotEmpty()) stickyBlockedQuery = query.take(120)
        stickyActivatedAtMs = System.currentTimeMillis()
    }

    private fun isStickyActive(): Boolean {
        if (stickyBrowserPackage.isEmpty()) return false
        val age = System.currentTimeMillis() - stickyActivatedAtMs
        if (age > STICKY_MAX_AGE_MS) {
            clearSticky()
            return false
        }
        return stickyBlockedHost.isNotEmpty() || stickyBlockedQuery.isNotEmpty()
    }

    private fun clearSticky() {
        stickyBrowserPackage = ""
        stickyBlockedHost = ""
        stickyBlockedQuery = ""
        stickyActivatedAtMs = 0L
    }

    companion object {
        private const val TAG = "Mindful.BrowserEventsManager"
        private const val STICKY_MAX_AGE_MS = 3 * 60 * 1000L
        private const val FULL_SCAN_MIN_INTERVAL_MS = 220L
        private const val MAX_SCAN_DEPTH = 10
        private const val MAX_SCAN_NODES = 280

        fun initializeNsfwDomains() {}
        fun clearNsfwDomains() {}

        fun isTransientSystemUi(packageName: String): Boolean {
            return packageName == "com.android.systemui"
                    || packageName == "com.samsung.android.app.cocktailbarservice"
                    || packageName == "com.samsung.android.honeyboard"
                    || packageName.endsWith(".systemui")
                    || packageName.contains("quickstep")
                    || packageName == "com.google.android.apps.nexuslauncher"
                    || packageName == "com.sec.android.app.launcher"
        }

        private fun looksLikeSearchQuery(text: String): Boolean {
            val t = text.trim()
            if (t.isEmpty()) return false
            if (t.contains(" ") && !t.contains("://")) return true
            if (!t.contains('.') && !t.contains('/')) return true
            return false
        }

        private fun isSearchResultsContext(url: String): Boolean {
            val u = url.lowercase()
            return u.contains("/search")
                    || u.contains("google.com/search")
                    || u.contains("bing.com/search")
                    || u.contains("duckduckgo.com")
                    || u.contains("search.yahoo")
                    || u.contains("yandex.")
                    || u.contains("?q=")
                    || u.contains("&q=")
        }

        private fun looksLikeWebContent(url: String): Boolean {
            return url.startsWith("http") || url.contains("://") || url.contains("www.")
        }

        /**
         * Scans text, contentDescription (alt), and view IDs that look like image/CDN URLs.
         */
        private fun scanVisibleContentForNsfw(node: AccessibilityNodeInfo): Boolean {
            return scanNodeRecursive(node, depth = 0, nodesScanned = intArrayOf(0))
        }

        private fun scanNodeRecursive(
            node: AccessibilityNodeInfo,
            depth: Int,
            nodesScanned: IntArray,
        ): Boolean {
            if (depth > MAX_SCAN_DEPTH || nodesScanned[0] >= MAX_SCAN_NODES) return false
            nodesScanned[0]++

            val className = node.className?.toString().orEmpty()
            val isImageLike = className.contains("Image", ignoreCase = true)
                    || className.contains("ImageView", ignoreCase = true)

            val text = buildString {
                node.text?.let { append(it) }
                node.contentDescription?.let {
                    if (isNotEmpty()) append(' ')
                    append(it)
                }
                // Image-adjacent: resource name / hint often carries CDN host or alt
                if (isImageLike) {
                    node.viewIdResourceName?.let {
                        if (isNotEmpty()) append(' ')
                        append(it)
                    }
                    node.hintText?.let {
                        if (isNotEmpty()) append(' ')
                        append(it)
                    }
                } else {
                    // Cheap URL-ish view ids (thumbnails in WebView wrappers)
                    node.viewIdResourceName?.let { id ->
                        if (id.contains("thumb", ignoreCase = true)
                            || id.contains("image", ignoreCase = true)
                            || id.contains("video", ignoreCase = true)
                        ) {
                            if (isNotEmpty()) append(' ')
                            append(id)
                        }
                    }
                }
            }

            if (text.isNotBlank()) {
                if (NsfwKeywords.isPornVisibleContent(text)) return true
                // Domain fragments in alt / description
                if (text.contains('.') && text.length < 500) {
                    Utils.parseHostNameFromUrl(text)?.let { host ->
                        if (NsfwDomainRepository.isBlocked(host)) return true
                    }
                }
            }

            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                val hit = scanNodeRecursive(child, depth + 1, nodesScanned)
                child.recycle()
                if (hit) return true
            }
            return false
        }

        private fun extractSearchQuery(url: String): String? {
            return runCatching {
                val uri = url.toUri()
                uri.getQueryParameter("q")
                    ?: uri.getQueryParameter("query")
                    ?: uri.getQueryParameter("p")
                    ?: uri.getQueryParameter("text")
            }.getOrNull()
        }

        private val urlBarNodeIds = setOf(
            ":id/url_bar",
            ":id/mozac_browser_toolbar_url_view",
            ":id/url",
            ":id/search",
            ":id/omnibarTextInput",
            ":id/url_field",
            ":id/location_bar_edit_text",
            ":id/location_bar_edit",
            ":id/addressbarEdit",
            ":id/bro_omnibar_address_title_text",
            ":id/cbn_tv_title",
            ":id/url_bar_title",
            ":id/location_bar",
            ":id/search_box_text",
            ":id/search_edit_text",
            ":id/omnibar_text",
        )

        private fun extractBrowserUrl(node: AccessibilityNodeInfo, packageName: String): String {
            try {
                if (node.className == "android.widget.EditText") {
                    val txtSequence = node.text
                    if (!txtSequence.isNullOrBlank()) {
                        return txtSequence.toString()
                    }
                }

                for (id in urlBarNodeIds) {
                    val urlBarNodes = node.findAccessibilityNodeInfosByViewId(packageName + id)
                    if (urlBarNodes.isNotEmpty()) {
                        val txtSequence = urlBarNodes.first().text
                        if (!txtSequence.isNullOrBlank()) {
                            return txtSequence.toString()
                        }
                    }
                }
            } catch (ignored: Exception) {
            }

            return ""
        }
    }
}
