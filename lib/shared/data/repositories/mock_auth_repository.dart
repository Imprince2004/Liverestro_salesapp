import '../../../core/network/api_response.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<ApiResponse<UserEntity>> login(String phone, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success(
      const UserEntity(
        id: 'mock_user_1',
        name: 'Mock Executive',
        email: 'mock@liverestro.com',
        phone: '9876543210',
        role: 'Sales Executive',
        isPinSet: false,
      ),
    );
  }

  @override
  Future<ApiResponse<bool>> sendOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success(true, message: 'Mock OTP sent to $phone');
  }

  @override
  Future<ApiResponse<bool>> verifyOtp(String phone, String otp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (otp == '123456') {
      return ApiResponse.success(true);
    }
    return ApiResponse.error('Invalid mock OTP. Use 123456');
  }

  @override
  Future<ApiResponse<bool>> createPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success(true);
  }

  @override
  Future<ApiResponse<UserEntity>> getProfile() async {
    return login('', '');
  }

  @override
  Future<void> logout() async {}
}
