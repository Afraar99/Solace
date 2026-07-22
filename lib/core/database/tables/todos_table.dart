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
import 'package:mindful/core/enums/todo_priority.dart';

@DataClassName("Todo")
class TodosTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Minutes from midnight for optional due time.
  IntColumn get dueTimeMinutes => integer().nullable()();

  DateTimeColumn get reminderAt => dateTime().nullable()();

  IntColumn get priority =>
      intEnum<TodoPriority>().withDefault(const Constant(1))();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
