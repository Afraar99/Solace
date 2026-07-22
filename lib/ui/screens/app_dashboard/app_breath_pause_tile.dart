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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/models/app_info.dart';
import 'package:mindful/providers/restrictions/breath_pause_apps_provider.dart';
import 'package:mindful/providers/system/permissions_provider.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/permissions/permission_sheet.dart';

/// Per-app toggle for the One Sec–style breathing pause on launch.
class AppBreathPauseTile extends ConsumerWidget {
  const AppBreathPauseTile({
    required this.appInfo,
    super.key,
  });

  final AppInfo appInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haveOverlayPermission = ref.watch(
      permissionProvider.select((v) => v.haveDisplayOverlayPermission),
    );
    final isEnabled = ref.watch(
      breathPauseAppsProvider.select(
        (apps) => apps.contains(appInfo.packageName),
      ),
    );

    void onPressed() {
      if (!haveOverlayPermission) {
        _showOverlayPermissionSheet(context, ref);
        return;
      }
      ref.read(breathPauseAppsProvider.notifier).setEnabled(
            appInfo.packageName,
            !isEnabled,
          );
    }

    return DefaultListTile(
      enabled: !appInfo.isImpSysApp,
      position: ItemPosition.mid,
      switchValue: isEnabled,
      titleText: context.locale.breath_pause_tile_title,
      subtitleText: context.locale.breath_pause_tile_subtitle,
      leadingIcon: FluentIcons.leaf_three_20_regular,
      isSelected: haveOverlayPermission,
      onPressed: onPressed,
    );
  }

  void _showOverlayPermissionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PermissionSheet(
        icon: FluentIcons.app_recent_20_filled,
        title: context.locale.permission_overlay_title,
        description: context.locale.permission_overlay_info,
        deviceSwitchTileLabel:
            context.locale.permission_overlay_device_tile_label,
        onTapGrantPermission: () {
          Navigator.of(sheetContext).maybePop();
          ref.read(permissionProvider.notifier).askDisplayOverlayPermission();
        },
      ),
    );
  }
}
