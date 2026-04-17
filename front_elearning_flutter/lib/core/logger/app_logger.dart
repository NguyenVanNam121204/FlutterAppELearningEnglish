import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
    }
  }
}
