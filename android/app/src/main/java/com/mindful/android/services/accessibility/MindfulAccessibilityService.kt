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
import android.content.Intent
import android.content.SharedPreferences
import android.content.SharedPreferences.OnSharedPreferenceChangeListener
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityEvent.TYPE_VIEW_SCROLLED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOWS_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import com.mindful.android.AppConstants.FACEBOOK_PACKAGE
import com.mindful.android.AppConstants.INSTAGRAM_PACKAGE
import com.mindful.android.AppConstants.REDDIT_PACKAGE
import com.mindful.android.AppConstants.SNAPCHAT_PACKAGE
import com.mindful.android.AppConstants.YOUTUBE_PACKAGE
import com.mindful.android.R
import com.mindful.android.enums.PlatformFeatures
import com.mindful.android.helpers.storage.SharedPrefsHelper
import com.mindful.android.models.Wellbeing
import com.mindful.android.utils.NsfwDomainRepository
import com.mindful.android.utils.NsfwKeywords
import com.mindful.android.workers.NsfwDomainListUpdateWorker
import com.mindful.android.receivers.DeviceAppsChangedReceiver
import com.mindful.android.utils.ThreadUtils
import com.mindful.android.utils.executors.Throttler
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * An AccessibilityService that monitors app usage and blocks access to specified content based on user settings.
 */
class MindfulAccessibilityService : AccessibilityService(), OnSharedPreferenceChangeListener {
    companion object {
        private const val TAG = "Mindful.MindfulAccessibilityService"
        private const val TOAST_MIN_INTERVAL_MS = 1500L

        const val ACTION_PERFORM_HOME_PRESS = "com.mindful.android.action.performHomePress"
        const val ACTION_MIDNIGHT_ACCESSIBILITY_RESET =
            "com.mindful.android.action.midnightAccessibilityReset"
        const val ACTION_TAMPER_PROTECTION_CHANGED =
            "com.mindful.android.action.tamperProtectionChanged"

        // Navigation-start + content-changed for earlier NSFW reaction
        private val desiredEvents = setOf(
            TYPE_WINDOWS_CHANGED,
            TYPE_WINDOW_STATE_CHANGED,
            TYPE_WINDOW_CONTENT_CHANGED,
            TYPE_VIEW_SCROLLED,
        )

        private val browserPackages = mutableSetOf<String>()
        private val shortsPlatformPackages = mutableSetOf<String>()
        private val devicePlatformPackages = mutableSetOf<String>()
    }


    // Bounded pool — avoid backlog under content-changed spam
    private val executorService: ExecutorService = Executors.newFixedThreadPool(2)
    private val eventInFlight = AtomicBoolean(false)
    private val throttler: Throttler = Throttler(350L)
    private var lastBrowserPackageSeen: String = ""
    private val deviceAppsChangedReceiver: DeviceAppsChangedReceiver =
        DeviceAppsChangedReceiver(onAppsChanged = { refreshServiceConfig() })

    // Managers
    private lateinit var shortsPlatformManager: ShortsPlatformManager
    private lateinit var browserManager: BrowserManager
    private lateinit var deviceFeaturesManager: DeviceFeaturesManager
    private lateinit var trackingManager: TrackingManager

    private var wellbeing = Wellbeing()
    private var kidsMode = false
    private var lastBlockedToastAtMs: Long = 0L
    private var lastForegroundPackage: String = ""

    override fun onCreate() {
        super.onCreate()
        trackingManager = TrackingManager(context = this)
        deviceFeaturesManager = DeviceFeaturesManager(
            context = this,
            blockedContentGoBack = this::goBackWithToast
        )
        shortsPlatformManager = ShortsPlatformManager(
            context = this,
            blockedContentGoBack = this::goBackWithToast
        )
        browserManager = BrowserManager(
            context = this,
            shortsPlatformManager = shortsPlatformManager,
            exitBlockedContent = this::exitBlockedContent
        )

        // Register shared prefs listener and load data
        SharedPrefsHelper.registerUnregisterListenerToListenablePrefs(this, true, this)
        wellbeing = SharedPrefsHelper.getSetWellBeingSettings(this, null)
        kidsMode = SharedPrefsHelper.getSetKidsMode(this, null)

        // Register listener for install and uninstall events
        deviceAppsChangedReceiver.register(this)
    }


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_MIDNIGHT_ACCESSIBILITY_RESET -> {
                shortsPlatformManager.resetShortsScreenTime()
                Log.d(TAG, "onStartCommand: Midnight reset completed")
            }

