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
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Icon(
          FluentIcons.person_circle_24_regular,
          size: 72,
          color: scheme.primary,
        ),
        24.vBox,
        StyledText(
          'What should we call you?',
          fontSize: 28,
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
        32.vBox,
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofocus: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Your name',
            hintText: AppConstants.defaultUsername,
            prefixIcon: const Icon(FluentIcons.person_20_regular),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}
