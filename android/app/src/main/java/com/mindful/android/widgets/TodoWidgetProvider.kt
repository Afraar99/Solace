package com.mindful.android.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.MainThread
import android.appwidget.AppWidgetProvider
import com.mindful.android.R
import com.mindful.android.helpers.storage.SharedPrefsHelper
import com.mindful.android.utils.AppUtils
import org.json.JSONArray
import org.json.JSONObject

class TodoWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val TAG = "Mindful.TodoWidgetProvider"
        const val ACTION_REFRESH_WIDGET = "com.mindful.android.action.refreshTodoWidgetProvider"
        const val ACTION_COMPLETE_TODO = "com.mindful.android.action.todoWidgetCompleteTodo"
        private const val ACTION_CELEBRATE_PULSE =
            "com.mindful.android.action.todoWidgetCelebratePulse"
        private const val EXTRA_PULSE_STEP = "pulseStep"
        private const val EXTRA_TODO_ID = "todoId"

        private val WHITE = 0xFFF5F5F5.toInt()
        private val RED = 0xFFE53935.toInt()
        private val MUTED_RED = 0xFFFF8A80.toInt()
    }

    data class FontScale(
        val headerSp: Float,
        val countSp: Float,
        val titleSp: Float,
        val checkSp: Float,
        val progressSp: Float,
        val maxRows: Int,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidget(
            context = context,
            appWidgetManager = appWidgetManager,
            appWidgetIds = appWidgetIds,
            triggeredBySystem = true,
            celebrationPulseStep = -1,
        )
    }

    override fun onReceive(context: Context, intent: Intent?) {
        intent?.action?.let { action ->
            when (action) {
                "android.appwidget.action.APPWIDGET_UPDATE_OPTIONS",
                ACTION_REFRESH_WIDGET,
                -> refreshAll(context, celebrationPulseStep = -1)

                ACTION_COMPLETE_TODO -> {
                    val todoId = intent.getIntExtra(EXTRA_TODO_ID, -1)
                    if (todoId > 0) {
                        markTodoDoneInSnapshot(context, todoId)
                    }
                    refreshAll(context, celebrationPulseStep = -1)
                }

                ACTION_CELEBRATE_PULSE -> {
                    val step = intent.getIntExtra(EXTRA_PULSE_STEP, 0)
                    refreshAll(context, celebrationPulseStep = step)
                }

                else -> Log.d(TAG, "Received unhandled action: $action")
            }
        }

        super.onReceive(context, intent)
    }

    private fun refreshAll(context: Context, celebrationPulseStep: Int) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetComponent = ComponentName(context, TodoWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)
        updateWidget(
            context = context,
            appWidgetManager = appWidgetManager,
            appWidgetIds = appWidgetIds,
            triggeredBySystem = false,
            celebrationPulseStep = celebrationPulseStep,
        )
    }

    /**
     * Optimistically mark a task done in SharedPrefs snapshot and queue DB sync for Flutter.
     */
    private fun markTodoDoneInSnapshot(context: Context, todoId: Int) {
        runCatching {
            val snapshot = JSONObject(SharedPrefsHelper.getSetTodoWidgetSnapshot(context, null))
            val tasks = snapshot.optJSONArray("tasks") ?: JSONArray()
            var found = false

            for (i in 0 until tasks.length()) {
                val task = tasks.getJSONObject(i)
                if (task.optInt("id", -1) == todoId && !task.optBoolean("done", false)) {
                    task.put("done", true)
                    found = true
                    break
                }
            }
            if (!found) return

            val pendingCount = (snapshot.optInt("pendingCount", 1) - 1).coerceAtLeast(0)
            val doneCount = snapshot.optInt("doneCount", 0) + 1
            val totalCount = snapshot.optInt("totalCount", tasks.length())
            val allDone = pendingCount == 0 && totalCount > 0

            snapshot.put("tasks", sortTasksForDisplay(tasks))
            snapshot.put("pendingCount", pendingCount)
            snapshot.put("doneCount", doneCount.coerceAtMost(totalCount))
            snapshot.put("allDone", allDone)
            snapshot.put("celebrate", allDone)

            SharedPrefsHelper.getSetTodoWidgetSnapshot(context, snapshot.toString())
            SharedPrefsHelper.enqueuePendingTodoCompletion(context, todoId)

            if (allDone) {
                scheduleCelebrationPulse(context)
            }
        }.getOrElse {
            SharedPrefsHelper.insertCrashLogToPrefs(context, it)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        triggeredBySystem: Boolean,
        celebrationPulseStep: Int,
    ) {
        runCatching {
            val snapshot = JSONObject(SharedPrefsHelper.getSetTodoWidgetSnapshot(context, null))
            val totalCount = snapshot.optInt("totalCount", snapshot.optInt("count", 0))
            val doneCount = snapshot.optInt("doneCount", 0)
            val celebrate = snapshot.optBoolean(
                "celebrate",
                totalCount > 0 && doneCount >= totalCount && snapshot.optInt("pendingCount", 1) == 0,
            )
            val tasks = sortTasksForDisplay(snapshot.optJSONArray("tasks") ?: JSONArray())

            updateViews(
                context = context,
                appWidgetManager = appWidgetManager,
                appWidgetIds = appWidgetIds,
                triggeredBySystem = triggeredBySystem,
                totalCount = totalCount,
                doneCount = doneCount,
                celebrate = celebrate,
                celebrationPulseStep = celebrationPulseStep,
                tasks = tasks,
            )

            if (celebrate && celebrationPulseStep < 0 && totalCount > 0) {
                scheduleCelebrationPulse(context)
            }
        }.getOrElse {
            SharedPrefsHelper.insertCrashLogToPrefs(context, it)
        }
    }

    private fun sortTasksForDisplay(tasks: JSONArray): JSONArray {
        val pending = mutableListOf<JSONObject>()
        val done = mutableListOf<JSONObject>()
        for (i in 0 until tasks.length()) {
            val task = tasks.getJSONObject(i)
            if (task.optBoolean("done", false)) done.add(task) else pending.add(task)
        }
        // High (2) first, then medium (1), then low (0)
        pending.sortBy { prioritySortWeight(it.optInt("priority", 1)) }
        val ordered = JSONArray()
        pending.forEach { ordered.put(it) }
        done.forEach { ordered.put(it) }
        return ordered
    }

    private fun prioritySortWeight(priority: Int): Int = when (priority) {
        2 -> 0 // high
        1 -> 1 // medium
        else -> 2 // low
    }

    private fun scheduleCelebrationPulse(context: Context) {
        val handler = Handler(Looper.getMainLooper())
        listOf(0, 1, 2, 3, 4).forEach { step ->
            handler.postDelayed({
                context.sendBroadcast(
                    Intent(context, TodoWidgetProvider::class.java)
                        .setAction(ACTION_CELEBRATE_PULSE)
                        .putExtra(EXTRA_PULSE_STEP, step),
                )
            }, step * 280L)
        }
    }

    private fun fontScaleForHeight(heightDp: Int): FontScale = when {
        heightDp >= 260 -> FontScale(18f, 24f, 17f, 16f, 12f, 5)
        heightDp >= 200 -> FontScale(16f, 22f, 15f, 15f, 11f, 5)
        heightDp >= 150 -> FontScale(15f, 20f, 14f, 14f, 11f, 5)
        heightDp >= 120 -> FontScale(14f, 18f, 13f, 13f, 10f, 4)
        else -> FontScale(13f, 16f, 12f, 12f, 10f, 3)
    }

    @MainThread
    private fun updateViews(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        triggeredBySystem: Boolean,
        totalCount: Int,
        doneCount: Int,
        celebrate: Boolean,
        celebrationPulseStep: Int,
        tasks: JSONArray,
    ) {
        val rows = listOf(
            RowIds(R.id.todo_row_1, R.id.todo_check_1, R.id.todo_title_1, R.id.todo_line_1),
            RowIds(R.id.todo_row_2, R.id.todo_check_2, R.id.todo_title_2, R.id.todo_line_2),
            RowIds(R.id.todo_row_3, R.id.todo_check_3, R.id.todo_title_3, R.id.todo_line_3),
            RowIds(R.id.todo_row_4, R.id.todo_check_4, R.id.todo_title_4, R.id.todo_line_4),
            RowIds(R.id.todo_row_5, R.id.todo_check_5, R.id.todo_title_5, null),
        )

        val progress = if (totalCount <= 0) 0 else ((doneCount * 100f) / totalCount).toInt()
        val emojiSize = when (celebrationPulseStep) {
            0 -> 56f
            1 -> 78f
            2 -> 92f
            3 -> 78f
            else -> 72f
        }

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val scale = fontScaleForHeight(heightDp)

            RemoteViews(context.packageName, R.layout.widget_todos_layout).let { views ->
                views.setTextViewText(R.id.todo_header_count, totalCount.toString())
                views.setTextViewText(
                    R.id.todo_progress_label,
                    "$doneCount OF $totalCount DONE",
                )
                views.setProgressBar(R.id.todo_progress, 100, progress, false)

                views.setTextViewTextSize(
                    R.id.todo_header_title,
                    TypedValue.COMPLEX_UNIT_SP,
                    scale.headerSp,
                )
                views.setTextViewTextSize(
                    R.id.todo_header_count,
                    TypedValue.COMPLEX_UNIT_SP,
                    scale.countSp,
                )
                views.setTextViewTextSize(
                    R.id.todo_progress_label,
                    TypedValue.COMPLEX_UNIT_SP,
                    scale.progressSp,
                )

                val visibleCount = minOf(tasks.length(), scale.maxRows)
                rows.forEachIndexed { index, row ->
                    if (index < visibleCount) {
                        val task = tasks.getJSONObject(index)
                        val title = task.optString("title", "")
                        val done = task.optBoolean("done", false)
                        val todoId = task.optInt("id", -1)

                        views.setViewVisibility(row.rowId, View.VISIBLE)
                        row.lineId?.let {
                            views.setViewVisibility(it, if (index < visibleCount - 1) View.VISIBLE else View.GONE)
                        }

                        views.setTextViewTextSize(
                            row.titleId,
                            TypedValue.COMPLEX_UNIT_SP,
                            scale.titleSp,
                        )
                        views.setTextViewTextSize(
                            row.checkId,
                            TypedValue.COMPLEX_UNIT_SP,
                            scale.checkSp,
                        )

                        if (done) {
                            views.setTextViewText(row.checkId, "✕")
                            views.setTextColor(row.checkId, RED)
                            views.setInt(row.checkId, "setBackgroundColor", 0x00000000)
                            val struck = SpannableString(title)
                            struck.setSpan(
                                StrikethroughSpan(),
                                0,
                                title.length,
                                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
                            )
                            views.setTextViewText(row.titleId, struck)
                            views.setTextColor(row.titleId, MUTED_RED)
                            views.setInt(
                                row.rowId,
                                "setBackgroundResource",
                                R.drawable.widget_todo_done_row_bg,
                            )
                            // Already done — open tasks on tap
                            views.setOnClickPendingIntent(
                                row.checkId,
                                openTasksPendingIntent(context, 3000 + index),
                            )
                        } else {
                            views.setTextViewText(row.checkId, "")
                            views.setInt(
                                row.checkId,
                                "setBackgroundResource",
                                R.drawable.widget_todo_checkbox_empty,
                            )
                            views.setTextViewText(row.titleId, title)
                            views.setTextColor(row.titleId, WHITE)
                            views.setInt(
                                row.rowId,
                                "setBackgroundResource",
                                R.drawable.widget_todo_open_row_bg,
                            )
                            if (todoId > 0) {
                                views.setOnClickPendingIntent(
                                    row.checkId,
                                    completeTodoPendingIntent(context, todoId),
                                )
                            }
                        }
                    } else {
                        views.setViewVisibility(row.rowId, View.GONE)
                        row.lineId?.let { views.setViewVisibility(it, View.GONE) }
                    }
                }

                if (celebrate && totalCount > 0 && doneCount >= totalCount) {
                    views.setViewVisibility(R.id.todo_celebration, View.VISIBLE)
                    views.setTextViewTextSize(
                        R.id.todo_celebration_emoji,
                        TypedValue.COMPLEX_UNIT_SP,
                        emojiSize,
                    )
                    views.setTextViewText(R.id.todo_celebration_label, "All clear! 🎉")
                } else {
                    views.setViewVisibility(R.id.todo_celebration, View.GONE)
                }

                setUpClickListeners(context, views)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    private fun completeTodoPendingIntent(context: Context, todoId: Int): PendingIntent {
        val intent = Intent(context.applicationContext, TodoWidgetProvider::class.java)
            .setAction(ACTION_COMPLETE_TODO)
            .putExtra(EXTRA_TODO_ID, todoId)
        return PendingIntent.getBroadcast(
            context.applicationContext,
            4000 + todoId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun openTasksPendingIntent(context: Context, requestCode: Int): PendingIntent {
        return PendingIntent.getActivity(
            context.applicationContext,
            requestCode,
            AppUtils.getIntentForMindfulUri(context, "com.mindful.android://open/tasks"),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun setUpClickListeners(context: Context, views: RemoteViews) {
        views.setOnClickPendingIntent(R.id.widgetRoot, openTasksPendingIntent(context, 2101))
        views.setOnClickPendingIntent(R.id.todo_header, openTasksPendingIntent(context, 2101))
        views.setOnClickPendingIntent(
            R.id.todo_add_button,
            PendingIntent.getActivity(
                context.applicationContext,
                2102,
                AppUtils.getIntentForMindfulUri(
                    context,
                    "com.mindful.android://open/tasks?action=add",
                ),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            ),
        )
        views.setOnClickPendingIntent(R.id.todo_celebration, openTasksPendingIntent(context, 2103))
    }

    private data class RowIds(
        val rowId: Int,
        val checkId: Int,
        val titleId: Int,
        val lineId: Int?,
    )
}
