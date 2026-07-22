/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mindful/config/navigation/app_routes.dart';
import 'package:mindful/config/navigation/navigation_service.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels local notifications for todo reminders.
class TodoReminderService {
  TodoReminderService._();

  static final TodoReminderService instance = TodoReminderService._();

  static const _channelId = 'mindful.notification.channel.TODO_REMINDERS';
  static const _channelName = 'Task Reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for your tasks and todos.',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == AppRoutes.tasksPath) {
      NavigationService.instance.goToRoute(AppRoutes.tasksPath);
    }
  }

  Future<void> scheduleReminder(Todo todo) async {
    if (!_initialized) await init();

    final reminderAt = todo.reminderAt;
    if (reminderAt == null || reminderAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(reminderAt, tz.local);

    await _plugin.zonedSchedule(
      todo.id,
      'Task reminder',
      todo.title,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: AppRoutes.tasksPath,
    );
  }

  Future<void> cancelReminder(int todoId) async {
    if (!_initialized) await init();
    await _plugin.cancel(todoId);
  }

  Future<void> rescheduleAll(List<Todo> todos) async {
    if (!_initialized) await init();

    for (final todo in todos) {
      await cancelReminder(todo.id);
      if (!todo.isCompleted) {
        await scheduleReminder(todo);
      }
    }
  }
}
