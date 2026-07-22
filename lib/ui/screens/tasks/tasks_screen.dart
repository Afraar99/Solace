/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/providers/todos/todos_provider.dart';
import 'package:mindful/ui/common/default_fab_button.dart';
import 'package:mindful/ui/common/scaffold_shell.dart';
import 'package:mindful/ui/screens/tasks/tab_today_todos.dart';
import 'package:mindful/ui/screens/tasks/tab_upcoming_todos.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_editor_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({
    super.key,
    this.initialTabIndex,
    this.openEditor = false,
  });

  final int? initialTabIndex;
  final bool openEditor;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openEditor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEditor(context, ref);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldShell(
      initialTab: widget.initialTabIndex,
      items: [
        NavbarItem(
          icon: FluentIcons.calendar_today_20_regular,
          filledIcon: FluentIcons.calendar_today_20_filled,
          titleText: 'Today',
          fab: DefaultFabButton(
            label: 'Add task',
            icon: FluentIcons.add_20_filled,
            onPressed: () => _openEditor(context, ref),
          ),
          sliverBody: const TabTodayTodos(),
        ),
        NavbarItem(
          icon: FluentIcons.calendar_arrow_right_20_regular,
          filledIcon: FluentIcons.calendar_arrow_right_20_filled,
          titleText: 'Upcoming',
          fab: DefaultFabButton(
            heroTag: 'tasksUpcomingFab',
            label: 'Add task',
            icon: FluentIcons.add_20_filled,
            onPressed: () => _openEditor(context, ref),
          ),
          sliverBody: const TabUpcomingTodos(),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final result = await TodoEditorSheet.show(context);
    if (result == null) return;

    await ref.read(todosNotifierProvider).addTodo(
          title: result.title,
          dueDate: result.dueDate,
          dueTimeMinutes: result.dueTimeMinutes,
          remindMe: result.remindMe,
          priority: result.priority,
        );
  }
}
