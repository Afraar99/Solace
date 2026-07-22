/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/core/utils/todo_utils.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/providers/todos/todos_provider.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/screens/tasks/widgets/empty_todos_state.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_editor_sheet.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_list_tile.dart';

class TabTodayTodos extends ConsumerWidget {
  const TabTodayTodos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTodosProvider);
    final completedAsync = ref.watch(completedTodayTodosProvider);

    if (pendingAsync.isLoading && !pendingAsync.hasValue) {
      return const CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (pendingAsync.hasError) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: Text(pendingAsync.error.toString())),
          ),
        ],
      );
    }

    final todos = pendingAsync.value ?? const <Todo>[];
    final completed = completedAsync.value ?? const <Todo>[];
    final grouped = TodoUtils.groupForTodayTab(todos);
    final sections = [
      (TodoListSection.overdue, 'Overdue', true),
      (TodoListSection.dueToday, 'Due today', false),
      (TodoListSection.noDate, 'No date', false),
    ];

    final pendingCount = sections
        .map((section) => grouped[section.$1]?.length ?? 0)
        .fold<int>(0, (sum, count) => sum + count);

    if (pendingCount == 0 && completed.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          EmptyTodosState(
            message: 'Nothing for today yet.\nAdd a task or set a due date.',
            onAddPressed: () => _openEditor(context, ref),
          ).sliver,
          const SliverTabsBottomPadding(),
        ],
      );
    }

    final children = <Widget>[];
    for (final (section, title, overdueStyle) in sections) {
      children.addAll(
        _buildSection(
          context,
          ref,
          title: title,
          todos: grouped[section] ?? const [],
          showOverdueStyle: overdueStyle,
        ),
      );
    }

    // Done items stay in the list but move to the bottom (crossed)
    if (completed.isNotEmpty) {
      children.add(const ContentSectionHeader(title: 'Done'));
      for (var i = 0; i < completed.length; i++) {
        children.add(
          TodoListTile(
            todo: completed[i],
            position: getItemPositionInList(i, completed.length),
            isCompleted: true,
            onComplete: () {},
            onDelete: () =>
                ref.read(todosNotifierProvider).deleteTodo(completed[i].id),
            onEdit: () {},
          ),
        );
      }
      children.add(8.vBox);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(delegate: SliverChildListDelegate(children)),
        const SliverTabsBottomPadding(),
      ],
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<Todo> todos,
    required bool showOverdueStyle,
  }) {
    if (todos.isEmpty) return [];

    return [
      ContentSectionHeader(title: title),
      for (var i = 0; i < todos.length; i++)
        TodoListTile(
          todo: todos[i],
          position: getItemPositionInList(i, todos.length),
          showOverdueStyle: showOverdueStyle,
          onComplete: () =>
              ref.read(todosNotifierProvider).completeTodo(todos[i].id),
          onDelete: () =>
              ref.read(todosNotifierProvider).deleteTodo(todos[i].id),
          onEdit: () => _openEditor(context, ref, todo: todos[i]),
        ),
      8.vBox,
    ];
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Todo? todo,
  }) async {
    final result = await TodoEditorSheet.show(context, todo: todo);
    if (result == null) return;

    final notifier = ref.read(todosNotifierProvider);
    if (todo == null) {
      await notifier.addTodo(
        title: result.title,
        dueDate: result.dueDate,
        dueTimeMinutes: result.dueTimeMinutes,
        remindMe: result.remindMe,
        priority: result.priority,
      );
    } else {
      await notifier.updateTodo(
        todo: todo,
        title: result.title,
        dueDate: result.dueDate,
        dueTimeMinutes: result.dueTimeMinutes,
        remindMe: result.remindMe,
        priority: result.priority,
      );
    }
  }
}
