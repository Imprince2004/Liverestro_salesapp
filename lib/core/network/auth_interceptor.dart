import 'package:dio/dio.dart';
import 'token_manager.dart';
import '../utils/logger.dart';

/// Interceptor for injecting authorization tokens and transparent 401 token refresh.
class AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;

  AuthInterceptor(this._tokenManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w('⚠️ [AuthInterceptor] 401 Unauthorized encountered. Attempting token refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newReqOptions = err.requestOptions;
        final newToken = await _tokenManager.getAccessToken();
        newReqOptions.headers['Authorization'] = 'Bearer $newToken';
        
        try {
          final dio = Dio();
          final response = await dio.fetch(newReqOptions);
          return handler.resolve(response);
        } catch (e) {
          return super.onError(err, handler);
        }
      } else {
        await _tokenManager.clearSession();
      }
    }
    super.onError(err, handler);
  }

  Future<bool> _refreshToken() async {
    // Transparent token refresh placeholder
    return false;
  }
}
