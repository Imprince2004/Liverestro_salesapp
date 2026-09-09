import 'dart:convert';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/pending_request_queue.dart';
import '../../data/models/restaurant_model.dart';
import '../../data/services/google_places_service.dart';

class RestaurantRepository {
  static const String _cacheKey = 'cached_restaurants_v4';

  Future<List<RestaurantModel>> getRestaurants({
    String? query,
    String? area,
    String? city,
    String? state,
    String? status,
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    List<RestaurantModel> list = [];
    final api = getIt<ApiClient>();
    final hive = getIt<HiveStorageService>();

    try {
      final response = await api.get('/api/leads');
      if (response.statusCode == 200 && response.data != null && response.data['data'] is List) {
        final rawList = response.data['data'] as List<dynamic>;
        list = rawList.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return RestaurantModel(
            id: m['id']?.toString() ?? '',
            name: m['restaurant_name'] ?? m['restaurantName'] ?? '',
            ownerName: m['owner_name'] ?? m['ownerName'] ?? '',
            mobile: m['mobile'] ?? m['phone'] ?? '',
            address: m['address'] ?? '',
            area: m['area'] ?? '',
            city: m['city'] ?? 'Ahmedabad',
            state: 'Gujarat',
            category: m['business_type'] ?? 'Restaurant',
            cuisine: m['cuisine'] ?? 'Food & Dining',
            currentPos: m['current_pos'] ?? m['currentPos'] ?? '',
            seatingCapacity: '${m['seating_capacity'] ?? 20} Seats',
            rating: 4.6,
            distanceKm: 0.0,
            outstandingAmount: 0.0,
            lastVisitDate: '',
            status: m['status'] ?? 'Active',
            assignedRep: m['assigned_salesperson'] ?? '',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 23.1118,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 72.5442,
          );
        }).where((r) => r.name.isNotEmpty).toList();

        if (list.isNotEmpty) {
          final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
          await hive.put(_cacheKey, jsonStr);
        }
      }
    } catch (_) {}

    if (list.isEmpty) {
      final jsonStr = hive.get<String>(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(jsonStr);
          list = decoded.map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    if (list.isEmpty) {
      final lat = latitude ?? 23.1118;
      final lon = longitude ?? 72.5442;
      list = await GooglePlacesService.fetchNearbyOutlets(
        latitude: lat,
        longitude: lon,
        category: category ?? 'All',
        searchQuery: query ?? '',
      );
    }

    return list.where((rst) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final match = rst.name.toLowerCase().contains(q) ||
            rst.ownerName.toLowerCase().contains(q) ||
            rst.address.toLowerCase().contains(q) ||
            rst.category.toLowerCase().contains(q) ||
            rst.cuisine.toLowerCase().contains(q) ||
            rst.area.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (category != null && category.isNotEmpty && category != 'All' && rst.category != category) {
        return false;
      }
      if (area != null && area.isNotEmpty && rst.area != area) return false;
      if (city != null && city.isNotEmpty && rst.city != city) return false;
      if (state != null && state.isNotEmpty && rst.state != state) return false;
      if (status != null && status.isNotEmpty && status != 'All' && rst.status != status) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> addRestaurant(RestaurantModel restaurant) async {
    final api = getIt<ApiClient>();
    final queue = getIt<PendingRequestQueue>();
    final hive = getIt<HiveStorageService>();

    final cached = await getRestaurants();
    final updated = [restaurant, ...cached];
    await hive.put(_cacheKey, jsonEncode(updated.map((e) => e.toJson()).toList()));

    try {
      await api.post('/api/restaurants', data: restaurant.toJson());
    } catch (_) {
      await queue.enqueueRequest(
        id: restaurant.id,
        endpoint: '/api/restaurants',
        method: 'POST',
        payload: jsonEncode(restaurant.toJson()),
      );
    }
  }
}
