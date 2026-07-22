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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/config/navigation/app_routes.dart';
import 'package:mindful/core/enums/default_home_tab.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_list.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/providers/usage/todays_apps_usage_provider.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/default_expandable_list_tile.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/sliver_active_session_alert.dart';
import 'package:mindful/ui/common/default_refresh_indicator.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/controllers/tab_controller_provider.dart';
import 'package:mindful/ui/screens/home/dashboard/dashboard_glass_panel.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards/focus_daily_glance.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards/screen_time_glance.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards_grid.dart';
import 'package:mindful/ui/transitions/default_effects.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TabDashboard extends ConsumerWidget {
  const TabDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsageLoading =
        ref.watch(todaysAppsUsageProvider.select((v) => v.isLoading));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultRefreshIndicator(
      onRefresh: () async => ref
          .read(todaysAppsUsageProvider.notifier)
          .refreshTodaysUsage(resetState: true),
      child: Stack(
        children: [
          /// Soft ambient wash so glass panels can catch light
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                      scheme.surface.withValues(alpha: 0),
                      scheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverActiveSessionAlert(),
              MultiSliver(
                children: [
                  8.vBox,

                  /// Today overview — glass hero
                  DashboardGlassPanel(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    child: Skeletonizer.zone(
                      enabled: isUsageLoading,
                      enableSwitchAnimation: true,
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            const Expanded(child: ScreenTimeGlance()),
                            8.hBox,
                            const Expanded(child: FocusDailyGlance()),
                          ],
                        ),
                      ),
                    ),
                  ),

                  10.vBox,

                  /// More glance metrics
                  DashboardGlassPanel(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(20),
                    child: DefaultExpandableListTile(
                      position: ItemPosition.none,
                      titleText: context.locale.glance_tile_title,
                      subtitleText: context.locale.glance_tile_subtitle,
                      color: Colors.transparent,
                      content: Skeletonizer.zone(
                        enabled: isUsageLoading,
                        enableSwitchAnimation: true,
                        child: const GlanceCardsGrid(),
                      ),
                    ),
                  ),

                  10.vBox,

                  /// Parental controls
                  DashboardGlassPanel(
                    borderRadius: BorderRadius.circular(20),
                    child: DefaultListTile(
                      position: ItemPosition.none,
                      margin: EdgeInsets.zero,
                      leadingIcon: FluentIcons.shield_keyhole_20_regular,
                      titleText: context.locale.parental_controls_tab_title,
                      subtitleText:
                          context.locale.parental_controls_tile_subtitle,
                      color: Colors.transparent,
                      trailing:
                          const Icon(FluentIcons.chevron_right_20_regular),
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.parentalControlsPath),
                    ),
                  ),

                  /// Digital wellbeing / blocking
                  ..._restrictions(context),
                ].animateListOnce(
                  ref: ref,
                  uniqueKey: "home.dashboard",
                  delay: 100.ms,
                  effects: DefaultEffects.transitionIn,
                  interval: 80.ms,
                ),
              ),
              const SliverTabsBottomPadding(),
            ],
          ),
        ],
      ),
    );
  }

  static List<Widget> _restrictions(BuildContext context) => [
        ContentSectionHeader(
          title: context.locale.restrictions_heading,
        ),
        DashboardGlassPanel(
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              DefaultListTile(
                position: ItemPosition.top,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.app_title_20_regular,
                titleText: context.locale.apps_blocking_tile_title,
                subtitleText: context.locale.apps_blocking_tile_subtitle,
                color: Colors.transparent,
                onPressed: () =>
                    TabControllerProvider.maybeOf(context)?.animateToTab(
                  DefaultHomeTab.statistics.index,
                ),
              ),
              _glassDivider(context),
              DefaultListTile(
                position: ItemPosition.mid,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.app_recent_20_regular,
                titleText: context.locale.grouped_apps_blocking_tile_title,
                subtitleText:
                    context.locale.grouped_apps_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.restrictionGroupsPath),
              ),
              _glassDivider(context),
              DefaultListTile(
                position: ItemPosition.mid,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.resize_video_20_regular,
                titleText: context.locale.shorts_blocking_tab_title,
                subtitleText: context.locale.shorts_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.shortsBlockingPath),
              ),
              _glassDivider(context),
              DefaultListTile(
                position: ItemPosition.bottom,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.earth_20_regular,
                titleText: context.locale.websites_blocking_tab_title,
                subtitleText: context.locale.websites_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.websitesBlockingPath),
              ),
            ],
          ),
        ),
      ];

  static Widget _glassDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
          height: 1,
          thickness: 0.6,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.08),
        ),
      );
}
