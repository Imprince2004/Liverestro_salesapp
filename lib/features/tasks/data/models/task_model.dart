class TaskModel {
  final String id;
  final String organizationId;
  final String managerId;
  final String managerName;
  final String assignedToId;
  final String assignedToName;
  final String title;
  final String description;
  final String taskType;
  final String priority;
  final String status;
  final String restaurantName;
  final String location;
  final double? latitude;
  final double? longitude;
  final String dueDate;
  final String notes;
  final String createdAt;

  const TaskModel({
    required this.id,
    required this.organizationId,
    required this.managerId,
    required this.managerName,
    required this.assignedToId,
    required this.assignedToName,
    required this.title,
    required this.description,
    required this.taskType,
    required this.priority,
    required this.status,
    required this.restaurantName,
    required this.location,
    this.latitude,
    this.longitude,
    required this.dueDate,
    required this.notes,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? 'org_demo_001',
      managerId: json['manager_id']?.toString() ?? 'usr_salesmanager_003',
      managerName: json['manager_name']?.toString() ?? 'Sales Manager Demo',
      assignedToId: json['assigned_to_id']?.toString() ?? '',
      assignedToName: json['assigned_to_name']?.toString() ?? 'Sales Executive',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      taskType: json['task_type']?.toString() ?? 'RESTAURANT_VISIT',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'PENDING',
      restaurantName: json['restaurant_name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      dueDate: json['due_date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'manager_id': managerId,
      'manager_name': managerName,
      'assigned_to_id': assignedToId,
      'assigned_to_name': assignedToName,
      'title': title,
      'description': description,
      'task_type': taskType,
      'priority': priority,
      'status': status,
      'restaurant_name': restaurantName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'due_date': dueDate,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  TaskModel copyWith({
    String? status,
    String? notes,
  }) {
    return TaskModel(
      id: id,
      organizationId: organizationId,
      managerId: managerId,
      managerName: managerName,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      title: title,
      description: description,
      taskType: taskType,
      priority: priority,
      status: status ?? this.status,
      restaurantName: restaurantName,
      location: location,
      latitude: latitude,
      longitude: longitude,
      dueDate: dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
