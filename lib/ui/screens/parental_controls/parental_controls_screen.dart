/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/core/services/auth_service.dart';
import 'package:mindful/providers/system/kids_mode_provider.dart';
import 'package:mindful/providers/system/parental_controls_provider.dart';
import 'package:mindful/providers/system/permissions_provider.dart';
import 'package:mindful/ui/permissions/accessibility_sideload_dialog.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/scaffold_shell.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/screens/parental_controls/invincible_mode_settings.dart';

class ParentalControlsScreen extends ConsumerWidget {
  const ParentalControlsScreen({super.key});

  Future<void> _toggleKidsMode(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled,
  ) async {
    if (!isEnabled) {
      if (!ref.read(permissionProvider).haveAccessibilityPermission) {
        requestAccessibilityPermissionWithGuide(context, ref);
        context.showSnackAlert(
          context.locale.permission_accessibility_info,
          icon: FluentIcons.accessibility_20_filled,
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(FluentIcons.people_community_20_regular),
          title: Text(context.locale.kids_mode_enable_dialog_title),
          content: Text(context.locale.kids_mode_enable_dialog_info),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.locale.kids_mode_enable_button),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final authenticated = await AuthService.instance.authenticate(
      reason: isEnabled
          ? 'Confirm fingerprint or PIN to turn off Kids Mode'
          : 'Confirm fingerprint or PIN to protect Kids Mode',
    );
    if (!context.mounted) return;

    if (authenticated == null) {
      context.showSnackAlert(
        context.locale.protected_access_no_lock_snack_alert,
        icon: FluentIcons.lock_closed_20_filled,
      );
      return;
    }
    if (!authenticated) {
      context.showSnackAlert(
        context.locale.protected_access_failed_lock_snack_alert,
        icon: FluentIcons.lock_closed_20_filled,
      );
      return;
    }

    final saved =
        await ref.read(kidsModeProvider.notifier).setEnabled(!isEnabled);
    if (!context.mounted || !saved) return;

    context.showSnackAlert(
      isEnabled
          ? context.locale.kids_mode_disabled_snack_alert
          : context.locale.kids_mode_enabled_snack_alert,
      icon: FluentIcons.people_community_20_filled,
    );
  }

  void _toggleProtectedAccess(
    BuildContext context,
    WidgetRef ref,
    bool isAccessProtected,
  ) async {
    try {
      if (!isAccessProtected) {
        final isAuthenticated = await AuthService.instance.authenticate(
          reason: 'Confirm fingerprint or PIN to protect Solace',
        );

        if (!context.mounted) return;

        if (isAuthenticated == null) {
          context.showSnackAlert(
            context.locale.protected_access_no_lock_snack_alert,
            icon: FluentIcons.fingerprint_20_filled,
          );
          return;
        }

        if (!isAuthenticated) {
          context.showSnackAlert(
            context.locale.protected_access_failed_lock_snack_alert,
            icon: FluentIcons.fingerprint_20_filled,
          );
          return;
        }
      }

      ref.read(parentalControlsProvider.notifier).switchProtectedAccess();
    } catch (e) {
      debugPrint('Failed to authenticate: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentalControls = ref.watch(parentalControlsProvider);
    final kidsModeState = ref.watch(kidsModeProvider);
    final kidsModeEnabled = kidsModeState.value ?? false;

    return ScaffoldShell(
      items: [
        NavbarItem(
          icon: FluentIcons.shield_keyhole_20_regular,
          filledIcon: FluentIcons.shield_keyhole_20_filled,
          titleText: context.locale.parental_controls_tab_title,
          sliverBody: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ContentSectionHeader(
                title: context.locale.kids_mode_heading,
              ).sliver,

              DefaultListTile(
                position: ItemPosition.none,
                switchValue: kidsModeEnabled,
                enabled: !kidsModeState.isLoading,
                leadingIcon: FluentIcons.people_community_20_regular,
                titleText: context.locale.kids_mode_tile_title,
                subtitleText: context.locale.kids_mode_tile_subtitle,
                onPressed: () => _toggleKidsMode(
                  context,
                  ref,
                  kidsModeEnabled,
                ),
              ).sliver,

              12.vSliverBox,
              StyledText(
                context.locale.kids_mode_info,
                fontSize: 13,
                height: 1.4,
                isSubtitle: true,
              ).sliver,

              const InvincibleModeSettings(),

              ContentSectionHeader(
                title: context.locale.parental_controls_tab_title,
              ).sliver,

              /// Protected access — fingerprint or device PIN
              DefaultListTile(
                position: ItemPosition.none,
                switchValue: parentalControls.protectedAccess,
                leadingIcon: FluentIcons.fingerprint_20_regular,
                titleText: context.locale.protected_access_tile_title,
                subtitleText: context.locale.protected_access_tile_subtitle,
                onPressed: () => _toggleProtectedAccess(
                  context,
                  ref,
                  parentalControls.protectedAccess,
                ),
              ).sliver,

              12.vSliverBox,
              StyledText(
                'When enabled, opening Solace asks for your fingerprint or device PIN — whichever you use on this phone. You only need one.',
                fontSize: 13,
                isSubtitle: true,
              ).sliver,

              const SliverTabsBottomPadding(),
            ],
          ),
        )
      ],
    );
  }
}
