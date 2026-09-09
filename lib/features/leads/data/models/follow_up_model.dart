enum FollowUpStatus { today, upcoming, overdue, completed }

class FollowUpCounts {
  final int today;
  final int upcoming;
  final int overdue;
  final int completed;

  const FollowUpCounts({
    this.today = 0,
    this.upcoming = 0,
    this.overdue = 0,
    this.completed = 0,
  });

  factory FollowUpCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FollowUpCounts();
    return FollowUpCounts(
      today: (json['today'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }
}

class FollowUpModel {
  final String id;
  final String? leadId;
  final String userId;
  final String restaurantName;
  final String contactPerson;
  final String phone;
  final String address;
  final String followUpType;
  final String priority;
  final String status; // 'PENDING', 'COMPLETED', 'CANCELLED'
  final DateTime scheduledTime;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FollowUpModel({
    required this.id,
    this.leadId,
    required this.userId,
    required this.restaurantName,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.followUpType,
    required this.priority,
    required this.status,
    required this.scheduledTime,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  FollowUpStatus get computedStatus {
    if (status.toUpperCase() == 'COMPLETED') {
      return FollowUpStatus.completed;
    }
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (scheduledTime.isBefore(startOfToday)) {
      return FollowUpStatus.overdue;
    } else if (scheduledTime.isAfter(endOfToday)) {
      return FollowUpStatus.upcoming;
    } else {
      return FollowUpStatus.today;
    }
  }

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedScheduledTime;
    try {
      parsedScheduledTime = DateTime.parse(json['scheduled_time'] ?? json['scheduledTime'] ?? DateTime.now().toIso8601String());
    } catch (_) {
      parsedScheduledTime = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    try {
      if (json['created_at'] != null || json['createdAt'] != null) {
        parsedCreatedAt = DateTime.parse(json['created_at'] ?? json['createdAt']);
      }
    } catch (_) {}

    DateTime? parsedUpdatedAt;
    try {
      if (json['updated_at'] != null || json['updatedAt'] != null) {
        parsedUpdatedAt = DateTime.parse(json['updated_at'] ?? json['updatedAt']);
      }
    } catch (_) {}

    return FollowUpModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? json['leadId']?.toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      restaurantName: json['restaurant_name']?.toString() ?? json['restaurantName']?.toString() ?? 'Unnamed Restaurant',
      contactPerson: json['contact_person']?.toString() ?? json['contactPerson']?.toString() ?? 'Owner',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Ahmedabad, Gujarat',
      followUpType: json['follow_up_type']?.toString() ?? json['followUpType']?.toString() ?? json['type']?.toString() ?? 'POS Upgrade & Quotation',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'PENDING',
      scheduledTime: parsedScheduledTime,
      notes: json['notes']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'user_id': userId,
      'restaurant_name': restaurantName,
      'contact_person': contactPerson,
      'phone': phone,
      'address': address,
      'follow_up_type': followUpType,
      'priority': priority,
      'status': status,
      'scheduled_time': scheduledTime.toIso8601String(),
      'notes': notes,
    };
  }

  FollowUpModel copyWith({
    String? id,
    String? leadId,
    String? userId,
    String? restaurantName,
    String? contactPerson,
    String? phone,
    String? address,
    String? followUpType,
    String? priority,
    String? status,
    DateTime? scheduledTime,
    String? notes,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      userId: userId ?? this.userId,
      restaurantName: restaurantName ?? this.restaurantName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      followUpType: followUpType ?? this.followUpType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
