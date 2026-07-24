/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/shield_days_store.dart';
import 'package:mindful/providers/restrictions/wellbeing_provider.dart';
import 'package:mindful/providers/shield/shield_days_provider.dart';
import 'package:mindful/ui/common/styled_text.dart';

/// GitHub-style contribution graph + clean streak counter (until relapse).
class ShieldContributionCard extends ConsumerWidget {
  const ShieldContributionCard({super.key});

  static const int _weeks = 16;

  /// Classic GitHub contribution greens
  static const _empty = Color(0xFF21262D);
  static const _level1 = Color(0xFF0E4429);
  static const _level2 = Color(0xFF006D32);
  static const _level3 = Color(0xFF26A641);
  static const _level4 = Color(0xFF39D353);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(shieldDaysProvider);
    final nsfwOn = ref.watch(wellBeingProvider.select((v) => v.blockNsfwSites));
    final streak = ref.read(shieldDaysProvider.notifier).nsfwStreak();
    final appDays = ref.read(shieldDaysProvider.notifier).appDaysCount();
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final weekday = todayOnly.weekday;
    final endOfWeek = todayOnly.add(Duration(days: 7 - weekday));
    final start = endOfWeek.subtract(Duration(days: (_weeks * 7) - 1));

    final monthLabels = <int, String>{};
    for (var w = 0; w < _weeks; w++) {
      final colStart = start.add(Duration(days: w * 7));
      if (colStart.day <= 7 || w == 0) {
        monthLabels[w] = _monthShort(colStart.month);
      }
    }

    final streakLabel = formatCleanDuration(streak);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledText(
                      nsfwOn ? 'Clean streak' : 'Daily presence',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    4.vBox,
                    StyledText(
                      nsfwOn
                          ? streakLabel
                          : 'Turn on NSFW filter to start counting',
                      fontSize: nsfwOn ? 26 : 13,
                      fontWeight: nsfwOn ? FontWeight.w700 : FontWeight.w500,
                      color: nsfwOn
                          ? _level4
                          : scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    if (nsfwOn) ...[
                      2.vBox,
                      StyledText(
                        'until relapse',
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: nsfwOn
                      ? _level2.withValues(alpha: 0.35)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StyledText(
                  nsfwOn ? 'Shield on' : 'NSFW off',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: nsfwOn
                      ? _level4
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          14.vBox,

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

                        final Color fill;
                        if (isFuture) {
                          fill = _empty.withValues(alpha: 0.35);
                        } else if (hasNsfw) {
                          fill = _level4;
                        } else if (hasApp) {
                          fill = _level2;
                        } else {
                          fill = _empty;
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
                                      color: Colors.white.withValues(alpha: 0.75),
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
          Row(
            children: [
              StyledText(
                'Less',
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              6.hBox,
              _legendSwatch(_empty),
              3.hBox,
              _legendSwatch(_level1),
              3.hBox,
              _legendSwatch(_level2),
              3.hBox,
              _legendSwatch(_level3),
              3.hBox,
              _legendSwatch(_level4),
              6.hBox,
              StyledText(
                'More',
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              const Spacer(),
              StyledText(
                'App days: $appDays',
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _legendSwatch(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  /// Days → months → years, e.g. "12 days", "1 month", "1 year 2 months"
  static String formatCleanDuration(int days) {
    if (days <= 0) return '0 days';
    if (days < 30) return days == 1 ? '1 day' : '$days days';

    if (days < 365) {
      final months = days ~/ 30;
      final rem = days % 30;
      final monthPart = months == 1 ? '1 month' : '$months months';
      if (rem == 0) return monthPart;
      return '$monthPart ${rem == 1 ? '1 day' : '$rem days'}';
    }

    final years = days ~/ 365;
    final remDays = days % 365;
    final months = remDays ~/ 30;
    final yearPart = years == 1 ? '1 year' : '$years years';
    if (months == 0) return yearPart;
    return '$yearPart ${months == 1 ? '1 month' : '$months months'}';
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
