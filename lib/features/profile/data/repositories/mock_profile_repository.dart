import '../../../../core/network/api_response.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  UserEntity _mockUser = const UserEntity(
    id: 'EMP00125',
    name: 'Prince Chandarana',
    email: 'prince@gmail.com',
    phone: '+91 98765 43210',
    role: 'Sales Executive',
    isPinSet: true,
  );

  @override
  Future<ApiResponse<UserEntity>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success(_mockUser);
  }

  @override
  Future<ApiResponse<UserEntity>> updateProfile(UserEntity user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockUser = user;
    return ApiResponse.success(_mockUser);
  }

  @override
  Future<ApiResponse<bool>> uploadProfilePicture(String path) async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse.success(true);
  }
}
