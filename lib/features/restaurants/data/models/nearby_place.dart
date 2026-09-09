class NearbyPlace {
  final String id;
  final String name;
  final String category; // 'Restaurant', 'Cafe', 'Dhaba', 'Tea Stall', 'Fast Food', 'Bakery', 'Food Place'
  final double latitude;
  final double longitude;
  final String? address;
  final String? cuisine;
  final String? phone;
  final String? openingHours;
  final Map<String, dynamic> tags;
  double? distanceMeters;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.cuisine,
    this.phone,
    this.openingHours,
    required this.tags,
    this.distanceMeters,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] != null ? Map<String, dynamic>.from(json['tags'] as Map) : <String, dynamic>{};
    final id = json['id']?.toString() ?? '';

    // Determine coordinates (node has lat/lon directly; way center has center.lat/center.lon)
    double lat = 0.0;
    double lon = 0.0;
    if (json['lat'] != null) {
      lat = (json['lat'] as num).toDouble();
      lon = (json['lon'] as num).toDouble();
    } else if (json['center'] != null) {
      lat = (json['center']['lat'] as num).toDouble();
      lon = (json['center']['lon'] as num).toDouble();
    }

    final amenity = tags['amenity']?.toString().toLowerCase() ?? '';
    final shop = tags['shop']?.toString().toLowerCase() ?? '';
    final cuisineTag = tags['cuisine']?.toString().toLowerCase() ?? '';
    final rawName = tags['name']?.toString() ?? '';
    final lowerName = rawName.toLowerCase();

    // Determine fine-grained category
    String category = 'Restaurant';
    if (lowerName.contains('dhaba') || cuisineTag.contains('dhaba') || tags['dhaba'] == 'yes') {
      category = 'Dhaba';
    } else if (shop == 'tea' || lowerName.contains('tea stall') || lowerName.contains('chai') || lowerName.contains('tea corner')) {
      category = 'Tea Stall';
    } else if (amenity == 'cafe' || lowerName.contains('cafe') || lowerName.contains('coffee')) {
      category = 'Cafe';
    } else if (amenity == 'fast_food' || lowerName.contains('fast food') || lowerName.contains('burger') || lowerName.contains('pizza')) {
      category = 'Fast Food';
    } else if (shop == 'bakery' || amenity == 'bakery') {
      category = 'Bakery';
    } else if (amenity == 'restaurant') {
      category = 'Restaurant';
    } else if (shop == 'beverages') {
      category = 'Beverages';
    } else {
      category = 'Food Place';
    }

    // Determine Display Name
    final displayName = rawName.isNotEmpty ? rawName : 'Unnamed $category';

    // Format address from tags if present
    String? address;
    final street = tags['addr:street']?.toString();
    final houseNumber = tags['addr:housenumber']?.toString();
    final city = tags['addr:city']?.toString() ?? tags['addr:suburb']?.toString();
    if (street != null || city != null) {
      address = [houseNumber, street, city].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return NearbyPlace(
      id: id,
      name: displayName,
      category: category,
      latitude: lat,
      longitude: lon,
      address: address,
      cuisine: tags['cuisine']?.toString(),
      phone: tags['phone']?.toString() ?? tags['contact:phone']?.toString(),
      openingHours: tags['opening_hours']?.toString(),
      tags: tags,
    );
  }

  factory NearbyPlace.fromPhotonFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] != null
        ? Map<String, dynamic>.from(feature['properties'] as Map)
        : <String, dynamic>{};
    final geom = feature['geometry'] != null
        ? Map<String, dynamic>.from(feature['geometry'] as Map)
        : <String, dynamic>{};
    final coords = geom['coordinates'] as List<dynamic>? ?? [0.0, 0.0];

    final lon = coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    final lat = coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;

    final rawName = props['name']?.toString().trim() ?? '';
    final osmValue = props['osm_value']?.toString().toLowerCase() ?? '';
    final lowerName = rawName.toLowerCase();

    // Determine category
    String category = 'Restaurant';
    if (lowerName.contains('dhaba') || osmValue.contains('dhaba')) {
      category = 'Dhaba';
    } else if (osmValue == 'tea' || lowerName.contains('tea stall') || lowerName.contains('chai') || lowerName.contains('tea point')) {
      category = 'Tea Stall';
    } else if (osmValue == 'cafe' || lowerName.contains('cafe') || lowerName.contains('coffee')) {
      category = 'Cafe';
    } else if (osmValue == 'fast_food' || lowerName.contains('fast food') || lowerName.contains('burger') || lowerName.contains('pizza')) {
      category = 'Fast Food';
    } else if (osmValue == 'bakery' || lowerName.contains('bakery') || lowerName.contains('cake')) {
      category = 'Bakery';
    } else if (osmValue == 'restaurant') {
      category = 'Restaurant';
    } else if (osmValue == 'bar' || osmValue == 'pub') {
      category = 'Bar';
    } else {
      category = 'Restaurant';
    }

    final displayName = rawName.isNotEmpty ? rawName : 'Local $category';

    // Format address
    final parts = <String>[];
    if (props['housenumber'] != null && props['housenumber'].toString().isNotEmpty) {
      parts.add(props['housenumber'].toString());
    }
    if (props['street'] != null && props['street'].toString().isNotEmpty) {
      parts.add(props['street'].toString());
    }
    if (props['district'] != null && props['district'].toString().isNotEmpty) {
      parts.add(props['district'].toString());
    } else if (props['locality'] != null && props['locality'].toString().isNotEmpty) {
      parts.add(props['locality'].toString());
    }
    if (props['city'] != null && props['city'].toString().isNotEmpty) {
      parts.add(props['city'].toString());
    } else if (props['county'] != null && props['county'].toString().isNotEmpty) {
      parts.add(props['county'].toString());
    }
    if (props['postcode'] != null && props['postcode'].toString().isNotEmpty) {
      parts.add(props['postcode'].toString());
    }

    final address = parts.isNotEmpty ? parts.join(', ') : (props['state']?.toString() ?? 'Nearby Food Venue');

    return NearbyPlace(
      id: props['osm_id']?.toString() ?? 'osm_${lat}_$lon',
      name: displayName,
      category: category,
      latitude: lat,
      longitude: lon,
      address: address,
      cuisine: props['cuisine']?.toString() ?? (props['type']?.toString()),
      phone: props['phone']?.toString(),
      openingHours: props['opening_hours']?.toString(),
      tags: props,
    );
  }

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    } else {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
  }
}
