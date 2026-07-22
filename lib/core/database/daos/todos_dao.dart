/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/database/tables/todos_table.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';

part 'todos_dao.g.dart';

@DriftAccessor(tables: [TodosTable])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  /// Watches all pending todos ordered by creation time.
  Stream<List<Todo>> watchPendingTodos() => (select(todosTable)
        ..where((t) => t.isCompleted.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();

  Future<List<Todo>> fetchPendingTodos() => (select(todosTable)
        ..where((t) => t.isCompleted.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .get();

  Future<Todo?> fetchTodoById(int id) =>
      (select(todosTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTodo(TodosTableCompanion entry) =>
      into(todosTable).insert(entry);

  Future<bool> updateTodo(Todo todo) => update(todosTable).replace(todo);

  Future<int> completeTodo(int id) => (update(todosTable)
        ..where((t) => t.id.equals(id)))
      .write(
    TodosTableCompanion(
      isCompleted: const Value(true),
      completedAt: Value(DateTime.now()),
    ),
  );

  Future<int> deleteTodo(int id) =>
      (delete(todosTable)..where((t) => t.id.equals(id))).go();

  /// Pending todos for today (includes overdue and undated).
  Future<List<Todo>> fetchTodayPendingTodos() async {
    final today = DateTime.now().dateOnly;
    final all = await fetchPendingTodos();

    return all.where((todo) {
      if (todo.dueDate == null) return true;
      final due = todo.dueDate!.dateOnly;
      return !due.isAfter(today);
    }).toList();
  }

  /// Completed todos finished today.
  Future<List<Todo>> fetchCompletedTodayTodos() {
    final today = DateTime.now().dateOnly;
    final tomorrow = today.add(const Duration(days: 1));

    return (select(todosTable)
          ..where(
            (t) =>
                t.isCompleted.equals(true) &
                t.completedAt.isBiggerOrEqualValue(today) &
                t.completedAt.isSmallerThanValue(tomorrow),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Stream<List<Todo>> watchCompletedTodayTodos() {
    final today = DateTime.now().dateOnly;
    final tomorrow = today.add(const Duration(days: 1));

    return (select(todosTable)
          ..where(
            (t) =>
                t.isCompleted.equals(true) &
                t.completedAt.isBiggerOrEqualValue(today) &
                t.completedAt.isSmallerThanValue(tomorrow),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  /// Clears completed todos finished today (after celebration).
  Future<int> clearCompletedToday() {
    final today = DateTime.now().dateOnly;
    final tomorrow = today.add(const Duration(days: 1));

    return (delete(todosTable)
          ..where(
            (t) =>
                t.isCompleted.equals(true) &
                t.completedAt.isBiggerOrEqualValue(today) &
                t.completedAt.isSmallerThanValue(tomorrow),
          ))
        .go();
  }

  /// Pending first, then completed — for widget notepad list.
  Future<List<Todo>> fetchTodayWidgetTodos() async {
    final pending = await fetchTodayPendingTodos();
    final completed = await fetchCompletedTodayTodos();
    return [...pending, ...completed];
  }
}
