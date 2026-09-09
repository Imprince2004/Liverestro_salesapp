import 'dart:async';
import '../storage/secure_storage_service.dart';
import '../../services/biometric_service.dart';
import '../utils/logger.dart';

/// Security Manager handling session timeouts, biometric authentication & PIN checks.
class SecurityManager {
  final SecureStorageService _secureStorage;
  final BiometricService _biometricService;
  Timer? _sessionTimer;
  final Duration _timeoutDuration = const Duration(minutes: 15);

  SecurityManager(this._secureStorage, this._biometricService);

  void resetSessionTimer(Function onTimeout) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_timeoutDuration, () {
      AppLogger.w('🔒 Session timed out due to inactivity.');
      onTimeout();
    });
  }

  Future<bool> authenticateWithBiometrics() async {
    final available = await _biometricService.isBiometricAvailable();
    if (!available) return false;
    return await _biometricService.authenticate();
  }

  Future<bool> verifyUserPin(String enteredPin) async {
    final savedPin = await _secureStorage.getUserPin();
    return savedPin != null && savedPin == enteredPin;
  }
}
