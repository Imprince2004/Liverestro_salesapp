import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/token_manager.dart';

/// Auth Local DataSource handling secure tokens & credentials storage.
class AuthLocalDataSource {
  final SecureStorageService _secureStorage;
  final TokenManager _tokenManager;

  AuthLocalDataSource(this._secureStorage, this._tokenManager);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> savePin(String pin) async {
    await _secureStorage.saveUserPin(pin);
  }

  Future<void> clearAuth() async {
    await _tokenManager.clearSession();
  }
}
