import '../../../core/network/api_response.dart';
import '../entities/user_entity.dart';

/// Auth Repository Domain Contract.
abstract class AuthRepository {
  Future<ApiResponse<UserEntity>> login(String phone, String password);
  Future<ApiResponse<bool>> sendOtp(String phone);
  Future<ApiResponse<bool>> verifyOtp(String phone, String otp);
  Future<ApiResponse<bool>> createPin(String pin);
  Future<ApiResponse<UserEntity>> getProfile();
  Future<void> logout();
}
