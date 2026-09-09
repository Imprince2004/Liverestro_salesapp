import 'network_exceptions.dart';

/// Error mapper converting exceptions into clean user-facing failure domain representations.
class ErrorMapper {
  ErrorMapper._();

  static String mapToErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
