import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/utils/logger.dart';

final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});

/// Google Maps service helper placeholders for restaurant location mapping.
class GoogleMapsService {
  Future<void> initialize() async {
    AppLogger.i('🗺️ [GoogleMapsService] Initializing Google Maps API configuration...');
  }

  Marker createRestaurantMarker({
    required String markerId,
    required double latitude,
    required double longitude,
    required String title,
    String? snippet,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(title: title, snippet: snippet),
    );
  }
}
