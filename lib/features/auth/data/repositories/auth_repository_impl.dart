import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/network/token_manager.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_response_model.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final HiveStorageService _hiveStorage;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required HiveStorageService hiveStorage,
    required TokenManager tokenManager,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _hiveStorage = hiveStorage,
        _tokenManager = tokenManager;

  Future<AuthResponseModel> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      identifier: identifier,
      password: password,
    );

    if (response.success && response.user != null) {
      final user = response.user!;
      if (response.token != null) {
        await _tokenManager.saveTokens(
          accessToken: response.token!,
          refreshToken: response.token!,
        );
        await _secureStorage.saveAuthToken(response.token!);
      }

      // Persist user role and profile details in Hive
      await _hiveStorage.put('user_id', user.id);
      await _hiveStorage.put('user_name', user.name);
      await _hiveStorage.put('user_email', user.email);
      await _hiveStorage.put('user_phone', user.phone);
      await _hiveStorage.put('user_role', user.role);
      await _hiveStorage.put('active_app_user_role', _mapRoleToEnumName(user.role));
      if (user.organizationId != null) {
        await _hiveStorage.put('user_organization_id', user.organizationId);
      }
      if (user.organizationName != null) {
        await _hiveStorage.put('user_organization_name', user.organizationName);
      }
    }

    return response;
  }

  Future<UserEntity?> getCurrentUser() async {
    final token = await _secureStorage.getAuthToken();
    if (token == null) return null;

    final response = await _remoteDataSource.getMe(token);
    if (response.success && response.user != null) {
      return response.user;
    }
    return null;
  }

  Future<void> logout() async {
    await _tokenManager.clearSession();
    await _secureStorage.clearAll();
  }

  String _mapRoleToEnumName(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'superAdmin';
      case 'COMPANY_ADMIN':
        return 'companyAdmin';
      case 'SALES_MANAGER':
        return 'salesManager';
      case 'SALES_EXECUTIVE':
      default:
        return 'salesExecutive';
    }
  }
}
