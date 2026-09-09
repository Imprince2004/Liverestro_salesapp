import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

/// Dio Interceptor for authorization header injection, request logging, and error handling.
class ApiInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  ApiInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    AppLogger.d('🌐 [API Request] [${options.method}] ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('✅ [API Response] [${response.statusCode}] ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('❌ [API Error] [${err.response?.statusCode}] ${err.requestOptions.uri} - ${err.message}');
    super.onError(err, handler);
  }
}
