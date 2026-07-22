package com.mindful.android.services.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.provider.Browser
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.core.net.toUri
import com.mindful.android.models.Wellbeing
import com.mindful.android.utils.NsfwDomains
import com.mindful.android.utils.NsfwKeywords
import com.mindful.android.utils.ThreadUtils
import com.mindful.android.utils.Utils

/**
 * Blocks distracting websites and NSFW content via Accessibility URL-bar inspection.
 *
 * NSFW enforcement uses hard HOME (not SafeSearch-with-same-query) so porn SERPs are not left
 * on the back stack. Keyword matching is best-effort and gameable; the host blocklist is primary
 * for known tube sites. Fullscreen (hidden URL bar) remains an inherent Accessibility ceiling.
 */
class BrowserManager(
    private val context: Context,
    private val shortsPlatformManager: ShortsPlatformManager,
    private val exitBlockedContent: (action: Int, immediate: Boolean) -> Unit,
) {
    /** Last browser package that hit an NSFW block (sticky while that browser stays foreground). */
    private var stickyBrowserPackage: String = ""
    private var stickyBlockedHost: String = ""
    private var stickyBlockedQuery: String = ""
    private var stickyActivatedAtMs: Long = 0L

    private var mLastCleanRedirectUrl = ""

    /**
     * Blocks access to websites and short-form content based on current settings.
     *
     * @param node        The AccessibilityNodeInfo of the current view.
     * @param packageName The package name of the app.
     */
    fun blockDistraction(
        packageName: String,
        node: AccessibilityNodeInfo,
        wellbeing: Wellbeing,
    ) {
        clearStickyIfBrowserLeft(packageName)

        val raw = extractBrowserUrl(node, packageName)

        // URL bar empty: sticky re-HOME only when a blocked *host* was seen (fullscreen gap).
        // Do not re-HOME on empty URL for query-only sticky — that fights clean-home redirect.
        if (raw.isBlank()) {
            if (wellbeing.blockNsfwSites
                && isStickyActive(packageName)
                && stickyBlockedHost.isNotEmpty()
            ) {
                Log.d(TAG, "blockDistraction: Sticky NSFW re-exit (empty URL) in $packageName")
                hardExitNsfw(packageName)
            }
            return
        }

        val url = raw.replace("google.com/amp/s/amp.", "")

        // Omnibox search text (spaces, no host) — check NSFW keywords before requiring a domain
        if (wellbeing.blockNsfwSites && looksLikeSearchQuery(url)) {
            if (containsNsfwKeyword(url)) {
                Log.d(TAG, "blockDistraction: NSFW search query in omnibox for $packageName")
                activateSticky(packageName, host = "", query = url.lowercase())
                hardExitNsfw(packageName)
                return
            }
        }

        // Not a navigable URL yet
        if (url.contains(" ") || !url.contains(".")) return

        val host = Utils.parseHostNameFromUrl(url) ?: return

        // User blocked sites / NSFW sites / built-in NSFW domains (label-safe)
        val hostBlocked = Utils.isHostBlockedBySet(host, wellbeing.blockedWebsites)
                || Utils.isHostBlockedBySet(host, wellbeing.nsfwWebsites)
                || (wellbeing.blockNsfwSites && Utils.isHostBlockedByMap(host, nsfwDomains))

        if (hostBlocked) {
            Log.d(TAG, "blockDistraction: Blocked website $host opened in $packageName")
            if (wellbeing.blockNsfwSites && (
                        Utils.isHostBlockedBySet(host, wellbeing.nsfwWebsites)
                                || Utils.isHostBlockedByMap(host, nsfwDomains)
                        )
            ) {
                activateSticky(packageName, host = host, query = "")
                hardExitNsfw(packageName)
            } else {
                // Manual website block — keep BACK behavior for non-NSFW list
                exitBlockedContent(
                    AccessibilityService.GLOBAL_ACTION_BACK,
                    false
                )
            }
            return
        }

        // Sticky: same blocked host reappeared
        if (wellbeing.blockNsfwSites && isStickyActive(packageName)) {
            if (stickyBlockedHost.isNotEmpty() && Utils.hostMatchesBlockedDomain(host, stickyBlockedHost)) {
                Log.d(TAG, "blockDistraction: Sticky NSFW host re-hit $host")
                hardExitNsfw(packageName)
                return
            }
        }

        // Block short form content
        if (shortsPlatformManager.checkAndBlockShortsOnBrowser(wellbeing, url)) return

        // NSFW search URLs (q=) — hard exit, do not SafeSearch-with-same-query
        if (wellbeing.blockNsfwSites) {
            val query = extractSearchQuery(url)?.lowercase()
            if (!query.isNullOrBlank() && containsNsfwKeyword(query)) {
                Log.d(TAG, "blockDistraction: NSFW search URL query blocked in $packageName")
                activateSticky(packageName, host = host, query = query)
                hardExitNsfw(packageName, openCleanHome = true)
                return
            }
            if (stickyBlockedQuery.isNotEmpty()
                && isStickyActive(packageName)
                && query != null
                && query.contains(stickyBlockedQuery)
            ) {
                hardExitNsfw(packageName, openCleanHome = true)
            }
        }
    }

    /**
     * Called when the foreground package changes so sticky can clear when leaving the browser.
     */
    fun onForegroundPackageChanged(packageName: String) {
        clearStickyIfBrowserLeft(packageName)
    }

    private fun hardExitNsfw(packageName: String, openCleanHome: Boolean = false) {
        exitBlockedContent(AccessibilityService.GLOBAL_ACTION_HOME, true)
        if (openCleanHome) {
            redirectToCleanHome(packageName)
        }
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
            // Allow a later clean redirect after the browser settles
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

    private fun isStickyActive(packageName: String): Boolean {
        if (stickyBrowserPackage.isEmpty() || stickyBrowserPackage != packageName) return false
        val age = System.currentTimeMillis() - stickyActivatedAtMs
        if (age > STICKY_MAX_AGE_MS) {
            clearSticky()
            return false
        }
        return stickyBlockedHost.isNotEmpty() || stickyBlockedQuery.isNotEmpty()
    }

    private fun clearStickyIfBrowserLeft(packageName: String) {
        if (stickyBrowserPackage.isNotEmpty() && packageName != stickyBrowserPackage) {
            clearSticky()
        }
    }

    private fun clearSticky() {
        stickyBrowserPackage = ""
        stickyBlockedHost = ""
        stickyBlockedQuery = ""
        stickyActivatedAtMs = 0L
    }

    companion object {
        private const val TAG = "Mindful.BrowserEventsManager"

        /** Safety bound only — primary sticky lifetime is "same browser still foreground". */
        private const val STICKY_MAX_AGE_MS = 5 * 60 * 1000L

        private var nsfwDomains: Map<String, Boolean> = mapOf()

        fun initializeNsfwDomains() {
            nsfwDomains = NsfwDomains.init()
        }

        fun clearNsfwDomains() {
            nsfwDomains = mapOf()
        }

        private fun looksLikeSearchQuery(text: String): Boolean {
            val t = text.trim()
            if (t.isEmpty()) return false
            // Typed query in omnibox (spaces) or no scheme/host shape
            if (t.contains(" ") && !t.contains("://")) return true
            if (!t.contains('.') && !t.contains('/')) return true
            return false
        }

        private fun containsNsfwKeyword(text: String): Boolean {
            val lower = text.lowercase()
            return NsfwKeywords.keywords.any { keyword ->
                // Prefer whole-token style checks for short keywords to reduce false positives
                if (keyword.length <= 3) {
                    Regex("\\b${Regex.escape(keyword)}\\b").containsMatchIn(lower)
                } else {
                    lower.contains(keyword)
                }
            }
        }

        private fun extractSearchQuery(url: String): String? {
            return runCatching {
                val uri = url.toUri()
                uri.getQueryParameter("q")
                    ?: uri.getQueryParameter("query")
                    ?: uri.getQueryParameter("p") // Yahoo
            }.getOrNull()
        }

        /**
         * List of Ids of URL Bars used by different browsers.
         */
        private val urlBarNodeIds = setOf(
            ":id/url_bar",  // Chrome
            ":id/mozac_browser_toolbar_url_view",  // Firefox
            ":id/url",
            ":id/search",
            ":id/omnibarTextInput", // Duck duck go
            ":id/url_field", // Opera
            ":id/location_bar_edit_text", // often Samsung / Chromium
            ":id/location_bar_edit",
            ":id/addressbarEdit",
            ":id/bro_omnibar_address_title_text",
            ":id/cbn_tv_title", // Quetta Browser
            ":id/url_bar_title", // Samsung Internet variants
            ":id/location_bar",
        )

        /**
         * Extracts the URL or omnibox text from the given AccessibilityNodeInfo.
         */
        private fun extractBrowserUrl(node: AccessibilityNodeInfo, packageName: String): String {
            try {
                // Find by input field class (works while typing / suggestions open)
                if (node.className == "android.widget.EditText") {
                    val txtSequence = node.text
                    if (!txtSequence.isNullOrBlank()) {
                        return txtSequence.toString()
                    }
                }

                // Find by known URL bar ids — still read when suggestions dropdown is open
                // so NSFW queries in the omnibox are not skipped.
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
