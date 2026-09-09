import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/environment.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AttendanceService {
  final Dio _dio;
  final HiveStorageService _hive;

  AttendanceService()
      : _dio = getIt<ApiClient>().instance,
        _hive = getIt<HiveStorageService>();

  static const String _queueKey = 'attendance_sync_queue';

  /// Check if the device is connected to the internet
  Future<bool> isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return !connectivity.contains(ConnectivityResult.none);
  }

  /// Add an action to the local queue
  Future<void> _addToQueue(Map<String, dynamic> action) async {
    final queueJson = _hive.get<String>(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);
    queue.add(action);
    await _hive.put(_queueKey, jsonEncode(queue));
  }

  /// Process the local sync queue
  Future<void> syncPendingRecords() async {
    if (!await isOnline()) return;

    final queueJson = _hive.get<String>(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);
    if (queue.isEmpty) return;

    final token = await getIt<SecureStorageService>().getAuthToken();
    if (token == null || token.isEmpty) return;

    final List<dynamic> remainingQueue = [];

    for (final item in queue) {
      try {
        final action = item['action'];
        final lat = item['lat'];
        final lng = item['lng'];
        final time = item['time'];
        final isAutomatic = item['is_automatic'] ?? false;

        if (action == 'check-in') {
          await _dio.post(
            '${Environment.lanUrl}/api/attendance/check-in',
            data: {'lat': lat, 'lng': lng, 'time': time},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } else if (action == 'check-out') {
          await _dio.post(
            '${Environment.lanUrl}/api/attendance/check-out',
            data: {'lat': lat, 'lng': lng, 'time': time, 'is_automatic': isAutomatic},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
      } catch (e) {
        remainingQueue.add(item);
      }
    }

    await _hive.put(_queueKey, jsonEncode(remainingQueue));
  }

  /// Record check-in
  Future<bool> checkIn(double lat, double lng, DateTime time) async {
    final payload = {
      'action': 'check-in',
      'lat': lat,
      'lng': lng,
      'time': time.toIso8601String(),
    };

    final token = await getIt<SecureStorageService>().getAuthToken();

    if (await isOnline() && token != null && token.isNotEmpty) {
      try {
        await _dio.post(
          '${Environment.lanUrl}/api/attendance/check-in',
          data: {'lat': lat, 'lng': lng, 'time': time.toIso8601String()},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return true;
      } catch (_) {
        // Fail: queue
      }
    }

    await _addToQueue(payload);
    return false;
  }

  /// Record check-out
  Future<bool> checkOut(double lat, double lng, DateTime time, bool isAutomatic) async {
    final payload = {
      'action': 'check-out',
      'lat': lat,
      'lng': lng,
      'time': time.toIso8601String(),
      'is_automatic': isAutomatic,
    };

    final token = await getIt<SecureStorageService>().getAuthToken();

    if (await isOnline() && token != null && token.isNotEmpty) {
      try {
        await _dio.post(
          '${Environment.lanUrl}/api/attendance/check-out',
          data: {
            'lat': lat,
            'lng': lng,
            'time': time.toIso8601String(),
            'is_automatic': isAutomatic,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return true;
      } catch (_) {
        // Fail: queue
      }
    }

    await _addToQueue(payload);
    return false;
  }
}
