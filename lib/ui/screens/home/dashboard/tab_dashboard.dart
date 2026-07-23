/*
 *
 *  * Copyright (c) 2024 Solace
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
import 'package:mindful/providers/restrictions/wellbeing_provider.dart';
import 'package:mindful/providers/shield/shield_days_provider.dart';
import 'package:mindful/providers/usage/todays_apps_usage_provider.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/default_expandable_list_tile.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/sliver_active_session_alert.dart';
import 'package:mindful/ui/common/default_refresh_indicator.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/controllers/tab_controller_provider.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards/focus_daily_glance.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards/screen_time_glance.dart';
import 'package:mindful/ui/screens/home/dashboard/glance_cards_grid.dart';
import 'package:mindful/ui/screens/home/dashboard/shield_contribution_card.dart';
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

    /// Keep shield graph in sync when NSFW toggles
    ref.listen(wellBeingProvider.select((v) => v.blockNsfwSites), (_, __) {
      ref.read(shieldDaysProvider.notifier).checkInToday();
    });

    return DefaultRefreshIndicator(
      onRefresh: () async {
        await ref
            .read(todaysAppsUsageProvider.notifier)
            .refreshTodaysUsage(resetState: true);
        await ref.read(shieldDaysProvider.notifier).checkInToday();
      },
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverActiveSessionAlert(),
            MultiSliver(
              children: [
                8.vBox,

                /// Shield contribution graph
                const ShieldContributionCard(),

                12.vBox,

                /// Today metrics
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
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

                12.vBox,

                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
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

                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: DefaultListTile(
                    position: ItemPosition.none,
                    margin: EdgeInsets.zero,
                    leadingIcon: FluentIcons.shield_keyhole_20_regular,
                    titleText: context.locale.parental_controls_tab_title,
                    subtitleText:
                        context.locale.parental_controls_tile_subtitle,
                    color: Colors.transparent,
                    trailing: Icon(
                      FluentIcons.chevron_right_20_regular,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.parentalControlsPath),
                  ),
                ),

                ..._restrictions(context),
              ].animateListOnce(
                ref: ref,
                uniqueKey: "home.dashboard.solace.v2",
                delay: 50.ms,
                effects: DefaultEffects.transitionIn,
                interval: 45.ms,
              ),
            ),
            const SliverTabsBottomPadding(),
          ],
        ),
      ),
    );
  }

  static List<Widget> _restrictions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      ContentSectionHeader(
        title: context.locale.restrictions_heading,
        padding: const EdgeInsets.only(top: 20, bottom: 10),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        ),
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
            _divider(context),
            DefaultListTile(
              position: ItemPosition.mid,
              margin: EdgeInsets.zero,
              leadingIcon: FluentIcons.app_recent_20_regular,
              titleText: context.locale.grouped_apps_blocking_tile_title,
              subtitleText: context.locale.grouped_apps_blocking_tile_subtitle,
              color: Colors.transparent,
              trailing: Icon(
                FluentIcons.chevron_right_20_regular,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.restrictionGroupsPath),
            ),
            _divider(context),
            DefaultListTile(
              position: ItemPosition.mid,
              margin: EdgeInsets.zero,
              leadingIcon: FluentIcons.resize_video_20_regular,
              titleText: context.locale.shorts_blocking_tab_title,
              subtitleText: context.locale.shorts_blocking_tile_subtitle,
              color: Colors.transparent,
              trailing: Icon(
                FluentIcons.chevron_right_20_regular,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.shortsBlockingPath),
            ),
            _divider(context),
            DefaultListTile(
              position: ItemPosition.bottom,
              margin: EdgeInsets.zero,
              leadingIcon: FluentIcons.earth_20_regular,
              titleText: context.locale.websites_blocking_tab_title,
              subtitleText: context.locale.websites_blocking_tile_subtitle,
              color: Colors.transparent,
              trailing: Icon(
                FluentIcons.chevron_right_20_regular,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.websitesBlockingPath),
            ),
          ],
        ),
      ),
    ];
  }

  static Widget _divider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
          height: 1,
          thickness: 0.6,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      );
}
