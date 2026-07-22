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
import 'package:mindful/core/utils/todo_utils.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/providers/todos/todos_provider.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/screens/tasks/widgets/empty_todos_state.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_editor_sheet.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_list_tile.dart';

class TabUpcomingTodos extends ConsumerWidget {
  const TabUpcomingTodos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(pendingTodosProvider);

    return todosAsync.when(
      loading: () => const CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, _) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(child: Center(child: Text(error.toString()))),
        ],
      ),
      data: (todos) {
        final upcoming = TodoUtils.filterUpcoming(todos);

        if (upcoming.isEmpty) {
          return const CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: EmptyTodosState(
                  message:
                      'No upcoming tasks.\nSchedule something for later.',
                ),
              ),
              SliverTabsBottomPadding(),
            ],
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TodoListTile(
                  todo: upcoming[index],
                  position: getItemPositionInList(index, upcoming.length),
                  onComplete: () => ref
                      .read(todosNotifierProvider)
                      .completeTodo(upcoming[index].id),
                  onDelete: () => ref
                      .read(todosNotifierProvider)
                      .deleteTodo(upcoming[index].id),
                  onEdit: () => _openEditor(context, ref, todo: upcoming[index]),
                ),
                childCount: upcoming.length,
              ),
            ),
            const SliverTabsBottomPadding(),
          ],
        );
      },
    );
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
