import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CrashLogger {
  CrashLogger._();

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      final buffer = StringBuffer()
        ..writeln('--- FlutterError ${DateTime.now().toIso8601String()} ---')
        ..writeln(details.exceptionAsString())
        ..writeln(details.stack ?? '')
        ..writeln('-----------------------------------------------')
        ..writeln();

      await _append(buffer.toString());
    } catch (_) {
      // Evitar crashes recursivos por logging.
    }
  }

  static Future<void> recordPlatformError(
    Object error,
    StackTrace stack,
  ) async {
    try {
      final buffer = StringBuffer()
        ..writeln('--- PlatformError ${DateTime.now().toIso8601String()} ---')
        ..writeln(error.toString())
        ..writeln(stack.toString())
        ..writeln('------------------------------------------------')
        ..writeln();

      await _append(buffer.toString());
    } catch (_) {}
  }

  static Future<String?> readLog() async {
    try {
      final file = await _logFile();
      if (!await file.exists()) return null;
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _logFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<void> _append(String content) async {
    final file = await _logFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(content, mode: FileMode.append, flush: true);
  }

  static Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'logs', 'crash.log'));
  }
}
