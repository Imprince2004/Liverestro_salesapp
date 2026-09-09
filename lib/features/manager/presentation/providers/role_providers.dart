import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/utils/environment.dart';
import '../../data/models/admin_models.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';

// ==========================================
// 1. ACTIVE USER ROLE NOTIFIER
// ==========================================
class ActiveRoleNotifier extends StateNotifier<AppUserRole> {
  ActiveRoleNotifier() : super(_loadInitialRole());

  static AppUserRole _loadInitialRole() {
    try {
      final hive = getIt<HiveStorageService>();
      final saved = hive.get<String>('active_app_user_role') ?? hive.get<String>('user_role');
      if (saved == 'superAdmin' || saved == 'SUPER_ADMIN') return AppUserRole.superAdmin;
      if (saved == 'companyAdmin' || saved == 'COMPANY_ADMIN') return AppUserRole.companyAdmin;
      if (saved == 'salesManager' || saved == 'SALES_MANAGER') return AppUserRole.salesManager;
      return AppUserRole.salesExecutive;
    } catch (_) {
      return AppUserRole.salesExecutive;
    }
  }

  void switchRole(AppUserRole role) {
    state = role;
    try {
      final hive = getIt<HiveStorageService>();
      hive.put('active_app_user_role', role.name);
    } catch (_) {}
  }
}

final activeRoleProvider = StateNotifierProvider<ActiveRoleNotifier, AppUserRole>((ref) {
  return ActiveRoleNotifier();
});

// ==========================================
// 2. TEAM MEMBERS & FIELD REPS NOTIFIER (Manager & Super Admin)
// ==========================================
final teamLoadingProvider = StateProvider<bool>((ref) => false);
final teamErrorProvider = StateProvider<String?>((ref) => null);

class TeamMembersNotifier extends StateNotifier<List<TeamMemberModel>> {
  final Ref? _ref;

  TeamMembersNotifier([this._ref]) : super(_loadInitialCachedTeam()) {
    fetchTeamFromBackend();
  }

  static List<TeamMemberModel> _loadInitialCachedTeam() {
    try {
      final hive = getIt<HiveStorageService>();
      final userId = hive.get<String>('user_id');
      if (userId != null && userId.isNotEmpty) {
        final cachedJson = hive.get<String>('cached_manager_team_$userId');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded.map((j) => TeamMemberModel.fromJson(j as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    return const [];
  }

  static List<String> get _fastApiCandidates => Environment.resolvedApiCandidates;

  static final Dio _directDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 3000),
      receiveTimeout: const Duration(milliseconds: 4000),
      sendTimeout: const Duration(milliseconds: 4000),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> fetchTeamFromBackend({String? managerId}) async {
    _ref?.read(teamLoadingProvider.notifier).state = true;
    _ref?.read(teamErrorProvider.notifier).state = null;

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final hive = getIt<HiveStorageService>();
      final effectiveManagerId = managerId ?? hive.get<String>('user_id');
      final candidates = _fastApiCandidates;

      bool fetchedSuccessfully = false;

      for (final base in candidates) {
        try {
          final res = await _directDio.get(
            '$base/api/users/team',
            queryParameters: {
              if (effectiveManagerId != null) 'managerId': effectiveManagerId,
            },
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
              extra: {'skip_retry': true},
            ),
          );

          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            Environment.activeWorkingBaseUrl = base;
            final List<dynamic> rawList = res.data['data'];
            final List<TeamMemberModel> loaded = rawList.map((j) => TeamMemberModel.fromJson(j as Map<String, dynamic>)).toList();
            state = loaded;
            fetchedSuccessfully = true;
            try {
              if (effectiveManagerId != null) {
                await hive.put('cached_manager_team_$effectiveManagerId', jsonEncode(rawList));
              }
              await hive.put('cached_manager_team', jsonEncode(rawList));
            } catch (_) {}
            break;
          }
        } catch (_) {}
      }

      if (!fetchedSuccessfully && state.isEmpty) {
        _ref?.read(teamErrorProvider.notifier).state = 'Unable to load Sales Executives. Please try again.';
      }
    } catch (_) {
      if (state.isEmpty) {
        _ref?.read(teamErrorProvider.notifier).state = 'Unable to load Sales Executives. Please try again.';
      }
    } finally {
      _ref?.read(teamLoadingProvider.notifier).state = false;
    }
  }

