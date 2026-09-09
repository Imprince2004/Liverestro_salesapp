import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/nearby_place.dart';

class OverpassService {
  static final List<String> _overpassEndpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  // In-memory cache for debouncing & avoiding excessive calls
  static double? _lastQueryLat;
  static double? _lastQueryLon;
  static double? _lastQueryRadius;
  static List<NearbyPlace> _cachedPlaces = [];
  static DateTime? _lastFetchTime;

  /// Returns cached places immediately if available
  static List<NearbyPlace> getCachedPlaces(double latitude, double longitude) {
    if (_cachedPlaces.isNotEmpty) {
      for (var p in _cachedPlaces) {
        p.distanceMeters = Geolocator.distanceBetween(
          latitude,
          longitude,
          p.latitude,
          p.longitude,
        );
      }
      _cachedPlaces.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
      return List<NearbyPlace>.from(_cachedPlaces);
    }
    return [];
  }

  /// Fetches nearby food outlets around [latitude, longitude] with a configurable [radiusMeters].
  /// Uses a high-performance multi-engine architecture (Photon OSM Engine + Nominatim + Overpass Fallback).
  static Future<List<NearbyPlace>> fetchNearbyFoodPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 2000,
    bool forceRefresh = false,
  }) async {
    // Check in-memory cache if queried within 3 minutes and within 60m
    if (!forceRefresh &&
        _lastQueryLat != null &&
        _lastQueryLon != null &&
        _lastQueryRadius == radiusMeters &&
        _cachedPlaces.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 3) {
      final movedDistance = Geolocator.distanceBetween(
        _lastQueryLat!,
        _lastQueryLon!,
        latitude,
        longitude,
      );
      if (movedDistance < 60) {
        for (var p in _cachedPlaces) {
          p.distanceMeters = Geolocator.distanceBetween(
            latitude,
            longitude,
            p.latitude,
            p.longitude,
          );
        }
        _cachedPlaces.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
        return _cachedPlaces;
      }
    }

    final Map<String, NearbyPlace> collectedPlaces = {};

    // -------------------------------------------------------------
    // STRATEGY 1: High-Speed Photon OpenStreetMap Live Engine
    // -------------------------------------------------------------
    try {
      final keywords = ['restaurant', 'cafe', 'dhaba', 'tea stall', 'fast food'];
      final futures = keywords.map((k) => _fetchPhotonKeywords(latitude, longitude, k));
      final results = await Future.wait(futures);

      for (final list in results) {
        for (final p in list) {
          p.distanceMeters = Geolocator.distanceBetween(
            latitude,
            longitude,
            p.latitude,
            p.longitude,
          );

          // Filter by radius with slight tolerance
          if (p.distanceMeters! <= (radiusMeters * 1.15)) {
            final dedupeKey = '${p.name.trim().toLowerCase()}_${(p.latitude * 1000).round()}_${(p.longitude * 1000).round()}';
            collectedPlaces[dedupeKey] = p;
          }
        }
      }
    } catch (_) {}

    // -------------------------------------------------------------
    // STRATEGY 2: Overpass QL Multi-Server Failover (if needed)
    // -------------------------------------------------------------
    if (collectedPlaces.length < 5) {
      try {
        final overpassPlaces = await _fetchOverpassDirect(latitude, longitude, radiusMeters);
        for (final p in overpassPlaces) {
          p.distanceMeters = Geolocator.distanceBetween(
            latitude,
            longitude,
            p.latitude,
            p.longitude,
          );
          if (p.distanceMeters! <= (radiusMeters * 1.15)) {
            final dedupeKey = '${p.name.trim().toLowerCase()}_${(p.latitude * 1000).round()}_${(p.longitude * 1000).round()}';
            collectedPlaces.putIfAbsent(dedupeKey, () => p);
          }
        }
      } catch (_) {}
    }

    // -------------------------------------------------------------
    // STRATEGY 3: Nominatim OpenStreetMap POI Fallback (if needed)
    // -------------------------------------------------------------
    if (collectedPlaces.isEmpty) {
      try {
        final nominatimPlaces = await _fetchNominatim(latitude, longitude);
        for (final p in nominatimPlaces) {
          p.distanceMeters = Geolocator.distanceBetween(
            latitude,
            longitude,
            p.latitude,
            p.longitude,
          );
          if (p.distanceMeters! <= (radiusMeters * 1.15)) {
            final dedupeKey = '${p.name.trim().toLowerCase()}_${(p.latitude * 1000).round()}_${(p.longitude * 1000).round()}';
            collectedPlaces.putIfAbsent(dedupeKey, () => p);
          }
        }
      } catch (_) {}
    }

    final List<NearbyPlace> finalPlaces = collectedPlaces.values.toList();

    // Sort by distance (closest first)
    finalPlaces.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));

    if (finalPlaces.isNotEmpty) {
      _lastQueryLat = latitude;
      _lastQueryLon = longitude;
      _lastQueryRadius = radiusMeters;
      _cachedPlaces = finalPlaces;
      _lastFetchTime = DateTime.now();
      return finalPlaces;
    }

    if (_cachedPlaces.isNotEmpty) {
      return _cachedPlaces;
    }

    return [];
  }

  /// Photon API Query
  static Future<List<NearbyPlace>> _fetchPhotonKeywords(double lat, double lon, String query) async {
    final uri = Uri.parse('https://photon.komoot.io/api/?q=$query&lat=$lat&lon=$lon&limit=30');
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'LiveRestroSalesApp/1.0 (FoodDiscovery; OpenStreetMap)',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final features = decoded['features'] as List<dynamic>? ?? [];
      final List<NearbyPlace> list = [];

      for (final item in features) {
        if (item is Map<String, dynamic>) {
          try {
            final place = NearbyPlace.fromPhotonFeature(item);
            if (place.latitude != 0.0 && place.longitude != 0.0) {
              list.add(place);
            }
          } catch (_) {}
        }
      }
      return list;
    }
    return [];
  }

  /// Overpass interpreter Query
  static Future<List<NearbyPlace>> _fetchOverpassDirect(double lat, double lon, double radiusMeters) async {
    final query = '''
[out:json][timeout:6];
(
  node["amenity"~"restaurant|cafe|fast_food"](around:${radiusMeters.round()},$lat,$lon);
  node["shop"~"tea|bakery"](around:${radiusMeters.round()},$lat,$lon);
);
out center 60;
''';

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent': 'LiveRestroSalesApp/1.0',
          },
          body: {'data': query},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final elements = decoded['elements'] as List<dynamic>? ?? [];
          final List<NearbyPlace> places = [];

          for (final item in elements) {
            if (item is Map<String, dynamic>) {
              try {
                final place = NearbyPlace.fromJson(item);
                if (place.latitude != 0.0 && place.longitude != 0.0) {
                  places.add(place);
                }
              } catch (_) {}
            }
          }
          if (places.isNotEmpty) {
            return places;
          }
        }
      } catch (_) {}
    }
    return [];
  }

  /// Nominatim Search Query
  static Future<List<NearbyPlace>> _fetchNominatim(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=restaurant&format=json&lat=$lat&lon=$lon&addressdetails=1&limit=25',
    );
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'LiveRestroSalesApp/1.0 (Contact: dev@liverestro.com)',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>? ?? [];
      final List<NearbyPlace> places = [];

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final itemLat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final itemLon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final name = item['name']?.toString() ?? (item['display_name']?.toString().split(',').first ?? 'Restaurant');
          final address = item['display_name']?.toString();

          if (itemLat != 0.0 && itemLon != 0.0) {
            places.add(
              NearbyPlace(
                id: item['osm_id']?.toString() ?? 'nom_${itemLat}_$itemLon',
                name: name,
                category: 'Restaurant',
                latitude: itemLat,
                longitude: itemLon,
                address: address,
                tags: item,
              ),
            );
          }
        }
      }
      return places;
    }
    return [];
  }

  /// Clears cache
  static void clearCache() {
    _lastQueryLat = null;
    _lastQueryLon = null;
    _lastQueryRadius = null;
    _cachedPlaces = [];
    _lastFetchTime = null;
  }
}
