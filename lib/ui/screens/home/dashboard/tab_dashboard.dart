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
import 'package:mindful/ui/common/default_expandable_list_tile.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/sliver_active_session_alert.dart';
import 'package:mindful/ui/common/default_refresh_indicator.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/controllers/tab_controller_provider.dart';
import 'package:mindful/ui/screens/home/dashboard/dashboard_glass_panel.dart';
import 'package:mindful/ui/screens/home/dashboard/dashboard_palette.dart';
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    /// Dashboard-only royal orange preview theme
    final orangeScheme = ColorScheme.fromSeed(
      seedColor: DashboardPalette.seed,
      brightness: brightness,
      surface: isDark ? DashboardPalette.warmInk : DashboardPalette.warmIvory,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: orangeScheme,
        dividerColor: DashboardPalette.royal.withValues(alpha: 0.12),
      ),
      child: Builder(
        builder: (context) {
          return DefaultRefreshIndicator(
            onRefresh: () async => ref
                .read(todaysAppsUsageProvider.notifier)
                .refreshTodaysUsage(resetState: true),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DashboardPalette.ambient(isDark: isDark),
                      ),
                    ),
                  ),
                ),

                /// Soft top glow
                Positioned(
                  top: -80,
                  left: -40,
                  right: -40,
                  height: 260,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 0.9,
                          colors: [
                            DashboardPalette.royal
                                .withValues(alpha: isDark ? 0.28 : 0.22),
                            DashboardPalette.apricot
                                .withValues(alpha: isDark ? 0.08 : 0.10),
                            Colors.transparent,
                          ],
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
                        12.vBox,

                        /// Today — hero glass
                        DashboardGlassPanel(
                          emphasized: true,
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 6, bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            DashboardPalette.apricot,
                                            DashboardPalette.ember,
                                          ],
                                        ),
                                      ),
                                    ),
                                    10.hBox,
                                    StyledText(
                                      context.locale.dashboard_tab_title,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DashboardPalette.royal
                                          .withValues(alpha: isDark ? 0.9 : 1),
                                    ),
                                  ],
                                ),
                              ),
                              Skeletonizer.zone(
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
                            ],
                          ),
                        ),

                        14.vBox,

                        /// Glance metrics
                        DashboardGlassPanel(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(22),
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

                        12.vBox,

                        /// Parental controls
                        DashboardGlassPanel(
                          borderRadius: BorderRadius.circular(22),
                          child: DefaultListTile(
                            position: ItemPosition.none,
                            margin: EdgeInsets.zero,
                            leadingIcon: FluentIcons.shield_keyhole_20_regular,
                            titleText:
                                context.locale.parental_controls_tab_title,
                            subtitleText:
                                context.locale.parental_controls_tile_subtitle,
                            color: Colors.transparent,
                            trailing: Icon(
                              FluentIcons.chevron_right_20_regular,
                              color: DashboardPalette.royal
                                  .withValues(alpha: 0.7),
                            ),
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.parentalControlsPath),
                          ),
                        ),

                        /// Digital wellbeing / blocking
                        ..._restrictions(context, isDark),
                      ].animateListOnce(
                        ref: ref,
                        uniqueKey: "home.dashboard.orange",
                        delay: 80.ms,
                        effects: DefaultEffects.transitionIn,
                        interval: 70.ms,
                      ),
                    ),
                    const SliverTabsBottomPadding(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<Widget> _restrictions(BuildContext context, bool isDark) => [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4),
          child: Row(
            children: [
              StyledText(
                context.locale.restrictions_heading,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DashboardPalette.royal,
              ),
              10.hBox,
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DashboardPalette.royal.withValues(alpha: 0.35),
                        DashboardPalette.royal.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        DashboardGlassPanel(
          borderRadius: BorderRadius.circular(24),
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
              _divider(isDark),
              DefaultListTile(
                position: ItemPosition.mid,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.app_recent_20_regular,
                titleText: context.locale.grouped_apps_blocking_tile_title,
                subtitleText:
                    context.locale.grouped_apps_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: Icon(
                  FluentIcons.chevron_right_20_regular,
                  color: DashboardPalette.royal.withValues(alpha: 0.65),
                ),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.restrictionGroupsPath),
              ),
              _divider(isDark),
              DefaultListTile(
                position: ItemPosition.mid,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.resize_video_20_regular,
                titleText: context.locale.shorts_blocking_tab_title,
                subtitleText: context.locale.shorts_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: Icon(
                  FluentIcons.chevron_right_20_regular,
                  color: DashboardPalette.royal.withValues(alpha: 0.65),
                ),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.shortsBlockingPath),
              ),
              _divider(isDark),
              DefaultListTile(
                position: ItemPosition.bottom,
                margin: EdgeInsets.zero,
                leadingIcon: FluentIcons.earth_20_regular,
                titleText: context.locale.websites_blocking_tab_title,
                subtitleText: context.locale.websites_blocking_tile_subtitle,
                color: Colors.transparent,
                trailing: Icon(
                  FluentIcons.chevron_right_20_regular,
                  color: DashboardPalette.royal.withValues(alpha: 0.65),
                ),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.websitesBlockingPath),
              ),
            ],
          ),
        ),
      ];

  static Widget _divider(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Divider(
          height: 1,
          thickness: 0.7,
          color: DashboardPalette.royal.withValues(alpha: isDark ? 0.14 : 0.10),
        ),
      );
}
