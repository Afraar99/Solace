/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/services/method_channel_service.dart';

/// Packages that show a One Sec–style breathing pause when opened.
final breathPauseAppsProvider =
    StateNotifierProvider<BreathPauseAppsNotifier, Set<String>>(
  (ref) => BreathPauseAppsNotifier(),
);

class BreathPauseAppsNotifier extends StateNotifier<Set<String>> {
  BreathPauseAppsNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final apps = await MethodChannelService.instance.getBreathPauseApps();
    if (!mounted) return;
    state = apps.toSet();

    /// Re-sync so the tracker service starts after reboot when only
    /// breathing pause is configured (no timers / limits).
    if (apps.isNotEmpty) {
      await MethodChannelService.instance.updateBreathPauseApps(apps);
    }
  }

  Future<void> setEnabled(String packageName, bool enabled) async {
    final next = Set<String>.from(state);
    if (enabled) {
      next.add(packageName);
    } else {
      next.remove(packageName);
    }
    state = next;
    await MethodChannelService.instance.updateBreathPauseApps(next.toList());
  }
}
