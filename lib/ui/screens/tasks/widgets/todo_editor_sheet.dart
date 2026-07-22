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
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/enums/todo_priority.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/ui/common/styled_text.dart';

class TodoEditorSheet extends StatefulWidget {
  const TodoEditorSheet({
    super.key,
    this.todo,
  });

  final Todo? todo;

  static Future<TodoEditorResult?> show(
    BuildContext context, {
    Todo? todo,
  }) {
    return showModalBottomSheet<TodoEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TodoEditorSheet(todo: todo),
      ),
    );
  }

  @override
  State<TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class TodoEditorResult {
  const TodoEditorResult({
    required this.title,
    this.dueDate,
    this.dueTimeMinutes,
    this.remindMe = false,
    this.priority = TodoPriority.medium,
  });

  final String title;
  final DateTime? dueDate;
  final int? dueTimeMinutes;
  final bool remindMe;
  final TodoPriority priority;
}

class _TodoEditorSheetState extends State<TodoEditorSheet> {
  late final TextEditingController _titleController;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _remindMe = false;
  TodoPriority _priority = TodoPriority.medium;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _dueDate = todo?.dueDate?.dateOnly;
    if (todo?.dueTimeMinutes != null) {
      _dueTime = TimeOfDay(
        hour: todo!.dueTimeMinutes! ~/ 60,
        minute: todo.dueTimeMinutes! % 60,
      );
    }
    _remindMe = todo?.reminderAt != null;
    _priority = todo?.priority ?? TodoPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked.dateOnly);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Navigator.of(context).pop(
      TodoEditorResult(
        title: title,
        dueDate: _dueDate,
        dueTimeMinutes: _dueTime == null
            ? null
            : (_dueTime!.hour * 60) + _dueTime!.minute,
        remindMe: _remindMe,
        priority: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StyledText(
                  _isEditing ? 'Edit task' : 'New task',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(FluentIcons.dismiss_20_regular),
              ),
            ],
          ),
          12.vBox,
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'What do you need to do?',
            ),
            onSubmitted: (_) => _save(),
          ),
          16.vBox,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(FluentIcons.calendar_20_regular, size: 18),
                label: Text(
                  _dueDate == null
                      ? 'Add date'
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(_dueDate!),
                ),
                onPressed: _pickDate,
              ),
              if (_dueDate != null)
                ActionChip(
                  avatar: const Icon(FluentIcons.clock_20_regular, size: 18),
                  label: Text(
                    _dueTime == null
                        ? 'Add time'
                        : _dueTime!.format(context),
                  ),
                  onPressed: _pickTime,
                ),
              if (_dueDate != null)
                ActionChip(
                  label: const Text('Clear date'),
                  onPressed: () => setState(() {
                    _dueDate = null;
                    _dueTime = null;
                  }),
                ),
            ],
          ),
          12.vBox,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind me'),
            subtitle: Text(
              _dueDate == null
                  ? 'Set a due date to enable reminders'
                  : 'Notification at due time',
            ),
            value: _remindMe && _dueDate != null,
            onChanged: _dueDate == null
                ? null
                : (value) => setState(() => _remindMe = value),
          ),
          8.vBox,
          StyledText(
            'Priority',
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
          8.vBox,
          SegmentedButton<TodoPriority>(
            segments: TodoPriority.values
                .map(
                  (priority) => ButtonSegment(
                    value: priority,
                    label: Text(priority.label),
                  ),
                )
                .toList(),
            selected: {_priority},
            onSelectionChanged: (values) =>
                setState(() => _priority = values.first),
          ),
          20.vBox,
          FilledButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Save changes' : 'Add task'),
          ),
        ],
      ),
    );
  }
}
