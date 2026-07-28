/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/permissions/alarm_permission_tile.dart';
import 'package:mindful/ui/permissions/battery_permission_tile.dart';
import 'package:mindful/ui/permissions/display_overlay_permission_tile.dart';
import 'package:mindful/ui/permissions/notification_permission_tile.dart';
import 'package:mindful/ui/permissions/usage_access_permission_tile.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sdkVersion = MethodChannelService.instance.deviceInfo.sdkVersion;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Image.asset(
                'assets/illustrations/onboarding_4.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          12.vBox,
          StyledText(
            context.locale.onboarding_page_permissions_title,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
          8.vBox,
          StyledText(
            context.locale.onboarding_page_permissions_info,
            fontSize: 15,
            height: 1.4,
            color: Theme.of(context).hintColor,
          ),
          20.vBox,

          /// Permission tiles — tap each one to open the enable screen
          const NotificationPermissionTile(),
          const BatteryPermissionTile(),
          if (sdkVersion >= 31) const AlarmPermissionTile(),
          const UsageAccessPermissionTile(),
          // Overlay is optional — only needed if you use app-limit popup overlays
          const DisplayOverlayPermissionTile(),

          24.vBox,
        ],
      ),
    );
  }
}
