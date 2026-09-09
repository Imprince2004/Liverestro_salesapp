/// API Endpoint path definitions for LiveRestro Sales.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth Endpoints
  static const String login = '/api/v1/auth/login';
  static const String sendOtp = '/api/v1/auth/send-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String createPin = '/api/v1/auth/create-pin';
  static const String refreshToken = '/api/v1/auth/refresh-token';

  // Sales Executive Endpoints
  static const String executiveProfile = '/api/v1/executive/profile';
  static const String dashboardStats = '/api/v1/executive/dashboard';

  // Restaurants & Visits Endpoints
  static const String restaurantList = '/api/v1/restaurants';
  static const String logVisit = '/api/v1/visits/checkin';
  static const String createOrder = '/api/v1/orders/create';
}
