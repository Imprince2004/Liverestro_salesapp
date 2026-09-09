import '../../../../core/network/api_response.dart';
import '../../../../shared/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<ApiResponse<UserEntity>> getProfile();
  Future<ApiResponse<UserEntity>> updateProfile(UserEntity user);
  Future<ApiResponse<bool>> uploadProfilePicture(String path);
}
