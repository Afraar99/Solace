/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/providers/system/permissions_provider.dart';
import 'package:mindful/ui/common/styled_text.dart';

/// Shown before opening Accessibility settings on sideloaded (APK) installs.
void requestAccessibilityPermissionWithGuide(
  BuildContext context,
  WidgetRef ref,
) {
  final sdk = MethodChannelService.instance.deviceInfo.sdkVersion;

  void openAccessibilitySettings() {
    ref.read(permissionProvider.notifier).askAccessibilityPermission();
  }

  if (sdk >= 33) {
    showAccessibilitySideloadGuide(
      context,
      onContinueToAccessibility: openAccessibilitySettings,
    );
  } else {
    openAccessibilitySettings();
  }
}

Future<void> showAccessibilitySideloadGuide(
  BuildContext context, {
  required VoidCallback onContinueToAccessibility,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              FluentIcons.shield_lock_20_filled,
              size: 28,
              color: Theme.of(sheetContext).colorScheme.primary,
            ),
            10.vBox,
            StyledText(
              context.locale.accessibility_sideload_dialog_title,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            10.vBox,
            StyledText(
              context.locale.accessibility_sideload_dialog_info,
              fontSize: 14,
              height: 1.45,
              isSubtitle: true,
            ),
            20.vBox,
            OutlinedButton.icon(
              onPressed: () {
                MethodChannelService.instance.openSelfAppInfoSettings();
              },
              icon: const Icon(FluentIcons.settings_20_regular),
              label: Text(context.locale.accessibility_sideload_button_app_info),
            ),
            8.vBox,
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onContinueToAccessibility();
              },
              child: Text(context.locale.accessibility_sideload_button_continue),
            ),
            8.vBox,
          ],
        ),
      );
    },
  );
}
