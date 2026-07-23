/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/config/app_themes.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/shield_days_store.dart';
import 'package:mindful/providers/restrictions/wellbeing_provider.dart';
import 'package:mindful/providers/shield/shield_days_provider.dart';
import 'package:mindful/ui/common/styled_text.dart';

/// GitHub-style contribution graph for Solace shield days (app presence + NSFW).
class ShieldContributionCard extends ConsumerWidget {
  const ShieldContributionCard({super.key});

  static const int _weeks = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(shieldDaysProvider);
    final nsfwOn = ref.watch(wellBeingProvider.select((v) => v.blockNsfwSites));
    final streak = ref.read(shieldDaysProvider.notifier).nsfwStreak();
    final appDays = ref.read(shieldDaysProvider.notifier).appDaysCount();
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    /// Align so columns are weeks starting Monday
    final weekday = todayOnly.weekday; // 1=Mon ... 7=Sun
    final endOfWeek = todayOnly.add(Duration(days: 7 - weekday));
    final start =
        endOfWeek.subtract(Duration(days: (_weeks * 7) - 1));

    final monthLabels = <int, String>{};
    for (var w = 0; w < _weeks; w++) {
      final colStart = start.add(Duration(days: w * 7));
      if (colStart.day <= 7 || w == 0) {
        monthLabels[w] = _monthShort(colStart.month);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StyledText(
                  nsfwOn ? 'NSFW shield' : 'Daily presence',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: nsfwOn
                      ? AppTheme.solaceBurgundy.withValues(alpha: 0.25)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StyledText(
                  nsfwOn ? 'Active' : 'NSFW off',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: nsfwOn
                      ? AppTheme.solaceBurgundyLight
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          10.vBox,

          /// Month labels
          Row(
            children: List.generate(_weeks, (w) {
              final label = monthLabels[w];
              return Expanded(
                child: StyledText(
                  label ?? '',
                  fontSize: 9,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              );
            }),
          ),
          4.vBox,

          /// Heatmap: 7 rows (Mon–Sun), _weeks columns
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 3.0;
              final cell =
                  ((constraints.maxWidth - gap * (_weeks - 1)) / _weeks)
                      .clamp(8.0, 14.0);
              return Column(
                children: List.generate(7, (row) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: row == 6 ? 0 : gap),
                    child: Row(
                      children: List.generate(_weeks, (col) {
                        final day = start.add(Duration(days: col * 7 + row));
                        final isFuture = day.isAfter(todayOnly);
                        final key = ShieldDaysStore.dateKey(day);
                        final entry = days[key];
                        final hasNsfw = entry?['nsfw'] == true;
                        final hasApp = entry?['app'] == true;
                        final isToday = day == todayOnly;

                        Color fill;
                        if (isFuture) {
                          fill = scheme.surfaceContainerHighest
                              .withValues(alpha: 0.25);
                        } else if (hasNsfw) {
                          fill = AppTheme.solaceBurgundy;
                        } else if (hasApp) {
                          fill = AppTheme.solaceBurgundy.withValues(alpha: 0.35);
                        } else {
                          fill = scheme.surfaceContainerHighest
                              .withValues(alpha: 0.45);
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                              right: col == _weeks - 1 ? 0 : gap),
                          child: Container(
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(3),
                              border: isToday
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),

          12.vBox,
          StyledText(
            nsfwOn
                ? 'Streak: $streak days · App days: $appDays'
                : 'App days: $appDays · Turn on NSFW filter to grow the streak',
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }

  static String _monthShort(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}
