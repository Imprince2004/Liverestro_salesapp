import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// Automatic exponential backoff retry mechanism for network requests.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 1000),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    if (requestOptions.extra['skip_retry'] == true || requestOptions.extra['no_retry'] == true) {
      return super.onError(err, handler);
    }

    final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final nextCount = retryCount + 1;
      requestOptions.extra['retry_count'] = nextCount;

      final delay = initialDelay * (1 << retryCount);
      AppLogger.w('🔄 [RetryInterceptor] Retrying request ($nextCount/$maxRetries) in ${delay.inMilliseconds}ms...');

      await Future.delayed(delay);

      try {
        final dio = Dio();
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    // Do not retry immediately refused connections (wrong host/port)
    final errStr = err.error?.toString().toLowerCase() ?? '';
    if (errStr.contains('connection refused') || errStr.contains('errno = 111') || errStr.contains('errno = 61')) {
      return false;
    }

    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}
