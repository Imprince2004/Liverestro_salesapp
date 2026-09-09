import 'sqflite_storage_service.dart';
import '../utils/logger.dart';

/// SQLite Persistent Pending Request Queue for offline SFA capabilities.
class PendingRequestQueue {
  final SqfliteStorageService _sqflite;

  PendingRequestQueue(this._sqflite);

  Future<void> enqueueRequest({
    required String id,
    required String endpoint,
    required String method,
    required String payload,
  }) async {
    final db = await _sqflite.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_requests (
        id TEXT PRIMARY KEY,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.insert('pending_requests', {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
    AppLogger.i('📥 [PendingRequestQueue] Enqueued offline request: $endpoint');
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final db = await _sqflite.database;
    try {
      return await db.query('pending_requests', orderBy: 'timestamp ASC');
    } catch (_) {
      return [];
    }
  }

  Future<void> removeRequest(String id) async {
    final db = await _sqflite.database;
    await db.delete('pending_requests', where: 'id = ?', whereArgs: [id]);
    AppLogger.d('🗑️ [PendingRequestQueue] Processed request removed: $id');
  }
}
