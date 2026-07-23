/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/services/bg_executor_service.dart';
import 'package:mindful/core/services/crash_log_service.dart';
import 'package:mindful/core/services/drift_db_service.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/core/services/todo_reminder_service.dart';
import 'package:mindful/mindful_app.dart';
import 'package:mindful/providers/todos/todos_provider.dart';

/// Dart background
@pragma('vm:entry-point')
Future<void> initBgExecutorService() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BgExecutorService.instance.init();
}

/// Flutter main app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize method channel and drift Database
  await MethodChannelService.instance.init();
  await DriftDbService.instance.init();
  await TodoReminderService.instance.init();

  /// Ensure breath-pause apps keep the tracker alive after reboot
  final breathPauseApps =
      await MethodChannelService.instance.getBreathPauseApps();
  if (breathPauseApps.isNotEmpty) {
    await MethodChannelService.instance.updateBreathPauseApps(breathPauseApps);
  }

  final pendingTodos =
      await DriftDbService.instance.driftDb.todosDao.fetchPendingTodos();
  await TodoReminderService.instance.rescheduleAll(pendingTodos);

  final todosNotifier = TodosNotifier();
  await todosNotifier.applyPendingWidgetCompletions();
  await todosNotifier.syncWidgetSnapshot();

  FlutterError.onError = (errorDetails) {
    CrashLogService.instance.recordCrashError(
      errorDetails.exception.toString(),
      errorDetails.stack.toString(),
    );

    if (kDebugMode) {
      FlutterError.presentError(errorDetails);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogService.instance.recordCrashError(
      error.toString(),
      stack.toString(),
    );
    return !kDebugMode;
  };

  /// Scale app from edge-edge behind system ui (mobile only)
  if (MethodChannelService.instance.isNativeAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// run main app
  runApp(
    const ProviderScope(
      child: MindfulApp(),
    ),
  );
}
