import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/nearby_place.dart';
import '../../data/services/overpass_service.dart';

class NearbyPlacesState {
  final List<NearbyPlace> allPlaces;
  final Position? userPosition;
  final bool isLoading;
  final String? errorMessage;
  final double radiusMeters;
  final String selectedCategory;
  final String searchQuery;
  final NearbyPlace? selectedPlace;
  final bool isPermissionDenied;
  final bool isPermissionPermanentlyDenied;
  final bool isMapView;

  const NearbyPlacesState({
    this.allPlaces = const [],
    this.userPosition,
    this.isLoading = false,
    this.errorMessage,
    this.radiusMeters = 2000,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedPlace,
    this.isPermissionDenied = false,
    this.isPermissionPermanentlyDenied = false,
    this.isMapView = true,
  });

  List<NearbyPlace> get filteredPlaces {
    return allPlaces.where((place) {
      bool matchesCategory = true;
      if (selectedCategory == 'Restaurant') {
        matchesCategory = place.category == 'Restaurant' || place.category == 'Food Place' || place.category == 'Fast Food';
      } else if (selectedCategory == 'Cafe') {
        matchesCategory = place.category == 'Cafe' || place.category == 'Bakery';
      } else if (selectedCategory == 'Dhaba') {
        matchesCategory = place.category == 'Dhaba';
      } else if (selectedCategory == 'Tea Stall') {
        matchesCategory = place.category == 'Tea Stall' || place.category == 'Beverages';
      } else if (selectedCategory != 'All') {
        matchesCategory = place.category.toLowerCase() == selectedCategory.toLowerCase();
      }

      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.category.toLowerCase().contains(query) ||
          (place.address != null && place.address!.toLowerCase().contains(query)) ||
          (place.cuisine != null && place.cuisine!.toLowerCase().contains(query));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  NearbyPlacesState copyWith({
    List<NearbyPlace>? allPlaces,
    Position? userPosition,
    bool? isLoading,
    String? errorMessage,
    double? radiusMeters,
    String? selectedCategory,
    String? searchQuery,
    NearbyPlace? selectedPlace,
    bool clearSelectedPlace = false,
    bool? isPermissionDenied,
    bool? isPermissionPermanentlyDenied,
    bool? isMapView,
  }) {
    return NearbyPlacesState(
      allPlaces: allPlaces ?? this.allPlaces,
      userPosition: userPosition ?? this.userPosition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPlace: clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isPermissionPermanentlyDenied: isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      isMapView: isMapView ?? this.isMapView,
    );
  }
}

class NearbyPlacesNotifier extends StateNotifier<NearbyPlacesState> {
  NearbyPlacesNotifier() : super(const NearbyPlacesState()) {
    init();
  }

  Future<void> init() async {
    await fetchLocationAndPlaces();
  }

  Future<void> fetchLocationAndPlaces({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location services are disabled on your device. Please enable GPS in device settings.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          isLoading: false,
          isPermissionDenied: true,
          errorMessage: 'Location permission was denied. Please grant location access to find nearby restaurants.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          isPermissionPermanentlyDenied: true,
          errorMessage: 'Location permission is permanently denied. Please enable it in App Settings.',
        );
        return;
      }

      // Step 1: Check Last Known Position for instant display
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          final cached = OverpassService.getCachedPlaces(position.latitude, position.longitude);
          if (cached.isNotEmpty) {
            state = state.copyWith(
              userPosition: position,
              allPlaces: cached,
              isLoading: false,
              isPermissionDenied: false,
              isPermissionPermanentlyDenied: false,
            );
          } else {
            state = state.copyWith(
              userPosition: position,
              isPermissionDenied: false,
              isPermissionPermanentlyDenied: false,
            );
          }
        }
      } catch (_) {}

      // Step 2: Fetch Current Precise Position
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {
        position ??= await Geolocator.getLastKnownPosition();
      }

      // If still null, use fallback coordinates for territory
      position ??= Position(
        latitude: 23.0225,
        longitude: 72.5714,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 50.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      // Step 3: Fetch Live Overpass Places around actual user coordinates
      final places = await OverpassService.fetchNearbyFoodPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: state.radiusMeters,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        userPosition: position,
        allPlaces: places,
        isLoading: false,
        isPermissionDenied: false,
        isPermissionPermanentlyDenied: false,
        errorMessage: null,
      );
    } catch (e) {
      final cached = state.allPlaces;
      state = state.copyWith(
        isLoading: false,
        allPlaces: cached,
        errorMessage: cached.isEmpty
            ? 'Failed to load nearby places: ${e.toString().replaceAll('Exception:', '').trim()}'
            : null,
      );
    }
  }

  void setRadius(double newRadius) {
    if (state.radiusMeters != newRadius) {
      state = state.copyWith(radiusMeters: newRadius);
      if (state.userPosition != null) {
        fetchLocationAndPlaces(forceRefresh: true);
      }
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setViewMode(bool isMap) {
    state = state.copyWith(isMapView: isMap);
  }

  void selectPlace(NearbyPlace? place) {
    if (place == null) {
      state = state.copyWith(clearSelectedPlace: true);
    } else {
      state = state.copyWith(selectedPlace: place);
    }
  }
}

final nearbyPlacesProvider = StateNotifierProvider<NearbyPlacesNotifier, NearbyPlacesState>((ref) {
  return NearbyPlacesNotifier();
});
