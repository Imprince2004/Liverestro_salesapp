class PinResetRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String employeeId;
  final String designation;
  final String phone;
  final String role;
  final String status;
  final String requestedAt;
  final String? approvedAt;
  final String? approvedBy;
  final String? approvedByName;
  final String? completedAt;
  final String? notes;

  const PinResetRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.employeeId,
    required this.designation,
    required this.phone,
    required this.role,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    this.completedAt,
    this.notes,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory PinResetRequestModel.fromJson(Map<String, dynamic> json) {
    return PinResetRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? 'Team Member',
      employeeId: json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? 'EMP001',
      designation: json['designation']?.toString() ?? 'Sales Executive',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'SALES_EXECUTIVE',
      status: json['status']?.toString() ?? 'PENDING',
      requestedAt: json['requested_at']?.toString() ?? json['requestedAt']?.toString() ?? '',
      approvedAt: json['approved_at']?.toString() ?? json['approvedAt']?.toString(),
      approvedBy: json['approved_by']?.toString() ?? json['approvedBy']?.toString(),
      approvedByName: json['approved_by_name']?.toString() ?? json['approvedByName']?.toString(),
      completedAt: json['completed_at']?.toString() ?? json['completedAt']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'employee_id': employeeId,
      'designation': designation,
      'phone': phone,
      'role': role,
      'status': status,
      'requested_at': requestedAt,
      'approved_at': approvedAt,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'completed_at': completedAt,
      'notes': notes,
    };
  }
}