            ACTION_TAMPER_PROTECTION_CHANGED -> {
                Log.d(TAG, "onStartCommand: Tamper protection changed")
                refreshServiceConfig()
            }

            ACTION_PERFORM_HOME_PRESS -> {
                Log.d(TAG, "onStartCommand: Pressing home button")
                goBackWithToast(GLOBAL_ACTION_HOME)
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onServiceConnected() {
        refreshServiceConfig()
        trackingManager.stopManualTracking()
        Log.d(TAG, "onCreate: Accessibility service started successfully")
        super.onServiceConnected()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        try {
            if (!desiredEvents.contains(event.eventType) || executorService.isShutdown) return

            // Drop overlapping content-changed floods — keeps latency low for the next event
            if (event.eventType == TYPE_WINDOW_CONTENT_CHANGED
                && !eventInFlight.compareAndSet(false, true)
            ) {
                return
            }

            val eventPackageName = event.packageName?.toString() ?: return
            val eventType = event.eventType

            executorService.submit {
                try {
                    handleAccessibilityEvent(eventPackageName, eventType)
                } finally {
                    if (eventType == TYPE_WINDOW_CONTENT_CHANGED) {
                        eventInFlight.set(false)
                    }
                }
            }
        } catch (ignored: Exception) {
        }
    }

    private fun handleAccessibilityEvent(eventPackageName: String, eventType: Int) {
        val isSystemUi = BrowserManager.isTransientSystemUi(eventPackageName)

        // Notification shade / QS must NOT reset NSFW sticky or pause detection
        if (!isSystemUi && eventPackageName != lastForegroundPackage) {
            lastForegroundPackage = eventPackageName
            browserManager.onForegroundPackageChanged(eventPackageName)
            if (eventPackageName in browserPackages) {
                lastBrowserPackageSeen = eventPackageName
            }
        }

        if (kidsMode && eventPackageName == YOUTUBE_PACKAGE) {
            exitBlockedContent(GLOBAL_ACTION_HOME, true)
            return
        }

        if (!shouldBlockContent()) return

        val kidsModeEnabled = kidsMode
        val wellBeing = effectiveWellbeing(kidsModeEnabled)

        // Prefer the real browser tree when shade is open but sticky NSFW is active
        val targetPackage = when {
            isSystemUi && wellBeing.blockNsfwSites && browserManager.hasActiveSticky() ->
                browserManager.stickyBrowserPackageOrEmpty()
                    .ifEmpty { lastBrowserPackageSeen }

            isSystemUi && wellBeing.blockNsfwSites && lastBrowserPackageSeen.isNotEmpty() ->
                lastBrowserPackageSeen

            else -> eventPackageName
        }

        val node = resolveNodeForPackage(targetPackage, eventPackageName) ?: return

        trackingManager.onNewEvent(node.packageName?.toString() ?: targetPackage)

        processEventInBackground(
            packageName = if (targetPackage.isNotEmpty()) targetPackage else eventPackageName,
            node = node,
            wellBeing = wellBeing,
            isKidsModeEnabled = kidsModeEnabled,
            eventType = eventType,
        )
    }

    /**
     * When SystemUI is focused, try to find the underlying browser window so
     * NSFW checks keep running mid-page-load during shade pull-down.
     */
    private fun resolveNodeForPackage(
        targetPackage: String,
        eventPackageName: String,
    ): AccessibilityNodeInfo? {
        if (targetPackage.isNotEmpty() && targetPackage != eventPackageName) {
            try {
                windows?.forEach { window ->
                    val root = window.root ?: return@forEach
                    val pkg = root.packageName?.toString()
                    if (pkg == targetPackage) return root
                }
            } catch (ignored: Exception) {
            }
        }

        if (eventPackageName == REDDIT_PACKAGE) {
            // Reddit needs source node for shorts — handled by caller path via root
        }

        return rootInActiveWindow
    }

    /**
     * Processes accessibility event in background thread instead of main thread.
     *
     * @param packageName The package name of the app generating the event.
     * @param node        The accessibility node representing the UI element currently in focus.
     */
    private fun processEventInBackground(
        packageName: String,
        node: AccessibilityNodeInfo,
        wellBeing: Wellbeing,
        isKidsModeEnabled: Boolean,
        eventType: Int = 0,
    ) {
        try {
            if (isKidsModeEnabled && packageName == YOUTUBE_PACKAGE) {
                exitBlockedContent(GLOBAL_ACTION_HOME, true)
                return
            }

            when (packageName) {
                in devicePlatformPackages ->
                    deviceFeaturesManager.blockFeatures(packageName, node, wellBeing)

                in shortsPlatformPackages ->
                    shortsPlatformManager.blockDistraction(packageName, node, wellBeing)

                in browserPackages ->
                    browserManager.blockDistraction(packageName, node, wellBeing)

                else -> {
                    // Shade open but we resolved a browser node — still run NSFW
                    if (wellBeing.blockNsfwSites
                        && packageName.isNotEmpty()
                        && (browserManager.hasActiveSticky()
                                || packageName == lastBrowserPackageSeen)
                    ) {
                        browserManager.blockDistraction(packageName, node, wellBeing)
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(
                TAG,
                "processEventInBackground: Failed to process accessibility event in background",
                e
            )
            SharedPrefsHelper.insertCrashLogToPrefs(this, e)
        }
    }


    /**
     * Determines whether content should be blocked based on the current settings.
     *
     * @return `true` if content should be blocked based on the current settings,
     * `false` otherwise.
     */
    private fun shouldBlockContent(): Boolean {
        return kidsMode ||
                wellbeing.blockedFeatures.isNotEmpty() ||
                wellbeing.blockedWebsites.isNotEmpty() ||
                wellbeing.nsfwWebsites.isNotEmpty() ||
                wellbeing.blockNsfwSites
    }

    /**
     * Applies Kids Mode without overwriting the user's own wellbeing choices.
     * Turning it off therefore restores the exact settings that existed before.
     */
    private fun effectiveWellbeing(isKidsModeEnabled: Boolean = kidsMode): Wellbeing {
        if (!isKidsModeEnabled) return wellbeing.copy()

        return wellbeing.copy(
            blockNsfwSites = true,
            allowedShortsTimeMs = -1,
            blockedFeatures = PlatformFeatures.values().toSet(),
            blockedWebsites = wellbeing.blockedWebsites + setOf("youtube.com", "youtu.be"),
        )
    }


    /**
     * Performs the back action (throttled) for shorts / device features.
     */
    private fun goBackWithToast(customAction: Int? = null) {
        throttler.submit {
            exitBlockedContent(
                action = customAction ?: GLOBAL_ACTION_BACK,
                immediate = true
            )
        }
    }

    /**
     * Exit blocked content. NSFW passes [immediate]=true so HOME is not delayed by SafeSearch-style waits.
     * Toast is always rate-limited separately to avoid spam on rapid retries.
     */
    private fun exitBlockedContent(action: Int, immediate: Boolean) {
        val run = {
            ThreadUtils.runOnMainThread {
                performGlobalAction(action)
                maybeShowBlockedToast()
            }
        }
        if (immediate) {
            run()
        } else {
            throttler.submit(run)
        }
    }

    private fun maybeShowBlockedToast() {
        val now = System.currentTimeMillis()
        if (now - lastBlockedToastAtMs < TOAST_MIN_INTERVAL_MS) return
        lastBlockedToastAtMs = now
        Toast.makeText(
            this@MindfulAccessibilityService,
            getString(R.string.toast_blocked_content),
            Toast.LENGTH_LONG
        ).show()
    }

    /**
     * Updates the service info with the latest settings and registered packages.
     */
    private fun refreshServiceConfig() {
        try {
            // Using hashset to avoid duplicates
            browserPackages.clear()
            devicePlatformPackages.clear()
            shortsPlatformPackages.clear()
            val pm = packageManager
            val effectiveSettings = effectiveWellbeing()

            // Tamper / uninstall blocking removed — do not gate Settings
            // Check admin and add settings to blocked packages
            // (intentionally disabled)

            // Fetch installed browser packages
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("http://www.google.com"))
            pm.queryIntentActivities(browserIntent, PackageManager.MATCH_ALL).forEach {
                browserPackages.add(it.activityInfo.packageName)
            }

            effectiveSettings.blockedFeatures.forEach { feature ->
                when (feature) {
                    /// Instagram
                    PlatformFeatures.INSTAGRAM_REELS,
                    PlatformFeatures.INSTAGRAM_EXPLORE,
                        -> shortsPlatformPackages.add(INSTAGRAM_PACKAGE)

                    // Snapchat
                    PlatformFeatures.SNAPCHAT_SPOTLIGHT,
                    PlatformFeatures.SNAPCHAT_DISCOVER,
                        -> shortsPlatformPackages.add(SNAPCHAT_PACKAGE)

                    // Facebook
                    PlatformFeatures.FACEBOOK_REELS ->
                        shortsPlatformPackages.add(FACEBOOK_PACKAGE)

                    // Reddit
                    PlatformFeatures.REDDIT_SHORTS ->
                        shortsPlatformPackages.add(REDDIT_PACKAGE)

                    // Youtube
                    PlatformFeatures.YOUTUBE_SHORTS -> {
                        // Add official package
                        shortsPlatformPackages.add(YOUTUBE_PACKAGE)

                        // Now add other unofficial clients
                        val ytIntent =
                            Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com"))
                        pm.queryIntentActivities(ytIntent, PackageManager.MATCH_ALL)
                            .filterNot { browserPackages.contains(it.activityInfo.packageName) }
                            .forEach {
                                shortsPlatformPackages.add(it.activityInfo.packageName)
                            }
                    }
                }
            }


            // Load maintained NSFW domain list for accessibility checks
            if (effectiveSettings.blockNsfwSites) {
                NsfwDomainRepository.initialize(this)
                NsfwDomainRepository.mergeUserDomains(
                    effectiveSettings.nsfwWebsites + effectiveSettings.blockedWebsites,
                )
                NsfwDomainRepository.refreshIfNeeded(this)
                NsfwDomainListUpdateWorker.schedule(this)
                // Warm fuzzy keyword tables on background thread for faster first match
                Thread {
                    NsfwKeywords.isPornSearchQuery("warmup")
                }.start()
            }

            Log.d(
                TAG, "refreshServiceConfig: Accessibility service config updated successfully: " +
                        "\n settings: $effectiveSettings" +
                        "\n device platforms: $devicePlatformPackages" +
                        "\n short platforms: $shortsPlatformPackages" +
                        "\n browsers: $browserPackages"
            )
        } catch (e: Exception) {
            Log.e(TAG, "refreshServiceInfo: Failed to refresh service info", e)
            SharedPrefsHelper.insertCrashLogToPrefs(this, e)
        }
    }

    override fun onSharedPreferenceChanged(prefs: SharedPreferences, changedKey: String?) {
        changedKey?.let { key ->
            if (key == SharedPrefsHelper.PREF_KEY_WELLBEING_SETTINGS) {
                Log.d(TAG, "OnSharedPrefsChanged: Key changed = $changedKey")
                wellbeing = SharedPrefsHelper.getSetWellBeingSettings(this, null)
                refreshServiceConfig()
            } else if (key == SharedPrefsHelper.PREF_KEY_KIDS_MODE) {
                Log.d(TAG, "OnSharedPrefsChanged: Kids Mode changed")
                kidsMode = SharedPrefsHelper.getSetKidsMode(this, null)
                refreshServiceConfig()
            }
        }
    }

    override fun onInterrupt() {
    }

    override fun onDestroy() {
        try {
            executorService.shutdownNow()
            trackingManager.startManualTracking()

            // Unregister prefs listener and receiver
            deviceAppsChangedReceiver.unRegister(this)
            SharedPrefsHelper.registerUnregisterListenerToListenablePrefs(this, false, this)
        } catch (e: Exception) {
            // ignored
        }

        Log.d(TAG, "onDestroy: Accessibility service destroyed")
        super.onDestroy()
    }
}
