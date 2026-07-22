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
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/screens/tasks/widgets/todo_editor_sheet.dart';

class EmptyTodosState extends StatelessWidget {
  const EmptyTodosState({
    super.key,
    required this.message,
    this.onAddPressed,
  });

  final String message;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.reading_list_20_regular,
            size: 56,
            color: scheme.primary.withValues(alpha: 0.7),
          ),
          16.vBox,
          StyledText(
            message,
            textAlign: TextAlign.center,
            color: scheme.onSurfaceVariant,
          ),
          if (onAddPressed != null) ...[
            20.vBox,
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(FluentIcons.add_20_filled),
              label: const Text('Add a task'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> openTodoEditor(
  BuildContext context, {
  required Future<void> Function(TodoEditorResult result) onSubmit,
}) async {
  final result = await TodoEditorSheet.show(context);
  if (result != null) {
    await onSubmit(result);
  }
}
