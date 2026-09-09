class RestaurantModel {
  final String id;
  final String name;
  final String ownerName;
  final String mobile;
  final String address;
  final String area;
  final String city;
  final String state;
  final String category; // Cafe, Tea Shop, Dhaba, Restaurant, Fast Food, Cloud Kitchen, Bakery
  final String cuisine;
  final String currentPos; // Petpooja, Posist, Manual Billing, Paper KOT, Vyapar
  final String seatingCapacity; // e.g. 15 Tables (60 Seats), Counter Only
  final double rating;
  final double distanceKm;
  final double outstandingAmount;
  final String lastVisitDate;
  final String status; // Active, Prospect, Lead, Inactive
  final String assignedRep;
  final double latitude;
  final double longitude;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.mobile,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
    this.category = 'Restaurant',
    this.cuisine = 'Multi-Cuisine & Dining',
    this.currentPos = 'Manual Billing',
    this.seatingCapacity = '12 Tables (48 Seats)',
    this.rating = 4.5,
    required this.distanceKm,
    required this.outstandingAmount,
    required this.lastVisitDate,
    required this.status,
    required this.assignedRep,
    required this.latitude,
    required this.longitude,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      category: json['category'] as String? ?? 'Restaurant',
      cuisine: json['cuisine'] as String? ?? 'Multi-Cuisine & Dining',
      currentPos: json['currentPos'] as String? ?? 'Manual Billing',
      seatingCapacity: json['seatingCapacity'] as String? ?? '12 Tables (48 Seats)',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      lastVisitDate: json['lastVisitDate'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      assignedRep: json['assignedRep'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'mobile': mobile,
      'address': address,
      'area': area,
      'city': city,
      'state': state,
      'category': category,
      'cuisine': cuisine,
      'currentPos': currentPos,
      'seatingCapacity': seatingCapacity,
      'rating': rating,
      'distanceKm': distanceKm,
      'outstandingAmount': outstandingAmount,
      'lastVisitDate': lastVisitDate,
      'status': status,
      'assignedRep': assignedRep,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? mobile,
    String? address,
    String? area,
    String? city,
    String? state,
    String? category,
    String? cuisine,
    String? currentPos,
    String? seatingCapacity,
    double? rating,
    double? distanceKm,
    double? outstandingAmount,
    String? lastVisitDate,
    String? status,
    String? assignedRep,
    double? latitude,
    double? longitude,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      currentPos: currentPos ?? this.currentPos,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      rating: rating ?? this.rating,
      distanceKm: distanceKm ?? this.distanceKm,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      status: status ?? this.status,
      assignedRep: assignedRep ?? this.assignedRep,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
