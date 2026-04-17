import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String _normalizeBaseUrlForPlatform(String value) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return value;
    }

    return value
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');
  }

  static String get apiBaseUrl {
    const define = String.fromEnvironment('API_BASE_URL');
    if (define.isNotEmpty) {
      return _normalizeBaseUrlForPlatform(define);
    }

    final env = dotenv.env['API_BASE_URL'];
    if (env != null && env.isNotEmpty) {
      return _normalizeBaseUrlForPlatform(env);
    }

    // Android emulator cannot reach host machine via localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5030';
    }

    return 'http://localhost:5030';
  }

  static String get appEnv {
    const define = String.fromEnvironment('APP_ENV');
    if (define.isNotEmpty) {
      return define;
    }

    final env = dotenv.env['APP_ENV'];
    if (env != null && env.isNotEmpty) {
      return env;
    }

    return 'dev';
  }

  static int get connectTimeoutMs {
    const define = String.fromEnvironment('CONNECT_TIMEOUT_MS');
    final defineParsed = int.tryParse(define);
    if (defineParsed != null) {
      return defineParsed;
    }

    final envParsed = int.tryParse(dotenv.env['CONNECT_TIMEOUT_MS'] ?? '');
    if (envParsed != null) {
      return envParsed;
    }

    return 15000;
  }

  static int get receiveTimeoutMs {
    const define = String.fromEnvironment('RECEIVE_TIMEOUT_MS');
    final defineParsed = int.tryParse(define);
    if (defineParsed != null) {
      return defineParsed;
    }

    final envParsed = int.tryParse(dotenv.env['RECEIVE_TIMEOUT_MS'] ?? '');
    if (envParsed != null) {
      return envParsed;
    }

    return 15000;
  }

  static bool get enableNetworkLog {
    const define = String.fromEnvironment('ENABLE_NETWORK_LOG');
    if (define.isNotEmpty) {
      return define.toLowerCase() == 'true';
    }

    final env = dotenv.env['ENABLE_NETWORK_LOG'];
    if (env != null && env.isNotEmpty) {
      return env.toLowerCase() == 'true';
    }

    return false;
  }

  static bool get isDev => appEnv == 'dev';
  static bool get isProd => appEnv == 'prod';
}
