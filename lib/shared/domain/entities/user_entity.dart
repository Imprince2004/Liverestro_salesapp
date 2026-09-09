/// LiveRestro Assigned Sales Manager Summary Entity
class ManagerSummaryEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String profilePhoto;
  final String territory;
  final String? employeeId;
  final String status;

  const ManagerSummaryEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.profilePhoto,
    required this.territory,
    this.employeeId,
    this.status = 'ACTIVE',
  });

  factory ManagerSummaryEntity.fromJson(Map<String, dynamic> json) {
    return ManagerSummaryEntity(
      id: json['id'] ?? json['userId'] ?? '',
      name: json['name'] ?? 'Sales Manager',
      email: json['email'] ?? 'manager@liverestro.com',
      phone: json['phone'] ?? '+91 90000 00003',
      designation: json['designation'] ?? 'Regional Sales Manager',
      profilePhoto: json['profilePhoto'] ?? json['profile_photo'] ?? '',
      territory: json['territory'] ?? 'Gujarat Region Command',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? 'EMP003',
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'designation': designation,
      'profilePhoto': profilePhoto,
      'territory': territory,
      'employeeId': employeeId,
      'status': status,
    };
  }
}

/// LiveRestro User Domain Entity with RBAC, Employee ID, Date of Joining, DOB & Assigned Manager.
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'SUPER_ADMIN', 'COMPANY_ADMIN', 'SALES_MANAGER', 'SALES_EXECUTIVE'
  final bool isPinSet;
  final String? organizationId;
  final String? organizationName;
  final String? managerId;
  final String? territory;
  final String? city;
  final String? token;
  final String employeeId;
  final String dateOfJoining;
  final String? dateOfBirth;
  final String designation;
  final String profilePhoto;
  final String status;
  final int visitsTarget;
  final ManagerSummaryEntity? assignedManager;
  final List<String> permissions;

  final String? address;
  final String? state;
  final String? pincode;
  final String? department;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final String? registeredByUserId;
  final String addedBy;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isPinSet,
    this.organizationId,
    this.organizationName,
    this.managerId,
    this.territory,
    this.city,
    this.token,
    this.employeeId = '',
    this.dateOfJoining = '',
    this.dateOfBirth,
    this.designation = '',
    this.profilePhoto = '',
    this.status = 'ACTIVE',
    this.visitsTarget = 8,
    this.assignedManager,
    this.permissions = const [],
    this.address,
    this.state,
    this.pincode,
    this.department,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.registeredByUserId,
    this.addedBy = 'Not Available',
  });

  bool hasPermission(String permission) {
    if (role == 'SUPER_ADMIN') return true;
    return permissions.contains(permission);
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isPinSet,
    String? organizationId,
    String? organizationName,
    String? managerId,
    String? territory,
    String? city,
    String? token,
    String? employeeId,
    String? dateOfJoining,
    String? dateOfBirth,
    String? designation,
    String? profilePhoto,
    String? status,
    int? visitsTarget,
    ManagerSummaryEntity? assignedManager,
    List<String>? permissions,
    String? address,
    String? state,
    String? pincode,
    String? department,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? registeredByUserId,
    String? addedBy,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isPinSet: isPinSet ?? this.isPinSet,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      managerId: managerId ?? this.managerId,
      territory: territory ?? this.territory,
      city: city ?? this.city,
      token: token ?? this.token,
      employeeId: employeeId ?? this.employeeId,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      designation: designation ?? this.designation,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      status: status ?? this.status,
      visitsTarget: visitsTarget ?? this.visitsTarget,
      assignedManager: assignedManager ?? this.assignedManager,
      permissions: permissions ?? this.permissions,
      address: address ?? this.address,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      department: department ?? this.department,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      registeredByUserId: registeredByUserId ?? this.registeredByUserId,
      addedBy: addedBy ?? this.addedBy,
    );
  }

  factory UserEntity.fromJson(Map<String, dynamic> json, {String? token}) {
    final permissionsRaw = json['permissions'];
    List<String> perms = [];
    if (permissionsRaw is List) {
      perms = permissionsRaw.map((e) => e.toString()).toList();
    }

    ManagerSummaryEntity? manager;
    if (json['assignedManager'] != null && json['assignedManager'] is Map<String, dynamic>) {
      manager = ManagerSummaryEntity.fromJson(json['assignedManager']);
    } else if (json['assigned_manager'] != null && json['assigned_manager'] is Map<String, dynamic>) {
      manager = ManagerSummaryEntity.fromJson(json['assigned_manager']);
    }

    return UserEntity(
      id: json['id'] ?? json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['mobile'] ?? '',
      role: (json['role'] ?? 'SALES_EXECUTIVE').toString().toUpperCase(),
      isPinSet: json['isPinSet'] ?? true,
      organizationId: json['organizationId'] ?? json['organization_id'],
      organizationName: json['organizationName'] ?? json['organization_name'],
      managerId: json['managerId'] ?? json['manager_id'],
      territory: json['territory'],
      city: json['city'],
      token: token ?? json['token'],
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      dateOfJoining: json['dateOfJoining'] ?? json['date_of_joining'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? json['date_of_birth'],
      designation: json['designation'] ?? (json['role'] == 'SALES_MANAGER' ? 'Sales Manager' : (json['role'] == 'SUPER_ADMIN' || json['role'] == 'COMPANY_ADMIN' ? 'Admin' : 'Sales Executive')),
      profilePhoto: json['profilePhoto'] ?? json['profile_photo'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      visitsTarget: json['visitsTarget'] ?? json['visits_target'] ?? 8,
      assignedManager: manager,
      permissions: perms,
      address: json['address'],
      state: json['state'],
      pincode: json['pincode'],
      department: json['department'],
      emergencyContactName: json['emergencyContactName'] ?? json['emergency_contact_name'],
      emergencyContactRelationship: json['emergencyContactRelationship'] ?? json['emergency_contact_relationship'],
      emergencyContactPhone: json['emergencyContactPhone'] ?? json['emergency_contact_phone'],
      registeredByUserId: json['registeredByUserId'] ?? json['registered_by_user_id'],
      addedBy: json['addedBy'] ?? json['added_by'] ?? json['registered_by_name'] ?? 'Not Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isPinSet': isPinSet,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'managerId': managerId,
      'token': token,
      'employeeId': employeeId,
      'dateOfJoining': dateOfJoining,
      'dateOfBirth': dateOfBirth,
      'designation': designation,
      'profilePhoto': profilePhoto,
      'status': status,
      'territory': territory,
      'city': city,
      'visitsTarget': visitsTarget,
      'assignedManager': assignedManager?.toJson(),
      'permissions': permissions,
      'address': address,
      'state': state,
      'pincode': pincode,
      'department': department,
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelationship': emergencyContactRelationship,
      'emergencyContactPhone': emergencyContactPhone,
      'registeredByUserId': registeredByUserId,
      'addedBy': addedBy,
    };
  }
}
