import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Local-development default for mobile simulators and emulators.
  ///
  /// Override this for physical devices and deployed environments with:
  /// `--dart-define=API_BASE_URL=https://api.example.com`.
  static String get baseUrl {
    final configuredBaseUrl = _configuredBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5088';
    }

    return 'http://localhost:5088';
  }
}
