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
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/enums/todo_priority.dart';
import 'package:mindful/core/utils/todo_utils.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/ui/common/default_slide_to_remove.dart';
import 'package:mindful/ui/common/styled_text.dart';

class TodoListTile extends StatefulWidget {
  const TodoListTile({
    super.key,
    required this.todo,
    required this.position,
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
    this.showOverdueStyle = false,
    this.isCompleted = false,
  });

  final Todo todo;
  final ItemPosition position;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showOverdueStyle;
  final bool isCompleted;

  @override
  State<TodoListTile> createState() => _TodoListTileState();
}

class _TodoListTileState extends State<TodoListTile> {
  bool _isCompleting = false;

  Future<void> _handleComplete() async {
    if (_isCompleting || widget.isCompleted) return;

    setState(() => _isCompleting = true);
    HapticFeedback.lightImpact();

    if (widget.todo.priority == TodoPriority.high) {
      Confetti.launch(
        context,
        options: const ConfettiOptions(
          particleCount: 40,
          spread: 60,
          y: 0.7,
        ),
      );
    }

    await Future.delayed(450.ms);
    if (!mounted) return;

    // Move to Done section (stay in list, crossed) — no full remove
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = widget.isCompleted || _isCompleting;
    final dueColor = widget.showOverdueStyle
        ? scheme.error
        : scheme.onSurfaceVariant;

    return DefaultSlideToRemove(
      key: ValueKey('${widget.todo.id}_${widget.isCompleted}'),
      position: widget.position,
      onDismiss: widget.onDelete,
      child: Material(
        color: done
            ? scheme.errorContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainer,
        borderRadius: getBorderRadiusFromPosition(widget.position),
        child: InkWell(
          onTap: widget.isCompleted ? null : widget.onEdit,
          borderRadius: getBorderRadiusFromPosition(widget.position),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isCompleted)
                  Icon(
                    FluentIcons.checkmark_circle_20_filled,
                    color: scheme.error,
                    size: 28,
                  )
                else
                  _CompleteButton(
                    isCompleting: _isCompleting,
                    onPressed: _handleComplete,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: AppConstants.defaultAnimDuration,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: scheme.error,
                                  color: done
                                      ? scheme.onErrorContainer
                                      : null,
                                ),
                        child: Text(widget.todo.title),
                      ),
                      if (!widget.isCompleted) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _PriorityChip(priority: widget.todo.priority),
                            const SizedBox(width: 8),
                            Flexible(
                              child: StyledText(
                                TodoUtils.dueLabel(widget.todo),
                                fontSize: 12,
                                color: dueColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.isCompleted)
                  const Icon(
                    FluentIcons.chevron_right_20_regular,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.isCompleting,
    required this.onPressed,
  });

  final bool isCompleting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: AppConstants.defaultAnimDuration,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleting ? scheme.error : scheme.outline,
                width: 2,
              ),
              color: isCompleting ? scheme.error.withValues(alpha: 0.12) : null,
            ),
            child: Center(
              child: isCompleting
                  ? Icon(
                      FluentIcons.dismiss_20_filled,
                      size: 16,
                      color: scheme.error,
                    )
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: AppConstants.defaultAnimDuration,
                        curve: Curves.easeOutBack,
                      )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = priority.chipColor(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: StyledText(
        priority.label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
