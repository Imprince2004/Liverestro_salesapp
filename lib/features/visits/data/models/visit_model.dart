class VisitModel {
  final String id;
  final String restaurantName;
  final String address;
  final double distanceKm;
  final bool isGeoFenceVerified;
  final bool isAutoCheckedIn;
  final String? photoPath;
  final String notes;
  final Map<String, bool> questionsChecklist;
  final List<String> productsDiscussed;
  final bool demoGiven;
  final String followUpAction;
  final String startTime;
  final String? endTime;
  final String duration;
  final String status; // Scheduled, In-Progress, Completed
  final String? audioUrl;
  final String? transcriptionSummary;

  const VisitModel({
    required this.id,
    required this.restaurantName,
    required this.address,
    required this.distanceKm,
    required this.isGeoFenceVerified,
    required this.isAutoCheckedIn,
    this.photoPath,
    required this.notes,
    required this.questionsChecklist,
    required this.productsDiscussed,
    required this.demoGiven,
    required this.followUpAction,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.status,
    this.audioUrl,
    this.transcriptionSummary,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    // Safely parse nested checklist map
    final rawChecklist = json['questionsChecklist'] as Map<dynamic, dynamic>? ?? {};
    final parsedChecklist = rawChecklist.map((key, value) {
      return MapEntry(key.toString(), value as bool? ?? false);
    });

    // Safely parse products discussed list
    final rawProducts = json['productsDiscussed'] as List<dynamic>? ?? [];
    final parsedProducts = rawProducts.map((p) => p.toString()).toList();

    return VisitModel(
      id: json['id'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? json['restaurant_name'] ?? '',
      address: json['address'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isGeoFenceVerified: json['isGeoFenceVerified'] as bool? ?? json['is_geo_fence_verified'] as bool? ?? false,
      isAutoCheckedIn: json['isAutoCheckedIn'] as bool? ?? json['is_auto_checked_in'] as bool? ?? false,
      photoPath: json['photoPath'] as String? ?? json['photo_path'] as String?,
      notes: json['notes'] as String? ?? '',
      questionsChecklist: parsedChecklist,
      productsDiscussed: parsedProducts,
      demoGiven: json['demoGiven'] as bool? ?? json['demo_given'] as bool? ?? false,
      followUpAction: json['followUpAction'] as String? ?? json['follow_up_action'] as String? ?? '',
      startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '',
      endTime: json['endTime'] as String? ?? json['end_time'] as String?,
      duration: json['duration'] as String? ?? '',
      status: json['status'] as String? ?? 'Scheduled',
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      transcriptionSummary: json['transcriptionSummary'] as String? ?? json['transcription_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'address': address,
      'distanceKm': distanceKm,
      'isGeoFenceVerified': isGeoFenceVerified,
      'isAutoCheckedIn': isAutoCheckedIn,
      'photoPath': photoPath,
      'notes': notes,
      'questionsChecklist': questionsChecklist,
      'productsDiscussed': productsDiscussed,
      'demoGiven': demoGiven,
      'followUpAction': followUpAction,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'status': status,
      'audioUrl': audioUrl,
      'transcriptionSummary': transcriptionSummary,
    };
  }
}
