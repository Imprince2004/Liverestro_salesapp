import '../../services/connectivity_service.dart';
import '../utils/internet_checker.dart';

/// Real-time connection quality & state manager.
class NetworkManager {
  final ConnectivityService _connectivityService;

  NetworkManager(this._connectivityService);

  Future<bool> get isConnected async {
    final hasHardwareConnection = await _connectivityService.isConnected;
    if (!hasHardwareConnection) return false;
    return await InternetChecker.hasActiveConnection();
  }

  Stream<bool> get onConnectivityChanged => _connectivityService.onConnectivityChanged;
}
