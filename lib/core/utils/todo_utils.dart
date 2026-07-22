/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:intl/intl.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/enums/todo_priority.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';

enum TodoListSection {
  overdue,
  dueToday,
  noDate,
}

/// Helpers for grouping and sorting todos in the UI.
class TodoUtils {
  TodoUtils._();

  static DateTime get _today => DateTime.now().dateOnly;

  static bool isOverdue(Todo todo) {
    final due = todo.dueDate?.dateOnly;
    return due != null && due.isBefore(_today);
  }

  static bool isDueToday(Todo todo) {
    final due = todo.dueDate?.dateOnly;
    return due != null && due.isAtSameMomentAs(_today);
  }

  static bool isUpcoming(Todo todo) {
    final due = todo.dueDate?.dateOnly;
    return due != null && due.isAfter(_today);
  }

  static bool isUndated(Todo todo) => todo.dueDate == null;

  static int compareTodos(Todo a, Todo b) {
    final dueCompare = _compareDueDates(a, b);
    if (dueCompare != 0) return dueCompare;

    final priorityCompare =
        a.priority.sortWeight.compareTo(b.priority.sortWeight);
    if (priorityCompare != 0) return priorityCompare;

    return b.createdAt.compareTo(a.createdAt);
  }

  static int _compareDueDates(Todo a, Todo b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.dateOnly.compareTo(b.dueDate!.dateOnly);
  }

  static Map<TodoListSection, List<Todo>> groupForTodayTab(List<Todo> todos) {
    final overdue = <Todo>[];
    final dueToday = <Todo>[];
    final noDate = <Todo>[];

    for (final todo in todos) {
      if (isOverdue(todo)) {
        overdue.add(todo);
      } else if (isDueToday(todo)) {
        dueToday.add(todo);
      } else if (isUndated(todo)) {
        noDate.add(todo);
      }
    }

    overdue.sort((a, b) {
      final byPriority =
          a.priority.sortWeight.compareTo(b.priority.sortWeight);
      if (byPriority != 0) return byPriority;
      return compareTodos(a, b);
    });
    dueToday.sort((a, b) {
      final byPriority =
          a.priority.sortWeight.compareTo(b.priority.sortWeight);
      if (byPriority != 0) return byPriority;
      return compareTodos(a, b);
    });
    noDate.sort((a, b) {
      final byPriority =
          a.priority.sortWeight.compareTo(b.priority.sortWeight);
      if (byPriority != 0) return byPriority;
      return compareTodos(a, b);
    });

    return {
      TodoListSection.overdue: overdue,
      TodoListSection.dueToday: dueToday,
      TodoListSection.noDate: noDate,
    };
  }

  static List<Todo> filterUpcoming(List<Todo> todos) {
    final upcoming = todos.where(isUpcoming).toList()..sort(compareTodos);
    return upcoming;
  }

  static String dueLabel(Todo todo) {
    if (todo.dueDate == null) return 'No date';

    final due = todo.dueDate!.dateOnly;
    final today = _today;
    final label = switch (due.compareTo(today)) {
      < 0 => 'Overdue · ${DateFormat.MMMd().format(due)}',
      0 => 'Today',
      _ => DateFormat.MMMd().format(due),
    };

    if (todo.dueTimeMinutes != null) {
      return '$label · ${_formatMinutes(todo.dueTimeMinutes!)}';
    }

    return label;
  }

  static String _formatMinutes(int minutes) {
    final dt = DateTime(0, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat.jm().format(dt);
  }

  static DateTime? resolveReminderAt({
    required DateTime? dueDate,
    required int? dueTimeMinutes,
    required DateTime? reminderAt,
    required bool remindMe,
  }) {
    if (!remindMe) return null;
    if (reminderAt != null) return reminderAt;

    if (dueDate == null) return null;

    if (dueTimeMinutes != null) {
      return dueDate.dateOnly.add(Duration(minutes: dueTimeMinutes));
    }

    return dueDate.dateOnly.add(const Duration(hours: 9));
  }
}
