import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/strings.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ));
});

/// Production Encrypted Storage Service wrapper around FlutterSecureStorage.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppStrings.authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppStrings.authTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppStrings.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppStrings.refreshTokenKey);
  }

  Future<void> saveUserPin(String pin) async {
    await _storage.write(key: AppStrings.userPinKey, value: pin);
  }

  Future<String?> getUserPin() async {
    return await _storage.read(key: AppStrings.userPinKey);
  }

  Future<void> saveSecurityPin(String pin) => saveUserPin(pin);
  Future<String?> getSecurityPin() => getUserPin();

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
