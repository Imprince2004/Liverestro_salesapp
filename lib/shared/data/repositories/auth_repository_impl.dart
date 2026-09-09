import '../../../core/network/api_response.dart';
import '../../../core/network/exception_handler.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Auth Repository implementation bridging remote & local data sources.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<UserEntity>> login(String phone, String password) async {
    return ExceptionHandler.runGuarded(() async {
      final json = await _remoteDataSource.login(phone, password);
      final userJson = json['user'] as Map<String, dynamic>? ?? {};
      final token = json['access_token'] as String? ?? '';
      final refreshToken = json['refresh_token'] as String? ?? '';

      if (token.isNotEmpty) {
        await _localDataSource.saveTokens(token, refreshToken);
      }

      return UserEntity(
        id: userJson['id'] as String? ?? 'user_1',
        name: userJson['name'] as String? ?? 'Executive',
        email: userJson['email'] as String? ?? 'executive@liverestro.com',
        phone: phone,
        role: userJson['role'] as String? ?? 'Sales Executive',
        isPinSet: userJson['is_pin_set'] as bool? ?? false,
      );
    });
  }

  @override
  Future<ApiResponse<bool>> sendOtp(String phone) async {
    return ExceptionHandler.runGuarded(() async {
      await _remoteDataSource.sendOtp(phone);
      return true;
    });
  }

  @override
  Future<ApiResponse<bool>> verifyOtp(String phone, String otp) async {
    return ExceptionHandler.runGuarded(() async {
      await _remoteDataSource.verifyOtp(phone, otp);
      return true;
    });
  }

  @override
  Future<ApiResponse<bool>> createPin(String pin) async {
    return ExceptionHandler.runGuarded(() async {
      await _remoteDataSource.createPin(pin);
      await _localDataSource.savePin(pin);
      return true;
    });
  }

  @override
  Future<ApiResponse<UserEntity>> getProfile() async {
    return ExceptionHandler.runGuarded(() async {
      return const UserEntity(
        id: 'user_1',
        name: 'LiveRestro Executive',
        email: 'executive@liverestro.com',
        phone: '+91 9876543210',
        role: 'Senior Sales Executive',
        isPinSet: true,
      );
    });
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAuth();
  }
}
