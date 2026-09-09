import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(LocalAuthentication());
});

/// Local Authentication (Biometric Fingerprint / FaceID) Service.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService(this._auth);

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      AppLogger.e('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.e('Error retrieving biometric types: $e');
      return [];
    }
  }

  Future<bool> authenticate({String reason = 'Scan your Fingerprint or Face to unlock LiveRestro Sales'}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        AppLogger.w('Biometrics unavailable on this device.');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e) {
      AppLogger.e('Biometric authentication failed: $e');
      return false;
    }
  }
}
