import 'package:logger/logger.dart';

/// Enterprise structured logger.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  static void logApiRequest(String method, String url, Map<String, dynamic>? headers) {
    _logger.i('🌐 [API Request] [$method] $url\nHeaders: $headers');
  }

  static void logApiResponse(String method, String url, int statusCode, int durationMs) {
    _logger.i('✅ [API Response] [$statusCode] [$durationMs ms] [$method] $url');
  }
}
