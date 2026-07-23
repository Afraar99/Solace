/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/services/shield_days_store.dart';
import 'package:mindful/providers/restrictions/wellbeing_provider.dart';

final shieldDaysProvider =
    StateNotifierProvider<ShieldDaysNotifier, Map<String, Map<String, bool>>>(
  (ref) => ShieldDaysNotifier(ref),
);

class ShieldDaysNotifier extends StateNotifier<Map<String, Map<String, bool>>> {
  ShieldDaysNotifier(this._ref) : super(const {}) {
    _bootstrap();
    _ref.listen<bool>(
      wellBeingProvider.select((v) => v.blockNsfwSites),
      (_, __) => checkInToday(),
    );
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    state = await ShieldDaysStore.instance.load();
    await checkInToday();
  }

  Future<void> checkInToday() async {
    final nsfwOn = _ref.read(wellBeingProvider).blockNsfwSites;
    state = await ShieldDaysStore.instance.markToday(
      appPresent: true,
      nsfwOn: nsfwOn,
    );
  }

  int nsfwStreak() {
    var streak = 0;
    var day = DateTime.now();
    for (var i = 0; i < 400; i++) {
      final key = ShieldDaysStore.dateKey(day);
      if (state[key]?['nsfw'] == true) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int appDaysCount({int lookbackDays = 112}) {
    final today = DateTime.now();
    var count = 0;
    for (var i = 0; i < lookbackDays; i++) {
      final d = today.subtract(Duration(days: i));
      if (state[ShieldDaysStore.dateKey(d)]?['app'] == true) count++;
    }
    return count;
  }
}
