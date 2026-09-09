import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

/// Enterprise JWT Token and Refresh Token lifecycle manager.
class TokenManager {
  final SecureStorageService _secureStorage;

  TokenManager(this._secureStorage);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.saveAuthToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
    AppLogger.d('🔑 Tokens securely saved.');
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.getAuthToken();
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _secureStorage.clearAll();
    AppLogger.i('🔒 Session cleared cleanly.');
  }
}
