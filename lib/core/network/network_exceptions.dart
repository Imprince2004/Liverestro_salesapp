import 'package:dio/dio.dart';

/// Network exception class for handling API and Dio connection errors cleanly.
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(message: 'Connection timeout with server. Please try again.');
      case DioExceptionType.sendTimeout:
        return NetworkException(message: 'Send timeout in connection with server.');
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Receive timeout in connection with server.');
      case DioExceptionType.badCertificate:
        return NetworkException(message: 'Bad certificate detected.');
      case DioExceptionType.badResponse:
        return _handleBadResponse(dioException.response);
      case DioExceptionType.cancel:
        return NetworkException(message: 'Request to server was cancelled.');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'No internet connection detected.');
      case DioExceptionType.unknown:
      default:
        return NetworkException(message: 'Unexpected network error occurred. Please try again.');
    }
  }

  static NetworkException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    String message = 'Server returned error status code: $statusCode';

    if (data is Map<String, dynamic> && data.containsKey('message')) {
      message = data['message'] as String;
    }

    switch (statusCode) {
      case 400:
        return NetworkException(message: message, statusCode: 400);
      case 401:
        return NetworkException(message: 'Unauthorized access. Please login again.', statusCode: 401);
      case 403:
        return NetworkException(message: 'Access forbidden for this resource.', statusCode: 403);
      case 404:
        return NetworkException(message: 'Requested resource not found.', statusCode: 404);
      case 500:
        return NetworkException(message: 'Internal server error. Please try later.', statusCode: 500);
      default:
        return NetworkException(message: message, statusCode: statusCode);
    }
  }

  @override
  String toString() => 'NetworkException(statusCode: $statusCode, message: $message)';
}
