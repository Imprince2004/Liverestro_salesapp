import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/environment.dart';
import '../models/follow_up_model.dart';

class FollowUpRepository {
  final HiveStorageService _hive;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 2000),
      receiveTimeout: const Duration(milliseconds: 3000),
      sendTimeout: const Duration(milliseconds: 3000),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  FollowUpRepository({HiveStorageService? hive})
      : _hive = hive ?? getIt<HiveStorageService>();

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

  String _getCurrentUserId() {
    try {
      return _hive.get<String>('user_id') ?? _hive.get<String>('user_employee_id') ?? 'usr_salesexecutive_prince';
    } catch (_) {
      return 'usr_salesexecutive_prince';
    }
  }

  /// Fetches follow-ups and dynamic category counts from the backend database with offline resiliency
  Future<({FollowUpCounts counts, List<FollowUpModel> items})> getFollowUps({
    String tab = 'all',
    String search = '',
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _getCurrentUserId();
    final cacheKey = 'cached_follow_ups_$effectiveUserId';

    final queryParams = <String, dynamic>{
      'tab': tab,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'userId': effectiveUserId,
    };

    // 1. Try real backend database via fast candidate failover
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.get(
            '$base/api/follow-ups',
            queryParameters: queryParams,
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null) {
            Environment.activeWorkingBaseUrl = base;
            final decoded = res.data is Map<String, dynamic>
                ? res.data as Map<String, dynamic>
                : json.decode(res.data.toString()) as Map<String, dynamic>;

            final countsJson = decoded['counts'] as Map<String, dynamic>?;
            final dataJson = decoded['data'] as List<dynamic>? ?? [];

            final counts = FollowUpCounts.fromJson(countsJson);
            final items = dataJson
                .map((e) => FollowUpModel.fromJson(e as Map<String, dynamic>))
                .toList();

            // Persist latest database records in local cache
            await _hive.put(cacheKey, jsonEncode(items.map((i) => i.toJson()).toList()));
            return (counts: counts, items: items);
          }
        } catch (_) {}
      }
    } catch (_) {}

    // 2. Offline / Local Cache Fallback: Retrieve saved follow-ups
    List<FollowUpModel> cachedList = [];
    final cached = _hive.get<String>(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        cachedList = list.map((e) => FollowUpModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    // 3. Supplement with follow-ups scheduled inside real leads if cached follow-ups are empty
    if (cachedList.isEmpty) {
      try {
        final rawLeads = _hive.get<String>('cached_leads_v4');
        if (rawLeads != null) {
          final List<dynamic> leads = jsonDecode(rawLeads);
          for (final l in leads) {
            final leadMap = Map<String, dynamic>.from(l);
            final nextDate = leadMap['next_follow_up_date'] ?? leadMap['nextFollowUpDate'];
            if (nextDate != null && nextDate.toString().isNotEmpty) {
              final nextTime = leadMap['next_follow_up_time'] ?? leadMap['nextFollowUpTime'] ?? '11:00 AM';
              DateTime scheduled;
              try {
                scheduled = DateTime.parse('$nextDate $nextTime');
              } catch (_) {
                try {
                  scheduled = DateTime.parse(nextDate.toString());
                } catch (_) {
                  scheduled = DateTime.now().add(const Duration(days: 1));
                }
              }

              cachedList.add(
                FollowUpModel(
                  id: 'flw_lead_${leadMap['id']}',
                  leadId: leadMap['id']?.toString(),
                  userId: effectiveUserId,
                  restaurantName: leadMap['restaurant_name'] ?? leadMap['restaurantName'] ?? 'Restaurant Outlet',
                  contactPerson: leadMap['contact_person_name'] ?? leadMap['contactPersonName'] ?? 'Owner',
                  phone: leadMap['mobile'] ?? '',
                  address: '${leadMap['address'] ?? ''}, ${leadMap['city'] ?? ''}'.trim(),
                  followUpType: leadMap['next_follow_up_type'] ?? leadMap['nextFollowUpType'] ?? 'Restaurant Visit',
                  priority: leadMap['priority'] ?? 'Medium',
                  status: 'PENDING',
                  scheduledTime: scheduled,
                  notes: leadMap['follow_up_notes'] ?? leadMap['followUpNotes'] ?? 'Follow-up scheduled during lead creation',
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    // 4. Calculate dynamic category counts
    int today = 0, upcoming = 0, overdue = 0, completed = 0;
    for (final f in cachedList) {
      if (f.status.toUpperCase() == 'COMPLETED') {
        completed++;
      } else {
        final status = f.computedStatus;
        if (status == FollowUpStatus.today) today++;
        if (status == FollowUpStatus.upcoming) upcoming++;
        if (status == FollowUpStatus.overdue) overdue++;
      }
    }

    return (
      counts: FollowUpCounts(today: today, upcoming: upcoming, overdue: overdue, completed: completed),
      items: cachedList
    );
  }

  /// Creates a new follow-up in the database and updates cache
  Future<FollowUpModel> createFollowUp(Map<String, dynamic> data) async {
    final effectiveUserId = _getCurrentUserId();
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('user_id') && !payload.containsKey('userId')) {
      payload['user_id'] = effectiveUserId;
    }

    FollowUpModel? createdModel;

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.post(
            '$base/api/follow-ups',
            data: payload,
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 || res.statusCode == 201) {
            Environment.activeWorkingBaseUrl = base;
            final decoded = res.data is Map<String, dynamic>
                ? res.data as Map<String, dynamic>
                : json.decode(res.data.toString()) as Map<String, dynamic>;
            final createdData = decoded['data'] as Map<String, dynamic>;
            createdModel = FollowUpModel.fromJson(createdData);
            break;
          }
        } catch (_) {}
      }
    } catch (_) {}

    createdModel ??= FollowUpModel(
      id: 'flw_${DateTime.now().millisecondsSinceEpoch}',
      leadId: payload['lead_id'] ?? payload['leadId'],
      userId: effectiveUserId,
      restaurantName: payload['restaurant_name'] ?? payload['restaurantName'] ?? '',
      contactPerson: payload['contact_person'] ?? payload['contactPerson'] ?? 'Owner',
      phone: payload['phone'] ?? '',
      address: payload['address'] ?? '',
      followUpType: payload['follow_up_type'] ?? payload['followUpType'] ?? 'Restaurant Visit',
      priority: payload['priority'] ?? 'Medium',
      status: payload['status'] ?? 'PENDING',
      scheduledTime: DateTime.tryParse(payload['scheduled_time'] ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      notes: payload['notes'] ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Update cache
    final cacheKey = 'cached_follow_ups_$effectiveUserId';
    try {
      final cached = _hive.get<String>(cacheKey);
      List<FollowUpModel> list = [];
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        list = decoded.map((e) => FollowUpModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      list.insert(0, createdModel);
      await _hive.put(cacheKey, jsonEncode(list.map((i) => i.toJson()).toList()));
    } catch (_) {}

    return createdModel;
  }

  /// Updates an existing follow-up (e.g. status='COMPLETED' or reschedule)
  Future<FollowUpModel> updateFollowUp(String id, Map<String, dynamic> updates) async {
    final effectiveUserId = _getCurrentUserId();
    FollowUpModel? updatedModel;

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.put(
            '$base/api/follow-ups/$id',
            data: updates,
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null) {
            Environment.activeWorkingBaseUrl = base;
            final decoded = res.data is Map<String, dynamic>
                ? res.data as Map<String, dynamic>
                : json.decode(res.data.toString()) as Map<String, dynamic>;
            final updatedData = decoded['data'] as Map<String, dynamic>;
            updatedModel = FollowUpModel.fromJson(updatedData);
            break;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Update cache
    final cacheKey = 'cached_follow_ups_$effectiveUserId';
    try {
      final cached = _hive.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        final list = decoded.map((e) => FollowUpModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final idx = list.findIndex((f) => f.id == id);
        if (idx != -1) {
          if (updates['status'] != null) {
            list[idx] = list[idx].copyWith(status: updates['status']);
          }
          if (updates['scheduled_time'] != null) {
            list[idx] = list[idx].copyWith(
              scheduledTime: DateTime.tryParse(updates['scheduled_time']) ?? list[idx].scheduledTime,
              status: updates['status'] ?? list[idx].status,
            );
          }
          updatedModel ??= list[idx];
          await _hive.put(cacheKey, jsonEncode(list.map((i) => i.toJson()).toList()));
        }
      }
    } catch (_) {}

    return updatedModel ?? FollowUpModel(
      id: id,
      userId: effectiveUserId,
      restaurantName: 'Restaurant',
      contactPerson: 'Owner',
      phone: '',
      address: '',
      followUpType: 'Restaurant Visit',
      priority: 'Medium',
      status: updates['status'] ?? 'PENDING',
      scheduledTime: DateTime.tryParse(updates['scheduled_time'] ?? '') ?? DateTime.now(),
      notes: '',
    );
  }

  /// Deletes a follow-up
  Future<bool> deleteFollowUp(String id) async {
    final effectiveUserId = _getCurrentUserId();
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.delete(
            '$base/api/follow-ups/$id',
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );
          if (res.statusCode == 200) {
            Environment.activeWorkingBaseUrl = base;
            break;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Update cache
    final cacheKey = 'cached_follow_ups_$effectiveUserId';
    try {
      final cached = _hive.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        final list = decoded.map((e) => FollowUpModel.fromJson(Map<String, dynamic>.from(e))).toList();
        list.removeWhere((f) => f.id == id);
        await _hive.put(cacheKey, jsonEncode(list.map((i) => i.toJson()).toList()));
      }
    } catch (_) {}

    return true;
  }
}

extension _ListFindIndex<T> on List<T> {
  int findIndex(bool Function(T element) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }
}
