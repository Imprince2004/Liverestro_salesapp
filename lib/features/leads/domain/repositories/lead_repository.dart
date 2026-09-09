import 'dart:convert';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/pending_request_queue.dart';
import '../../data/models/lead_model.dart';

class LeadRepository {
  static const String _cacheKey = 'cached_leads_v5';
  static const String _draftKey = 'draft_create_lead';

  /// Instant synchronous/fast cache lookup (0ms display)
  List<LeadModel> getCachedLeads() {
    try {
      final hive = getIt<HiveStorageService>();
      final jsonStr = hive.get<String>(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
        return list.where((l) => 
          !l.restaurantName.toLowerCase().contains('urban') && 
          !l.id.startsWith('lead_test_')
        ).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<LeadModel>> getLeads() async {
    List<LeadModel> list = [];
    final api = getIt<ApiClient>();
    final hive = getIt<HiveStorageService>();

    try {
      final response = await api.get('/api/leads');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List<dynamic>;
        list = rawList
            .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
            .where((l) => !l.restaurantName.toLowerCase().contains('urban') && !l.id.startsWith('lead_test_'))
            .toList();
        final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
        await hive.put(_cacheKey, jsonStr);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (_) {
      // Fallback to local Hive cache if API call fails/times out
      list = getCachedLeads();
    }
    return list;
  }

  Future<void> addLead(LeadModel lead) async {
    final api = getIt<ApiClient>();
    final queue = getIt<PendingRequestQueue>();
    final hive = getIt<HiveStorageService>();

    // 1. Optimistic Local Persistence
    final cached = await getLeads();
    final updated = [lead, ...cached.where((e) => e.id != lead.id)];
    await hive.put(_cacheKey, jsonEncode(updated.map((e) => e.toJson()).toList()));

    // 2. Network Sync / Offline Queue
    try {
      final response = await api.post('/api/leads', data: lead.toJson());
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server rejected lead creation');
      }
    } catch (_) {
      // Mark as Pending Sync and enqueue for background synchronization
      await queue.enqueueRequest(
        id: lead.id,
        endpoint: '/api/leads',
        method: 'POST',
        payload: jsonEncode(lead.toJson()),
      );
    }
  }

  /// Checks if a lead with matching mobile or restaurant name already exists to prevent duplicate entries
  Future<LeadModel?> checkDuplicateLead({
    required String mobile,
    required String restaurantName,
  }) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanName = restaurantName.toLowerCase().trim();

    final allLeads = await getLeads();
    for (var lead in allLeads) {
      final leadMobile = lead.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanMobile.isNotEmpty && leadMobile.isNotEmpty && (leadMobile.endsWith(cleanMobile) || cleanMobile.endsWith(leadMobile))) {
        return lead;
      }
      if (cleanName.isNotEmpty && lead.restaurantName.toLowerCase().trim() == cleanName) {
        return lead;
      }
    }
    return null;
  }

  /// Draft management
  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    final hive = getIt<HiveStorageService>();
    await hive.put(_draftKey, jsonEncode(draftData));
  }

  Future<Map<String, dynamic>?> getDraft() async {
    final hive = getIt<HiveStorageService>();
    final raw = hive.get<String>(_draftKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearDraft() async {
    final hive = getIt<HiveStorageService>();
    await hive.delete(_draftKey);
  }
}
