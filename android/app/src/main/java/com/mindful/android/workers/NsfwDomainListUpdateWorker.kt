package com.mindful.android.workers

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.mindful.android.helpers.storage.SharedPrefsHelper
import com.mindful.android.models.Wellbeing
import com.mindful.android.utils.NsfwDomainRepository
import java.util.concurrent.TimeUnit

/**
 * Refreshes the Blocklist Project porn domain list daily on Wi-Fi.
 */
class NsfwDomainListUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    companion object {
        private const val TAG = "Mindful.NsfwDomainWorker"
        private const val WORK_NAME = "nsfw_domain_list_daily_refresh"

        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.UNMETERED)
                .build()

            val request = PeriodicWorkRequestBuilder<NsfwDomainListUpdateWorker>(
                24, TimeUnit.HOURS,
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
            Log.d(TAG, "schedule: daily domain list refresh scheduled")
        }
    }

    override fun doWork(): Result {
        val wellbeing = SharedPrefsHelper.getSetWellBeingSettings(applicationContext, null)
        val kidsMode = SharedPrefsHelper.getSetKidsMode(applicationContext, null)
        if (!kidsMode && !wellbeing.blockNsfwSites) {
            return Result.success()
        }
        return try {
            NsfwDomainRepository.initialize(applicationContext)
            NsfwDomainRepository.refreshIfNeeded(applicationContext, force = true)
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "doWork failed", e)
            Result.retry()
        }
    }
}
