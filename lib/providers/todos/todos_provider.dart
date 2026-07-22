/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/database/daos/todos_dao.dart';
import 'package:mindful/core/enums/todo_priority.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/services/drift_db_service.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/core/services/todo_reminder_service.dart';
import 'package:mindful/core/utils/todo_utils.dart';

final pendingTodosProvider = StreamProvider<List<Todo>>(
  (ref) => DriftDbService.instance.driftDb.todosDao.watchPendingTodos(),
);

final completedTodayTodosProvider = StreamProvider<List<Todo>>(
  (ref) => DriftDbService.instance.driftDb.todosDao.watchCompletedTodayTodos(),
);

final todosNotifierProvider = Provider<TodosNotifier>(
  (ref) => TodosNotifier(),
);

class TodosNotifier {
  TodosDao get _dao => DriftDbService.instance.driftDb.todosDao;

  Future<int> addTodo({
    required String title,
    DateTime? dueDate,
    int? dueTimeMinutes,
    DateTime? reminderAt,
    bool remindMe = false,
    TodoPriority priority = TodoPriority.medium,
  }) async {
    final resolvedReminder = TodoUtils.resolveReminderAt(
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
      reminderAt: reminderAt,
      remindMe: remindMe,
    );

    final id = await _dao.insertTodo(
      TodosTableCompanion.insert(
        title: title.trim(),
        dueDate: Value(dueDate?.dateOnly),
        dueTimeMinutes: Value(dueTimeMinutes),
        reminderAt: Value(resolvedReminder),
        priority: Value(priority),
      ),
    );

    final todo = await _dao.fetchTodoById(id);
    if (todo != null) {
      await TodoReminderService.instance.scheduleReminder(todo);
      await _syncWidget();
    }

    return id;
  }

  Future<void> updateTodo({
    required Todo todo,
    required String title,
    DateTime? dueDate,
    int? dueTimeMinutes,
    DateTime? reminderAt,
    bool remindMe = false,
    TodoPriority priority = TodoPriority.medium,
  }) async {
    final resolvedReminder = TodoUtils.resolveReminderAt(
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
      reminderAt: reminderAt,
      remindMe: remindMe,
    );

    final updated = todo.copyWith(
      title: title.trim(),
      dueDate: Value(dueDate?.dateOnly),
      dueTimeMinutes: Value(dueTimeMinutes),
      reminderAt: Value(resolvedReminder),
      priority: priority,
    );

    await _dao.updateTodo(updated);
    await TodoReminderService.instance.cancelReminder(todo.id);
    await TodoReminderService.instance.scheduleReminder(updated);
    await _syncWidget();
  }

  Future<void> completeTodo(int id) async {
    await TodoReminderService.instance.cancelReminder(id);
    await _dao.completeTodo(id);
    await _syncWidget(triggerCelebration: true);
  }

  Future<void> deleteTodo(int id) async {
    await TodoReminderService.instance.cancelReminder(id);
    await _dao.deleteTodo(id);
    await _syncWidget();
  }

  Future<void> clearCompletedToday() async {
    await _dao.clearCompletedToday();
    await _syncWidget();
  }

  Future<void> syncWidgetSnapshot() => _syncWidget();

  /// Applies completions tapped on the home-screen widget.
  Future<void> applyPendingWidgetCompletions() async {
    final ids =
        await MethodChannelService.instance.consumePendingTodoCompletions();
    if (ids.isEmpty) return;

    for (final id in ids) {
      await TodoReminderService.instance.cancelReminder(id);
      await _dao.completeTodo(id);
    }
    await _syncWidget(triggerCelebration: true);
  }

  Future<void> _syncWidget({bool triggerCelebration = false}) async {
    final pending = await _dao.fetchTodayPendingTodos();
    // For today: high → medium → low
    pending.sort((a, b) {
      final byPriority =
          a.priority.sortWeight.compareTo(b.priority.sortWeight);
      if (byPriority != 0) return byPriority;
      return b.createdAt.compareTo(a.createdAt);
    });

    final completed = await _dao.fetchCompletedTodayTodos();
    final totalCount = pending.length + completed.length;
    final doneCount = completed.length;
    final allDone = totalCount > 0 && pending.isEmpty;

    // Open tasks first (priority sorted); completed at bottom with red cross
    final tasks = [
      ...pending.map(
        (todo) => {
          'id': todo.id,
          'title': todo.title,
          'priority': todo.priority.index,
          'done': false,
        },
      ),
      ...completed.map(
        (todo) => {
          'id': todo.id,
          'title': todo.title,
          'priority': todo.priority.index,
          'done': true,
        },
      ),
    ].take(5).toList();

    final snapshot = jsonEncode({
      'totalCount': totalCount,
      'doneCount': doneCount,
      'pendingCount': pending.length,
      'allDone': allDone,
      'celebrate': triggerCelebration && allDone,
      'tasks': tasks,
    });

    await MethodChannelService.instance.updateTodoWidgetSnapshot(snapshot);

    if (triggerCelebration && allDone) {
      Future.delayed(const Duration(seconds: 3), () async {
        await clearCompletedToday();
      });
    }
  }
}
