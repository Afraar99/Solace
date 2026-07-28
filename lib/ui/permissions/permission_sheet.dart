/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/permissions/permission_granting_steps.dart';

class PermissionSheet extends StatelessWidget {
  const PermissionSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTapGrantPermission,
    this.isAccessibilityPerm = false,
    this.deviceSwitchTileLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTapGrantPermission;
  final bool isAccessibilityPerm;
  final String? deviceSwitchTileLabel;

  @override
  Widget build(BuildContext context) {
    final positiveButtonLabel = isAccessibilityPerm
        ? context.locale.permission_button_agree_and_continue
        : context.locale.permission_button_grant_permission;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundedContainer(
              height: 8,
              width: 48,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              color: Theme.of(context).hintColor,
            ).centered,
            Icon(
              icon,
              size: 32,
            ),
            8.vBox,
            StyledText(
              title,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            6.vBox,
            StyledText(
              description,
              fontSize: 13,
            ),
            if (deviceSwitchTileLabel != null) ...[
              12.vBox,
              PermissionGrantingSteps(
                labelOfBtnToClick: positiveButtonLabel,
                deviceSwitchTileLabel: deviceSwitchTileLabel!,
                isAccessibilityPerm: isAccessibilityPerm,
              ),
            ],
            20.vBox,
            StyledText(
              context.locale.permission_sheet_privacy_info,
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.green[900]
                  : Colors.green[300],
            ),
            24.vBox,
            Row(
              children: [
                if (isAccessibilityPerm)
                  TextButton(
                    onPressed: Navigator.of(context).maybePop,
                    child: Text(context.locale.permission_button_not_now),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: onTapGrantPermission,
                  child: Text(positiveButtonLabel),
                ),
              ],
            ),
            16.vBox,
          ],
        ),
      ),
    );
  }
}
