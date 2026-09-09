import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';
import 'token_manager.dart';
import '../utils/environment.dart';
import '../utils/logger.dart';

/// Enterprise ApiClient wrapping Dio with auth, retry, and environment URL resolution.
class ApiClient {
  late final Dio _dio;

  ApiClient(TokenManager tokenManager) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(tokenManager),
      RetryInterceptor(),
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => AppLogger.d(obj.toString()),
      ),
    ]);
  }

  Dio get instance => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    _dio.options.baseUrl = Environment.baseUrl;
    return await _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _dio.options.baseUrl = Environment.baseUrl;
    return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _dio.options.baseUrl = Environment.baseUrl;
    return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _dio.options.baseUrl = Environment.baseUrl;
    return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}
