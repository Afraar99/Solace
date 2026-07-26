package com.mindful.android.services.accessibility

import android.content.Context
import android.view.accessibility.AccessibilityNodeInfo
import com.mindful.android.AppConstants.SYSTEM_SETTINGS_PACKAGE
import com.mindful.android.models.Wellbeing

class DeviceFeaturesManager(
    private val context: Context,
    private val blockedContentGoBack: () -> Unit,
) {

    /**
     * Checks if a blocked feature is open and applies restrictions.
     */
    fun blockFeatures(
        packageName: String,
        node: AccessibilityNodeInfo,
        wellbeing: Wellbeing,
    ) {
        val isFeatureOpen = when (packageName) {
            SYSTEM_SETTINGS_PACKAGE -> isSettingsTamperFeatureOpen(context, node)
            else -> false
        }

        if (isFeatureOpen) {
            blockedContentGoBack.invoke()
        }
    }

    companion object {
        /** Tamper protection removed — never block Settings. */
        private fun isSettingsTamperFeatureOpen(
            context: Context,
            node: AccessibilityNodeInfo,
        ): Boolean = false
    }
}