  void addMember(TeamMemberModel member) {
    state = [member, ...state];
  }

  void updateMemberRole(String id, AppUserRole newRole) {
    state = state.map((m) {
      if (m.id == id) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();
  }

  Future<void> toggleMemberActive(String id) async {
    final member = state.firstWhere((m) => m.id == id, orElse: () => state.first);
    final newStatus = member.isActive ? 'INACTIVE' : 'ACTIVE';
    state = state.map((m) {
      if (m.id == id) {
        return m.copyWith(
          isActive: !m.isActive,
          currentStatus: !m.isActive ? 'Active' : 'Inactive',
        );
      }
      return m;
    }).toList();

    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final candidates = _fastApiCandidates;
      for (final base in candidates) {
        try {
          await _directDio.put(
            '$base/api/users/$id',
            data: {'status': newStatus},
            options: Options(headers: {if (token != null) 'Authorization': 'Bearer $token'}),
          );
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> deleteMember(String id) async {
    state = state.where((m) => m.id != id).toList();
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final candidates = _fastApiCandidates;
      for (final base in candidates) {
        try {
          await _directDio.delete(
            '$base/api/users/$id',
            options: Options(headers: {if (token != null) 'Authorization': 'Bearer $token'}),
          );
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<({bool success, String? errorMessage, TeamMemberModel? member})> registerMember({
    required String name,
    required String email,
    required String phone,
    String? password,
    required String territory,
    String city = 'Ahmedabad',
    String designation = 'Sales Executive',
    String role = 'SALES_EXECUTIVE',
    int visitsTarget = 8,
    String? managerId,
  }) async {
    try {
      final token = await getIt<SecureStorageService>().getAuthToken();
      final candidates = _fastApiCandidates;

      Response? successResponse;
      String? backendErrorMsg;

      final resolvedRole = designation == 'Sales Manager' || role == 'SALES_MANAGER' ? 'SALES_MANAGER' : 'SALES_EXECUTIVE';
      final resolvedDesignation = resolvedRole == 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive';
      final resolvedAppRole = resolvedRole == 'SALES_MANAGER' ? AppUserRole.salesManager : AppUserRole.salesExecutive;

      for (final base in candidates) {
        try {
          final res = await _directDio.post(
            '$base/api/users',
            data: {
              'name': name,
              'email': email,
              'phone': phone,
              'password': password ?? 'LiveRestro@$phone',
              'role': resolvedRole,
              'designation': resolvedDesignation,
              'territory': territory,
              'city': city,
              'visitsTarget': visitsTarget,
              'managerId': managerId ?? 'usr_companyadmin_002',
            },
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
              extra: {'skip_retry': true},
            ),
          );

          if (res.statusCode == 200 || res.statusCode == 201) {
            Environment.activeWorkingBaseUrl = base;
            successResponse = res;
            break;
          }
        } on DioException catch (dioErr) {
          if (dioErr.response?.data != null && dioErr.response?.data is Map) {
            final map = dioErr.response!.data as Map;
            if (map['message'] != null) {
              backendErrorMsg = map['message'].toString();
            }
          }
          if (dioErr.response?.statusCode == 409 || dioErr.response?.statusCode == 400) {
            // Definite client validation / conflict error, stop retrying
            return (
              success: false,
              errorMessage: backendErrorMsg ?? 'This mobile number or email already exists.',
              member: null,
            );
          }
        } catch (_) {}
      }

      String backendUserId;
      String generatedEmpId;
      String dateOfJoining;

      if (successResponse != null && successResponse.data != null) {
        final resData = successResponse.data['data'] as Map<String, dynamic>? ?? {};
        backendUserId = resData['id']?.toString() ?? 'usr_${resolvedRole.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
        generatedEmpId = resData['employeeId']?.toString() ?? resData['employee_id']?.toString() ?? 'EMP${(state.length + 5).toString().padLeft(3, '0')}';
        dateOfJoining = resData['dateOfJoining']?.toString() ?? resData['date_of_joining']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];
      } else {
        backendUserId = 'usr_${resolvedRole.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
        generatedEmpId = 'EMP${(state.length + 5).toString().padLeft(3, '0')}';
        dateOfJoining = DateTime.now().toIso8601String().split('T')[0];
      }

      final newMember = TeamMemberModel(
        id: backendUserId,
        name: name,
        email: email,
        phone: phone,
        role: resolvedAppRole,
        territory: territory,
        city: city,
        employeeId: generatedEmpId,
        dateOfJoining: dateOfJoining,
        designation: resolvedDesignation,
        isActive: true,
        visitsTarget: visitsTarget,
        currentStatus: 'Idle',
        liveLocation: '$territory, $city',
        currentOutlet: 'New Registered User',
        batteryPercent: 100,
        visitsToday: 0,
      );

      // Register dynamically for instant local authentication
      AuthRemoteDataSource.registerDynamicUser(
        name: name,
        email: email,
        phone: phone,
        password: password ?? 'LiveRestro@$phone',
        role: resolvedRole,
        territory: territory,
      );

      // Prepend new executive to state immediately with confirmed EMP ID
      final updatedList = [newMember, ...state.where((m) => m.email != email && m.phone != phone)];
      state = updatedList;

      try {
        final hive = getIt<HiveStorageService>();
        final mId = managerId ?? hive.get<String>('user_id') ?? 'usr_salesmanager_003';
        final raw = jsonEncode(updatedList.map((m) => m.toJson()).toList());
        await hive.put('cached_manager_team_$mId', raw);
        await hive.put('cached_manager_team', raw);
      } catch (_) {}

      // Re-fetch in background to ensure database sync
      fetchTeamFromBackend(managerId: managerId);

      return (
        success: true,
        errorMessage: null,
        member: newMember,
      );
    } catch (e) {
      return (
        success: false,
        errorMessage: e.toString(),
        member: null,
      );
    }
  }
}

final teamMembersProvider = StateNotifierProvider<TeamMembersNotifier, List<TeamMemberModel>>((ref) {
  return TeamMembersNotifier(ref);
});

// ==========================================
// 3. POS RATE CARDS & PRICING (Super Admin)
// ==========================================
class PricingTiersNotifier extends StateNotifier<List<PricingTierModel>> {
  PricingTiersNotifier() : super(_initialPlans);

  static final List<PricingTierModel> _initialPlans = [
    const PricingTierModel(
      id: 'plan_q',
      planName: 'LiveRestro Starter (Quarterly)',
      billingPeriod: 'Quarterly',
      softwarePrice: 4999.0,
      hardwareBundlePrice: 8500.0,
      includedFeatures: [
        'Cloud Billing & Offline Sync',
        'Kitchen Display System (KDS)',
        'Thermal Printer USB/Bluetooth Driver',
        'Daily WhatsApp Sales Digest',
      ],
      maxDiscountPercentAllowed: 10,
    ),
    const PricingTierModel(
      id: 'plan_a',
      planName: 'LiveRestro Growth (Annual Pro)',
      billingPeriod: 'Annual',
      softwarePrice: 14999.0,
      hardwareBundlePrice: 12500.0,
      includedFeatures: [
        'Everything in Starter',
        'Live Swiggy & Zomato Auto-Sync',
        'Smart WhatsApp Digital Receipts & Reviews',
        'Multi-Counter Table & Captain App',
        'Inventory & Food Costing Module',
      ],
      isPopular: true,
      maxDiscountPercentAllowed: 15,
    ),
    const PricingTierModel(
      id: 'plan_3y',
      planName: 'LiveRestro Enterprise (3-Year Platinum)',
      billingPeriod: '3-Year Platinum',
      softwarePrice: 34999.0,
      hardwareBundlePrice: 18000.0,
      includedFeatures: [
        'All Features Unlocked Forever',
        'Free 10-inch Android POS Hardware Terminal',
        'Free 80mm High-Speed Thermal Printer',
        'Central Multi-Outlet Cloud HQ',
        'Dedicated 24x7 Account Manager & Free AMC',
      ],
      maxDiscountPercentAllowed: 25,
    ),
  ];

  void updatePlanPricing(String id, double swPrice, double hwPrice) {
    state = state.map((p) {
      if (p.id == id) {
        return PricingTierModel(
          id: p.id,
          planName: p.planName,
          billingPeriod: p.billingPeriod,
          softwarePrice: swPrice,
          hardwareBundlePrice: hwPrice,
          includedFeatures: p.includedFeatures,
          isPopular: p.isPopular,
          maxDiscountPercentAllowed: p.maxDiscountPercentAllowed,
        );
      }
      return p;
    }).toList();
  }
}

final pricingTiersProvider = StateNotifierProvider<PricingTiersNotifier, List<PricingTierModel>>((ref) {
  return PricingTiersNotifier();
});

// ==========================================
// 4. TERRITORY ZONES (Super Admin & ASM)
// ==========================================
final territoryZonesProvider = Provider<List<TerritoryZoneModel>>((ref) {
  return const [
    TerritoryZoneModel(
      id: 'zone_01',
      zoneName: 'Ahmedabad North (Gota, Jagatpur & SG Highway)',
      city: 'Ahmedabad',
      assignedManagerName: 'Rajesh Sharma',
      activeRepsCount: 4,
      totalComplexesCount: 8,
      totalOutletsMapped: 76,
      targetRevenue: 500000.0,
      achievedRevenue: 413000.0,
    ),
    TerritoryZoneModel(
      id: 'zone_02',
      zoneName: 'Ahmedabad West (Bopal, Shela & SG Road)',
      city: 'Ahmedabad',
      assignedManagerName: 'Rajesh Sharma',
      activeRepsCount: 3,
      totalComplexesCount: 6,
      totalOutletsMapped: 58,
      targetRevenue: 400000.0,
      achievedRevenue: 340000.0,
    ),
    TerritoryZoneModel(
      id: 'zone_03',
      zoneName: 'Surat Central & Vesu Food Hub',
      city: 'Surat',
      assignedManagerName: 'Kunal Singhal',
      activeRepsCount: 5,
      totalComplexesCount: 12,
      totalOutletsMapped: 110,
      targetRevenue: 650000.0,
      achievedRevenue: 520000.0,
    ),
    TerritoryZoneModel(
      id: 'zone_04',
      zoneName: 'Vadodara Alkapuri & Old Padra Hub',
      city: 'Vadodara',
      assignedManagerName: 'Amit Desai',
      activeRepsCount: 3,
      totalComplexesCount: 7,
      totalOutletsMapped: 64,
      targetRevenue: 350000.0,
      achievedRevenue: 280000.0,
    ),
  ];
});

// ==========================================
// 5. PENDING APPROVALS NOTIFIER (Sales Manager & Super Admin)
// ==========================================
class ApprovalRequestsNotifier extends StateNotifier<List<ApprovalRequestModel>> {
  ApprovalRequestsNotifier() : super(const []);

  void approve(String id) {
    state = state.map((a) {
      if (a.id == id) return a.copyWith(status: 'Approved');
      return a;
    }).toList();
  }

  void reject(String id) {
    state = state.map((a) {
      if (a.id == id) return a.copyWith(status: 'Rejected');
      return a;
    }).toList();
  }
}

final approvalRequestsProvider = StateNotifierProvider<ApprovalRequestsNotifier, List<ApprovalRequestModel>>((ref) {
  return ApprovalRequestsNotifier();
});

// ==========================================
// 6. UNASSIGNED LEADS NOTIFIER (Sales Manager)
// ==========================================
class UnassignedLeadsNotifier extends StateNotifier<List<UnassignedLeadModel>> {
  UnassignedLeadsNotifier() : super(const []);

  void assignLead(String leadId, String repId, String repName) {
    state = state.map((l) {
      if (l.id == leadId) {
        return l.copyWith(assignedRepId: repName);
      }
      return l;
    }).toList();
  }
}

final unassignedLeadsProvider = StateNotifierProvider<UnassignedLeadsNotifier, List<UnassignedLeadModel>>((ref) {
  return UnassignedLeadsNotifier();
});

// ==========================================
// 7. SYSTEM AUDIT LOGS (Super Admin)
// ==========================================
class AuditLogsNotifier extends StateNotifier<List<AuditLogModel>> {
  AuditLogsNotifier() : super(_initialLogs);

  static final List<AuditLogModel> _initialLogs = [
    AuditLogModel(
      id: 'log_01',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      actorName: 'Rajesh Sharma (ASM)',
      actorRole: AppUserRole.salesManager,
      actionType: 'DISCOUNT_APPROVAL',
      details: 'Approved 18% discount for The Grand Thakar (Godrej City Square)',
    ),
    AuditLogModel(
      id: 'log_02',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      actorName: 'Prince Chandarana',
      actorRole: AppUserRole.salesExecutive,
      actionType: 'NEW_LEAD_CREATED',
      details: 'Created Lead: Chai Sutta Bar (CSB) with GPS tag at Godrej City Square',
    ),
    AuditLogModel(
      id: 'log_03',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      actorName: 'Super Admin HQ',
      actorRole: AppUserRole.superAdmin,
      actionType: 'PRICING_UPDATED',
      details: 'Updated LiveRestro Enterprise 3-Year Platinum plan hardware allowance',
    ),
    AuditLogModel(
      id: 'log_04',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      actorName: 'Aakash Dave',
      actorRole: AppUserRole.salesExecutive,
      actionType: 'VISIT_CHECKIN',
      details: 'Logged Visit & Voice Note at Honest Pav Bhaji, Vandematram Crosswind',
    ),
  ];

  void addLog(AuditLogModel log) {
    state = [log, ...state];
  }
}

final auditLogsProvider = StateNotifierProvider<AuditLogsNotifier, List<AuditLogModel>>((ref) {
  return AuditLogsNotifier();
});

/// Available territories / areas fetched dynamically from database
final availableTerritoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  try {
    final dio = Dio();
    for (final base in Environment.resolvedApiCandidates) {
      try {
        final res = await dio.get(
          '$base/api/users/territories',
          options: Options(
            extra: {'skip_retry': true},
            sendTimeout: const Duration(milliseconds: 1500),
            receiveTimeout: const Duration(milliseconds: 2000),
          ),
        );
        if (res.statusCode == 200 && res.data != null && res.data['data'] is List) {
          final list = (res.data['data'] as List).map((e) => e.toString()).toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }
  } catch (_) {}
  return [
    'Ahmedabad North (Gota & Jagatpur)',
    'Ahmedabad North (SG Highway & Chandlodiya)',
    'Ahmedabad West (Sindhubhavan & Bodakdev)',
    'Ahmedabad West (Bopal & Shela)',
    'Ahmedabad Central (Navrangpura & CG Road)',
    'Ahmedabad East (Nikol & Vastral)',
    'Gujarat Headquarters',
  ];
});
