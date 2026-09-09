import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod, mock }

/// Environment configuration resolution for LiveRestro Sales.
class Environment {
  Environment._();

  /// Compile-time build argument (e.g. flutter build apk --dart-define=API_BASE_URL=https://api.liverestro.com)
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _envString = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String ngrokPublicUrl = 'https://liverestro-salesapp.onrender.com';

  static AppEnvironment current = _resolveInitialEnvironment();
  static String? activeWorkingBaseUrl;

  static AppEnvironment _resolveInitialEnvironment() {
    if (kReleaseMode || _envString == 'prod' || _envString == 'production') {
      return AppEnvironment.prod;
    }
    if (_envString == 'staging') return AppEnvironment.staging;
    if (_envString == 'mock') return AppEnvironment.mock;
    return AppEnvironment.dev;
  }

  static void setEnvironment(AppEnvironment env) {
    current = env;
  }

  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    if (activeWorkingBaseUrl != null) return activeWorkingBaseUrl!;
    if (ngrokPublicUrl.isNotEmpty) return ngrokPublicUrl;
    switch (current) {
      case AppEnvironment.prod:
        return 'https://api.liverestro.com';
      case AppEnvironment.staging:
        return 'https://staging-api.liverestro.com';
      case AppEnvironment.dev:
        return lanUrl;
      case AppEnvironment.mock:
        if (!kIsWeb) {
          if (Platform.isAndroid) return 'http://10.0.2.2:5000';
          if (Platform.isIOS) return 'http://localhost:5000';
        }
        return 'http://127.0.0.1:5000';
    }
  }

  static String get localDesktopUrl => 'http://127.0.0.1:5000';
  static String get emulatorUrl => 'http://10.0.2.2:5000';
  static String get lanIpUrl => 'http://10.201.26.248:5000';
  static String get lanUrl => 'http://10.201.26.248:5000';

  static List<String> get apiCandidates => resolvedApiCandidates;

  static List<String> get resolvedApiCandidates {
    // 1. If explicit compile-time API_BASE_URL is provided, use only that
    if (configuredBaseUrl.isNotEmpty) {
      return [configuredBaseUrl];
    }

    // 2. Priority: Public Ngrok HTTPS Tunnel URL for testing across mobile data / external WiFi
    final candidates = <String>[];
    if (ngrokPublicUrl.isNotEmpty) {
      candidates.add(ngrokPublicUrl);
    }

    // 3. In Production release mode, strictly target the production URL
    if (current == AppEnvironment.prod) {
      return ['https://api.liverestro.com'];
    }

    // 4. If a working URL has already responded in the current session
    if (activeWorkingBaseUrl != null) {
      candidates.add(activeWorkingBaseUrl!);
    }

    // 5. Localhost & LAN Fallbacks
    if (kIsWeb) {
      candidates.addAll(['http://localhost:5000', 'http://127.0.0.1:5000', 'http://10.201.26.248:5000']);
    } else if (Platform.isAndroid) {
      candidates.addAll([
        'http://10.201.26.248:5000',
        'http://192.168.29.229:5000',
        emulatorUrl,
        'http://localhost:5000',
        'http://127.0.0.1:5000',
      ]);
    } else if (Platform.isIOS) {
      candidates.addAll([
        'http://10.201.26.248:5000',
        'http://192.168.29.229:5000',
        'http://localhost:5000',
        'http://127.0.0.1:5000',
      ]);
    } else {
      candidates.addAll([
        'http://127.0.0.1:5000',
        'http://localhost:5000',
        'http://10.201.26.248:5000',
      ]);
    }

    return candidates.toSet().toList();
  }

  static bool get isDev => current == AppEnvironment.dev;
  static bool get isStaging => current == AppEnvironment.staging;
  static bool get isProd => current == AppEnvironment.prod;
  static bool get isMock => current == AppEnvironment.mock;
}
