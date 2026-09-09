import 'pending_request_queue.dart';
import '../network/network_manager.dart';
import '../utils/logger.dart';

/// Automatic background offline request queue sync processor.
class OfflineSyncManager {
  final PendingRequestQueue _queue;
  final NetworkManager _networkManager;

  OfflineSyncManager(this._queue, this._networkManager) {
    _initListener();
  }

  void _initListener() {
    _networkManager.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncPendingRequests();
      }
    });
  }

  Future<void> syncPendingRequests() async {
    final pending = await _queue.getPendingRequests();
    if (pending.isEmpty) return;

    AppLogger.i('⚡ [OfflineSyncManager] Processing ${pending.length} pending offline requests...');
    for (var request in pending) {
      final id = request['id'] as String;
      // Process & sync request placeholder
      await _queue.removeRequest(id);
    }
  }
}
