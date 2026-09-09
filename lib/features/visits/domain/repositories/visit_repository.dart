import 'dart:convert';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/pending_request_queue.dart';
import '../../data/models/visit_model.dart';

class VisitRepository {
  static const String _cacheKey = 'cached_visits';

  final List<VisitModel> _mockVisits = const [
    VisitModel(
      id: 'vst_01',
      restaurantName: 'Spice Junction Fine Dine',
      address: 'Plot 42, Mg Road, Connaught Place',
      distanceKm: 0.05,
      isGeoFenceVerified: true,
      isAutoCheckedIn: true,
      notes: 'Met manager Vikram. Demonstrated Kitchen Display System (KDS).',
      questionsChecklist: {
        'Decision Maker Present?': true,
        'Current POS expiring soon?': true,
        'Hardware required?': false,
      },
      productsDiscussed: ['LiveRestro POS', 'KDS', 'QR Menu'],
      demoGiven: true,
      followUpAction: 'Send commercial quote by tomorrow.',
      startTime: '10:15 AM',
      endTime: '11:00 AM',
      duration: '45 mins',
      status: 'Completed',
    ),
  ];

  Future<List<VisitModel>> getVisits() async {
    List<VisitModel> list = [];
    final api = getIt<ApiClient>();
    final hive = getIt<HiveStorageService>();

    try {
      final response = await api.get('/api/visits');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List<dynamic>;
        list = rawList.map((e) => VisitModel.fromJson(e as Map<String, dynamic>)).toList();
        final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
        await hive.put(_cacheKey, jsonStr);
      } else {
        throw Exception('API error');
      }
    } catch (_) {
      final jsonStr = hive.get<String>(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        list = decoded.map((e) => VisitModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        list = List.from(_mockVisits);
      }
    }
    return list;
  }

  Future<void> addVisit(VisitModel visit) async {
    final api = getIt<ApiClient>();
    final queue = getIt<PendingRequestQueue>();
    final hive = getIt<HiveStorageService>();

    // Update local cache immediately (Optimistic UI update)
    final cached = await getVisits();
    final updated = [visit, ...cached];
    await hive.put(_cacheKey, jsonEncode(updated.map((e) => e.toJson()).toList()));

    try {
      await api.post('/api/visits', data: visit.toJson());
    } catch (_) {
      await queue.enqueueRequest(
        id: visit.id,
        endpoint: '/api/visits',
        method: 'POST',
        payload: jsonEncode(visit.toJson()),
      );
    }
  }
}
