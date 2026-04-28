import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'app.dart';
import 'background/background_tasks.dart';
import 'core/utils/crash_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTasks.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashLogger.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogger.recordPlatformError(error, stack);
    return false;
  };

  runApp(const ProviderScope(child: RolPagosApp()));
}
