import 'app_logger.dart';

/// Crash reporting service placeholder (Firebase Crashlytics / Sentry).
class CrashLogger {
  CrashLogger._();

  static Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason}) async {
    AppLogger.e('💥 [CrashLogger] Error recorded: $reason', exception, stack);
  }

  static Future<void> setUserIdentifier(String userId) async {
    AppLogger.i('👤 [CrashLogger] Set user id: $userId');
  }
}
