import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/exception_handler.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _client;

  ProfileRepositoryImpl(this._client);

  @override
  Future<ApiResponse<UserEntity>> getProfile() async {
    return ExceptionHandler.runGuarded(() async {
      final response = await _client.get('/api/users/me');
      final json = response.data as Map<String, dynamic>;
      if (json['data'] != null && json['data'] is Map<String, dynamic>) {
        return UserEntity.fromJson(json['data'] as Map<String, dynamic>);
      }
      return UserEntity.fromJson(json);
    });
  }

  @override
  Future<ApiResponse<UserEntity>> updateProfile(UserEntity user) async {
    return ExceptionHandler.runGuarded(() async {
      final payload = {
        'userId': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'date_of_birth': user.dateOfBirth,
        'date_of_joining': user.dateOfJoining,
        'designation': user.designation,
        'territory': user.territory,
        'profile_photo': user.profilePhoto,
        'address': user.address,
        'city': user.city,
        'state': user.state,
        'pincode': user.pincode,
        'emergency_contact_name': user.emergencyContactName,
        'emergency_contact_relationship': user.emergencyContactRelationship,
        'emergency_contact_phone': user.emergencyContactPhone,
      };

      try {
        final response = await _client.put('/api/users/profile', data: payload);
        if (response.data != null && response.data['data'] != null) {
          final json = response.data['data'] as Map<String, dynamic>;
          return UserEntity.fromJson(json);
        }
      } catch (_) {}

      return user;
    });
  }

  @override
  Future<ApiResponse<bool>> uploadProfilePicture(String path) async {
    return ExceptionHandler.runGuarded(() async {
      return true;
    });
  }
}
