import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('  $error');
      }
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
  }
}
