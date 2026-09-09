import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/environment.dart';
import '../models/monthly_target_model.dart';
import '../models/implementation_model.dart';

class TargetRemoteDataSource {
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

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 2000),
      receiveTimeout: const Duration(milliseconds: 3000),
      sendTimeout: const Duration(milliseconds: 3000),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Fetch monthly target for a specific user and month/year
  static Future<MonthlyTargetModel> fetchMyTarget({
    String? userId,
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;
    final effectiveUserId = userId ?? getIt<HiveStorageService>().get<String>('user_id') ?? 'usr_demo';

    final cacheKey = 'cached_my_target_${effectiveUserId}_${targetMonth}_$targetYear';
    final hive = getIt<HiveStorageService>();

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.get(
            '$base/api/targets/my-target',
            queryParameters: {
              'user_id': effectiveUserId,
              'month': targetMonth,
              'year': targetYear,
            },
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            Environment.activeWorkingBaseUrl = base;
            final model = MonthlyTargetModel.fromJson(Map<String, dynamic>.from(res.data['data']));
            await hive.put(cacheKey, jsonEncode(model.toJson()));
            return model;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Offline / Cached fallback
    final cached = hive.get<String>(cacheKey);
    if (cached != null) {
      try {
        return MonthlyTargetModel.fromJson(jsonDecode(cached));
      } catch (_) {}
    }

    // Dynamic calculation from real database leads in storage
    int localCompletedLeads = 0;
    try {
      final rawLeads = hive.get<String>('cached_leads_v4');
      if (rawLeads != null) {
        final List<dynamic> list = jsonDecode(rawLeads);
        localCompletedLeads = list.where((item) {
          try {
            final dStr = item['created_at'] ?? item['createdAt'];
            if (dStr == null) return true;
            final d = DateTime.tryParse(dStr.toString());
            if (d == null) return true;
            return d.month == targetMonth && d.year == targetYear;
          } catch (_) {
            return true;
          }
        }).length;
      }
    } catch (_) {}

    const dynamicTargetLeads = 20;
    final dynamicProgress = dynamicTargetLeads > 0
        ? ((localCompletedLeads / dynamicTargetLeads) * 100).round().clamp(0, 100)
        : 0;
    final dynamicRemaining = dynamicTargetLeads - localCompletedLeads > 0
        ? dynamicTargetLeads - localCompletedLeads
        : 0;

    return MonthlyTargetModel(
      id: 'tgt_${effectiveUserId}_${targetMonth}_$targetYear',
      userId: effectiveUserId,
      month: targetMonth,
      monthName: _getMonthName(targetMonth),
      year: targetYear,
      targetLeads: dynamicTargetLeads,
      completedLeads: localCompletedLeads,
      remainingLeads: dynamicRemaining,
      progressPercent: dynamicProgress,
      assignedByName: 'Sales Manager',
    );
  }

  /// Fetch team targets (Admin / Sales Manager view)
  static Future<List<MonthlyTargetModel>> fetchTeamTargets({
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final cacheKey = 'cached_team_targets_${targetMonth}_$targetYear';
    final hive = getIt<HiveStorageService>();

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.get(
            '$base/api/targets/team',
            queryParameters: {
              'month': targetMonth,
              'year': targetYear,
            },
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] is List) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> list = res.data['data'];
            final models = list.map((e) => MonthlyTargetModel.fromJson(Map<String, dynamic>.from(e))).toList();
            await hive.put(cacheKey, jsonEncode(models.map((m) => m.toJson()).toList()));
            return models;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Offline fallback
    final cached = hive.get<String>(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => MonthlyTargetModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return [];
  }

  /// Assign or update target for a sales executive
  static Future<MonthlyTargetModel> assignTarget({
    required String userId,
    required int targetLeads,
    int? month,
    int? year,
    int? targetVisits,
    String? notes,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final token = await getIt<SecureStorageService>().getAuthToken();
    for (final base in _fastApiCandidates) {
      try {
        final res = await _dio.post(
          '$base/api/targets/assign',
          data: {
            'user_id': userId,
            'month': targetMonth,
            'year': targetYear,
            'target_leads': targetLeads,
            'target_visits': targetVisits ?? 50,
            'notes': notes ?? '',
          },
          options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );

        if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
          Environment.activeWorkingBaseUrl = base;
          final model = MonthlyTargetModel.fromJson(Map<String, dynamic>.from(res.data['data']));
          final hive = getIt<HiveStorageService>();
          await hive.put('cached_my_target_${userId}_${targetMonth}_$targetYear', jsonEncode(model.toJson()));
          return model;
        }
      } catch (_) {}
    }

    return fetchMyTarget(userId: userId, month: targetMonth, year: targetYear);
  }

  /// Fetch implementation tasks relevant to logged-in user
  static Future<List<ImplementationModel>> fetchMyImplementationTasks() async {
    const cacheKey = 'cached_my_implementations_v1';
    final hive = getIt<HiveStorageService>();

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.get(
            '$base/api/implementations/my-tasks',
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] is List) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> list = res.data['data'];
            final models = list.map((e) => ImplementationModel.fromJson(Map<String, dynamic>.from(e))).toList();
            await hive.put(cacheKey, jsonEncode(models.map((m) => m.toJson()).toList()));
            return models;
          }
        } catch (_) {}
      }
    } catch (_) {}

    final cached = hive.get<String>(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => ImplementationModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return [];
  }

  /// Fetch all restaurant implementations for Admin / Sales Manager
  static Future<List<ImplementationModel>> fetchAllImplementations({
    String? stage,
    String? status,
    String? search,
  }) async {
    const cacheKey = 'cached_all_implementations_v1';
    final hive = getIt<HiveStorageService>();

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      for (final base in _fastApiCandidates) {
        try {
          final res = await _dio.get(
            '$base/api/implementations/all',
            queryParameters: {
              if (stage != null && stage != 'ALL') 'stage': stage,
              if (status != null && status != 'ALL') 'status': status,
              if (search != null && search.isNotEmpty) 'search': search,
            },
            options: Options(
              headers: {if (token != null) 'Authorization': 'Bearer $token'},
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] is List) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> list = res.data['data'];
            final models = list.map((e) => ImplementationModel.fromJson(Map<String, dynamic>.from(e))).toList();
            await hive.put(cacheKey, jsonEncode(models.map((m) => m.toJson()).toList()));
            return models;
          }
        } catch (_) {}
      }
    } catch (_) {}

    final cached = hive.get<String>(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => ImplementationModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return [];
  }

  /// Assign responsible person for Demo, Software Setup, or Training stage
  static Future<ImplementationModel?> assignStage({
    required String id,
    required String stage,
    required String assignedToId,
    String? assignedToName,
    String? assignedDate,
    String? notes,
  }) async {
    final token = await getIt<SecureStorageService>().getAuthToken();
    for (final base in _fastApiCandidates) {
      try {
        final res = await _dio.put(
          '$base/api/implementations/$id/assign-stage',
          data: {
            'stage': stage,
            'assigned_to_id': assignedToId,
            'assigned_to_name': assignedToName ?? '',
            'assigned_date': assignedDate ?? DateTime.now().toIso8601String().split('T')[0],
            'notes': notes ?? '',
          },
          options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );

        if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
          Environment.activeWorkingBaseUrl = base;
          return ImplementationModel.fromJson(Map<String, dynamic>.from(res.data['data']));
        }
      } catch (_) {}
    }
    return null;
  }

  /// Update stage status (NOT_STARTED, ASSIGNED, IN_PROGRESS, COMPLETED)
  static Future<ImplementationModel?> updateStageStatus({
    required String id,
    required String stage,
    required String status,
    String? completedDate,
    String? notes,
  }) async {
    final token = await getIt<SecureStorageService>().getAuthToken();
    for (final base in _fastApiCandidates) {
      try {
        final res = await _dio.put(
          '$base/api/implementations/$id/update-stage-status',
          data: {
            'stage': stage,
            'status': status,
            'completed_date': completedDate ?? DateTime.now().toIso8601String().split('T')[0],
            'notes': notes ?? '',
          },
          options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );

        if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
          Environment.activeWorkingBaseUrl = base;
          return ImplementationModel.fromJson(Map<String, dynamic>.from(res.data['data']));
        }
      } catch (_) {}
    }
    return null;
  }

  static String _getMonthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return 'Current Month';
  }
}
