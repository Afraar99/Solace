import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/services/method_channel_service.dart';

/// Whether the parent-controlled Kids Mode preset is active.
///
/// Android owns persistence because enforcement also runs while Flutter is not
/// open. This provider mirrors the native value for the settings UI.
final kidsModeProvider =
    StateNotifierProvider<KidsModeNotifier, AsyncValue<bool>>(
  (ref) => KidsModeNotifier(),
);

class KidsModeNotifier extends StateNotifier<AsyncValue<bool>> {
  KidsModeNotifier() : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    state = AsyncData(await MethodChannelService.instance.getKidsMode());
  }

  Future<bool> setEnabled(bool enabled) async {
    final previous = state.value ?? false;
    state = const AsyncLoading();

    final saved = await MethodChannelService.instance.updateKidsMode(enabled);
    if (!saved) {
      state = AsyncData(previous);
      return false;
    }

    state = AsyncData(enabled);
    return true;
  }
}
