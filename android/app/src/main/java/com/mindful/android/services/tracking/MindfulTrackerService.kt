package com.mindful.android.services.tracking

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.annotation.WorkerThread
import com.mindful.android.AppConstants
import com.mindful.android.R
import com.mindful.android.generics.ServiceBinder
import com.mindful.android.helpers.device.NotificationHelper
import com.mindful.android.helpers.storage.SharedPrefsHelper
import java.util.concurrent.ConcurrentHashMap

class MindfulTrackerService : Service() {
    companion object {
        private const val TAG = "Mindful.MindfulTrackerService"
        /** Only prevents double-fire from usage/accessibility spam — not a real cooldown */
        private const val BREATH_DEBOUNCE_MS = 2_500L
    }

    private val mBinder = ServiceBinder(this@MindfulTrackerService)

    private lateinit var overlayManager: OverlayManager
    private lateinit var reminderManager: ReminderManager

    private lateinit var restrictionManager: RestrictionManager
    val getRestrictionManager get() = restrictionManager

    private lateinit var launchTrackingManager: LaunchTrackingManager
    val getLaunchTrackingManager get() = launchTrackingManager

    /** Last time breath overlay was shown per package (debounce only) */
    private val lastBreathShownAt = ConcurrentHashMap<String, Long>()
    private var lastForegroundPackage: String = ""

    override fun onCreate() {
        overlayManager = OverlayManager(this)
        reminderManager = ReminderManager(overlayManager, ::onNewAppLaunch)
        restrictionManager = RestrictionManager(this, ::stopIfNoUsage)
        launchTrackingManager = LaunchTrackingManager(
            context = this,
            onNewAppLaunched = ::onNewAppLaunch,
            dismissOverlay = { overlayManager.dismissSheetOverlay() },
            cancelReminders = { reminderManager.cancelReminders() },
        )
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        if (intent?.action == ServiceBinder.ACTION_START_MINDFUL_SERVICE) {
            startFgService()
            return START_STICKY
        }

        stopIfNoUsage()
        return START_NOT_STICKY
    }

    private fun startFgService() {
        try {
            val notification = NotificationHelper.buildFgServiceNotification(
                this,
                getString(R.string.app_blocker_running_notification_info)
            )
            startForeground(AppConstants.TRACKER_SERVICE_NOTIFICATION_ID, notification)
            Log.d(TAG, "startFgService: TRACKER service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "startFgService: Failed to start TRACKER service", e)
            SharedPrefsHelper.insertCrashLogToPrefs(this, e)
            stopIfNoUsage()
        }
    }

    fun onMidnightReset() {
        restrictionManager.resetCache()
        overlayManager.dismissSheetOverlay()
        val reminderAwaiting = reminderManager.cancelReminders()

        // Means app is active but timer is not over and now it is reset so re-launch same event again
        if (reminderAwaiting) launchTrackingManager.reInvokeLastLaunchEvent()
    }


    @WorkerThread
    private fun onNewAppLaunch(packageName: String) {
        try {
            reminderManager.cancelReminders()
            overlayManager.dismissSheetOverlay()

            /// Left another app — next open of that app should breathe again
            if (lastForegroundPackage.isNotEmpty() && lastForegroundPackage != packageName) {
                lastBreathShownAt.remove(lastForegroundPackage)
            }
            lastForegroundPackage = packageName

            /// check current restrictions
            val currentOrFutureState = restrictionManager.isAppRestricted(packageName)
            Log.d(TAG, "onNewAppLaunch: $packageName's evaluated state => $currentOrFutureState")

            /// Hard-blocked apps skip the breath pause
            if (currentOrFutureState != null && currentOrFutureState.timeLeftMillis <= 0L) {
                overlayManager.showSheetOverlay(
                    packageName = packageName,
                    restrictionState = currentOrFutureState,
                )
                return
            }

            /// Breathing pause every time the user opens a selected app
            if (restrictionManager.needsBreathPause(packageName) &&
                !isBreathDebounced(packageName)
            ) {
                Log.d(TAG, "onNewAppLaunch: Showing breath pause for $packageName")
                markBreathShown(packageName)
                overlayManager.showBreathPauseOverlay(
                    packageName = packageName,
                    onContinue = {
                        currentOrFutureState?.let {
                            reminderManager.scheduleReminders(
                                packageName = packageName,
                                state = it,
                            )
                        }
                    },
                )
                return
            }

            /// Under limit but will be exhausted in some time
            currentOrFutureState?.let {
                reminderManager.scheduleReminders(
                    packageName = packageName,
                    state = it,
                )
            }
        } catch (e: Exception) {
            SharedPrefsHelper.insertCrashLogToPrefs(this, e)
            Log.e(TAG, "onNewAppLaunch: Failed to process new app launch event", e)
        }
    }

    private fun isBreathDebounced(packageName: String): Boolean {
        val last = lastBreathShownAt[packageName] ?: return false
        return System.currentTimeMillis() - last < BREATH_DEBOUNCE_MS
    }

    private fun markBreathShown(packageName: String) {
        lastBreathShownAt[packageName] = System.currentTimeMillis()
    }

    private fun stopIfNoUsage() {
        if (restrictionManager.isIdle) {
            Log.d(TAG, "Service no longer needed, stopping")
            launchTrackingManager.dispose()
            reminderManager.cancelReminders()
            overlayManager.dismissSheetOverlay()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: TRACKER service destroyed successfully")
        super.onDestroy()
    }


    override fun onBind(intent: Intent): IBinder? {
        return if (intent.action == ServiceBinder.ACTION_BIND_TO_MINDFUL) mBinder else null
    }
}
