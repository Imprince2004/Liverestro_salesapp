class AssignableUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String designation;
  final String profilePhoto;
  final String employeeId;
  final String territory;
  final String city;
  final String? managerId;
  final bool isAvailable;
  final String availability;
  final String badgeText;
  final String badgeColor;
  final int activeTasksCount;
  final String? currentActivity;

  const AssignableUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.designation,
    this.profilePhoto = '',
    this.employeeId = 'EMP001',
    this.territory = 'Ahmedabad North',
    this.city = 'Ahmedabad',
    this.managerId,
    this.isAvailable = true,
    this.availability = 'AVAILABLE',
    this.badgeText = 'Available',
    this.badgeColor = '#10B981',
    this.activeTasksCount = 0,
    this.currentActivity,
  });

  factory AssignableUserModel.fromJson(Map<String, dynamic> json) {
    return AssignableUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'SALES_EXECUTIVE',
      designation: json['designation']?.toString() ?? (json['role'] == 'SALES_MANAGER' ? 'Regional Sales Manager' : 'Sales Executive'),
      profilePhoto: json['profile_photo']?.toString() ?? json['profilePhoto']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? 'EMP001',
      territory: json['territory']?.toString() ?? 'Ahmedabad Zone',
      city: json['city']?.toString() ?? 'Ahmedabad',
      managerId: json['manager_id']?.toString() ?? json['managerId']?.toString(),
      isAvailable: json['is_available'] == true || json['availability'] == 'AVAILABLE',
      availability: json['availability']?.toString() ?? 'AVAILABLE',
      badgeText: json['badge_text']?.toString() ?? (json['is_available'] == true ? 'Available' : 'Assigned'),
      badgeColor: json['badge_color']?.toString() ?? (json['is_available'] == true ? '#10B981' : '#F59E0B'),
      activeTasksCount: json['active_tasks_count'] is int ? json['active_tasks_count'] as int : int.tryParse(json['active_tasks_count']?.toString() ?? '0') ?? 0,
      currentActivity: json['current_activity']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'designation': designation,
      'profile_photo': profilePhoto,
      'employee_id': employeeId,
      'territory': territory,
      'city': city,
      'manager_id': managerId,
      'is_available': isAvailable,
      'availability': availability,
      'badge_text': badgeText,
      'badge_color': badgeColor,
      'active_tasks_count': activeTasksCount,
      'current_activity': currentActivity,
    };
  }
}
