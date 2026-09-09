import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

/// Auth Remote DataSource interfacing with REST API endpoints.
class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _client.post(ApiEndpoints.login, data: {
      'phone': phone,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _client.post(ApiEndpoints.sendOtp, data: {
      'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _client.post(ApiEndpoints.verifyOtp, data: {
      'phone': phone,
      'otp': otp,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPin(String pin) async {
    final response = await _client.post(ApiEndpoints.createPin, data: {
      'pin': pin,
    });
    return response.data as Map<String, dynamic>;
  }
}
