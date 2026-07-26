/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/ui/common/styled_text.dart';

/// Asks for the user's display name after permissions, before home.
class NameSetupPage extends StatelessWidget {
  const NameSetupPage({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          reverse: true,
          padding: EdgeInsets.only(bottom: keyboardInset > 0 ? 16 : 0),
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                24.vBox,
                Icon(
                  FluentIcons.person_circle_24_regular,
                  size: 64,
                  color: scheme.primary,
                ),
                20.vBox,
                StyledText(
                  'What should we call you?',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                  color: scheme.primary,
                ),
                8.vBox,
                StyledText(
                  'This name shows on your dashboard greeting. You can change it later by long-pressing it.',
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                  textAlign: TextAlign.center,
                ),
                28.vBox,
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    onSubmitted?.call();
                  },
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: AppConstants.defaultUsername,
                    prefixIcon: const Icon(FluentIcons.person_20_regular),
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
                24.vBox,
              ],
            ),
          ),
        );
      },
    );
  }
}
