class PosSoftwareOrderModel {
  final String id;
  final String leadId;
  final String restaurantName;
  final String contactPerson;
  final String contactPhone;
  final String location;
  final String assignedExecutiveId;
  final String assignedExecutiveName;
  final String assignedManagerId;
  final String assignedManagerName;
  final String posType; // 'Free' or 'Paid'
  final double amount;
  final String status;
  final String createdAt;
  final String updatedAt;

  const PosSoftwareOrderModel({
    required this.id,
    required this.leadId,
    required this.restaurantName,
    this.contactPerson = '',
    this.contactPhone = '',
    this.location = '',
    this.assignedExecutiveId = '',
    this.assignedExecutiveName = '',
    this.assignedManagerId = '',
    this.assignedManagerName = '',
    this.posType = 'Free',
    this.amount = 0.0,
    this.status = 'Active',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => posType.toUpperCase() == 'PAID';

  factory PosSoftwareOrderModel.fromJson(Map<String, dynamic> json) {
    final rawPos = (json['pos_type'] ?? json['posType'] ?? 'Free').toString();
    final isPaidType = rawPos.toUpperCase() == 'PAID';
    final parsedAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;

    return PosSoftwareOrderModel(
      id: json['id'] as String? ?? '',
      leadId: json['lead_id'] as String? ?? (json['leadId'] as String? ?? ''),
      restaurantName: json['restaurant_name'] as String? ?? (json['restaurantName'] as String? ?? ''),
      contactPerson: json['contact_person'] as String? ?? (json['contactPerson'] as String? ?? ''),
      contactPhone: json['contact_phone'] as String? ?? (json['contactPhone'] as String? ?? ''),
      location: json['location'] as String? ?? 'Ahmedabad',
      assignedExecutiveId: json['assigned_executive_id'] as String? ?? (json['assignedExecutiveId'] as String? ?? ''),
      assignedExecutiveName: json['assigned_executive_name'] as String? ?? (json['assignedExecutiveName'] as String? ?? 'Kapil Patel'),
      assignedManagerId: json['assigned_manager_id'] as String? ?? (json['assignedManagerId'] as String? ?? ''),
      assignedManagerName: json['assigned_manager_name'] as String? ?? (json['assignedManagerName'] as String? ?? 'Prince Chandarana'),
      posType: isPaidType ? 'Paid' : 'Free',
      amount: isPaidType ? parsedAmount : 0.0,
      status: json['status'] as String? ?? 'Active',
      createdAt: json['created_at'] as String? ?? (json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] as String? ?? (json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'leadId': leadId,
      'restaurant_name': restaurantName,
      'restaurantName': restaurantName,
      'contact_person': contactPerson,
      'contactPerson': contactPerson,
      'contact_phone': contactPhone,
      'contactPhone': contactPhone,
      'location': location,
      'assigned_executive_id': assignedExecutiveId,
      'assignedExecutiveId': assignedExecutiveId,
      'assigned_executive_name': assignedExecutiveName,
      'assignedExecutiveName': assignedExecutiveName,
      'assigned_manager_id': assignedManagerId,
      'assignedManagerId': assignedManagerId,
      'assigned_manager_name': assignedManagerName,
      'assignedManagerName': assignedManagerName,
      'pos_type': posType,
      'posType': posType,
      'amount': amount,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  PosSoftwareOrderModel copyWith({
    String? id,
    String? leadId,
    String? restaurantName,
    String? contactPerson,
    String? contactPhone,
    String? location,
    String? assignedExecutiveId,
    String? assignedExecutiveName,
    String? assignedManagerId,
    String? assignedManagerName,
    String? posType,
    double? amount,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PosSoftwareOrderModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      restaurantName: restaurantName ?? this.restaurantName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      location: location ?? this.location,
      assignedExecutiveId: assignedExecutiveId ?? this.assignedExecutiveId,
      assignedExecutiveName: assignedExecutiveName ?? this.assignedExecutiveName,
      assignedManagerId: assignedManagerId ?? this.assignedManagerId,
      assignedManagerName: assignedManagerName ?? this.assignedManagerName,
      posType: posType ?? this.posType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
