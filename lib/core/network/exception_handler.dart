import 'api_response.dart';
import 'error_mapper.dart';
import '../utils/logger.dart';

/// Centralized safe execution wrapper for asynchronous operations.
class ExceptionHandler {
  ExceptionHandler._();

  static Future<ApiResponse<T>> runGuarded<T>(
    Future<T> Function() action,
  ) async {
    try {
      final data = await action();
      return ApiResponse.success(data);
    } catch (e, stack) {
      AppLogger.e('Unhandled exception in runGuarded: $e', e, stack);
      return ApiResponse.error(ErrorMapper.mapToErrorMessage(e));
    }
  }
}
