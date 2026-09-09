import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/environment.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/notification_model.dart';

// Top-level stream controller for newly arrived in-app notifications
final realtimeNotificationStreamController = StreamController<NotificationModel>.broadcast();

class NotificationListNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;
  Timer? _pollingTimer;

  NotificationListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initNotifier();
  }

  static List<String> get _fastApiCandidates {
    final active = Environment.activeWorkingBaseUrl;
    return {
      if (active != null) active,
      Environment.lanUrl,
      'https://stature-versus-rule.ngrok-free.dev',
      'http://10.159.105.248:5000',
      'http://10.0.2.2:5000',
      'http://127.0.0.1:5000',
      'http://localhost:5000',
    }.toList();
  }

  static final Dio _directDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500),
      receiveTimeout: const Duration(milliseconds: 2500),
      sendTimeout: const Duration(milliseconds: 2500),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  void _initNotifier() {
    _loadFromLocalCache();
    fetchNotifications();

    // Start background sync timer for real-time delivery
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      fetchNotifications(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _getCacheKey() {
    final authState = _ref.read(authNotifierProvider);
    final hive = getIt<HiveStorageService>();
    final userId = authState.user?.id ?? hive.get<String>('user_id') ?? 'current_user';
    return 'user_notifications_db_$userId';
  }

  void _loadFromLocalCache() {
    final hive = getIt<HiveStorageService>();
    final cacheKey = _getCacheKey();
    final cached = hive.get<String>(cacheKey);

    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cached);
        final list = decoded.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
        state = AsyncValue.data(list);
      } catch (_) {}
    }
  }

  Future<void> _saveToLocalCache(List<NotificationModel> list) async {
    final hive = getIt<HiveStorageService>();
    final cacheKey = _getCacheKey();
    await hive.put(cacheKey, jsonEncode(list.map((n) => n.toJson()).toList()));
  }

  Future<void> fetchNotifications({bool isBackground = false}) async {
    if (!isBackground && (state.value == null || state.value!.isEmpty)) {
      state = const AsyncValue.loading();
    }

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final authState = _ref.read(authNotifierProvider);
      final hive = getIt<HiveStorageService>();
      final currentUserId = authState.user?.id ?? hive.get<String>('user_id') ?? '';

      for (final base in _fastApiCandidates) {
        try {
          final res = await _directDio.get(
            '$base/api/notifications',
            queryParameters: {
              if (currentUserId.isNotEmpty) 'user_id': currentUserId,
            },
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> rawList = res.data['data'];
            final List<NotificationModel> serverList = rawList
                .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
                .toList();

            // Detect any new incoming unread notifications to trigger push/sound
            final currentIds = (state.value ?? []).map((n) => n.id).toSet();
            for (final item in serverList) {
              if (!currentIds.contains(item.id) && !item.isRead) {
                _triggerDeviceNotificationAlert(item);
              }
            }

            state = AsyncValue.data(serverList);
            await _saveToLocalCache(serverList);
            return;
          }
        } catch (_) {}
      }

      // If network is offline, maintain current state from local DB
      if (state.value == null) {
        _loadFromLocalCache();
        if (state.value == null) {
          state = const AsyncValue.data([]);
        }
      }
    } catch (e, st) {
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _triggerDeviceNotificationAlert(NotificationModel notification) {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    realtimeNotificationStreamController.add(notification);
  }

  Future<void> addIncomingNotification(NotificationModel notification) async {
    final currentList = state.value ?? [];
    // Avoid duplicate insertions
    if (currentList.any((n) => n.id == notification.id)) return;

    final updated = [notification, ...currentList];
    state = AsyncValue.data(updated);
    await _saveToLocalCache(updated);

    _triggerDeviceNotificationAlert(notification);
  }

  Future<void> markAsRead(String notificationId) async {
    final currentList = state.value ?? [];
    final updated = currentList.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _saveToLocalCache(updated);

    // Sync mark-as-read to backend API
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          await _directDio.put(
            '$base/api/notifications/$notificationId/read',
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final currentList = state.value ?? [];
    final updated = currentList.map((n) => n.copyWith(isRead: true)).toList();

    state = AsyncValue.data(updated);
    await _saveToLocalCache(updated);

    // Sync to backend API
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final authState = _ref.read(authNotifierProvider);
      final currentUserId = authState.user?.id ?? '';

      for (final base in _fastApiCandidates) {
        try {
          await _directDio.put(
            '$base/api/notifications/read-all',
            data: {
              if (currentUserId.isNotEmpty) 'user_id': currentUserId,
            },
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentList = state.value ?? [];
    final updated = currentList.where((n) => n.id != notificationId).toList();

    state = AsyncValue.data(updated);
    await _saveToLocalCache(updated);

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          await _directDio.delete(
            '$base/api/notifications/$notificationId',
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ),
          );
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationListNotifier(ref);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncNotifications = ref.watch(notificationListProvider);
  return asyncNotifications.value?.where((n) => !n.isRead).length ?? 0;
});
