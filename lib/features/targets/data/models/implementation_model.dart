class ImplementationModel {
  final String id;
  final String leadId;
  final String restaurantName;
  final String leadOwnerId;
  final String leadOwnerName;
  final String overallStage; // 'DEMO', 'SOFTWARE_SETUP', 'TRAINING', 'COMPLETED'
  final String overallStatus; // 'IN_PROGRESS', 'COMPLETED', 'ON_HOLD'
  final int progressPercent; // 0 - 100%

  // Stage 1: Demo
  final String demoStatus; // 'NOT_STARTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED'
  final String demoAssignedToId;
  final String demoAssignedToName;
  final String demoAssignedDate;
  final String demoCompletedDate;
  final String demoNotes;

  // Stage 2: Software Setup
  final String setupStatus; // 'NOT_STARTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED'
  final String setupAssignedToId;
  final String setupAssignedToName;
  final String setupAssignedDate;
  final String setupCompletedDate;
  final String setupNotes;

  // Stage 3: Training
  final String trainingStatus; // 'NOT_STARTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED'
  final String trainingAssignedToId;
  final String trainingAssignedToName;
  final String trainingAssignedDate;
  final String trainingCompletedDate;
  final String trainingNotes;

  final String createdAt;
  final String updatedAt;

  const ImplementationModel({
    required this.id,
    this.leadId = '',
    required this.restaurantName,
    this.leadOwnerId = '',
    this.leadOwnerName = 'Sales Executive',
    this.overallStage = 'DEMO',
    this.overallStatus = 'IN_PROGRESS',
    this.progressPercent = 20,
    this.demoStatus = 'NOT_STARTED',
    this.demoAssignedToId = '',
    this.demoAssignedToName = '',
    this.demoAssignedDate = '',
    this.demoCompletedDate = '',
    this.demoNotes = '',
    this.setupStatus = 'NOT_STARTED',
    this.setupAssignedToId = '',
    this.setupAssignedToName = '',
    this.setupAssignedDate = '',
    this.setupCompletedDate = '',
    this.setupNotes = '',
    this.trainingStatus = 'NOT_STARTED',
    this.trainingAssignedToId = '',
    this.trainingAssignedToName = '',
    this.trainingAssignedDate = '',
    this.trainingCompletedDate = '',
    this.trainingNotes = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ImplementationModel.fromJson(Map<String, dynamic> json) {
    return ImplementationModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? json['leadId']?.toString() ?? '',
      restaurantName: json['restaurant_name'] ?? json['restaurantName'] ?? 'Unnamed Restaurant',
      leadOwnerId: json['lead_owner_id']?.toString() ?? json['leadOwnerId']?.toString() ?? '',
      leadOwnerName: json['lead_owner_name'] ?? json['leadOwnerName'] ?? 'Sales Executive',
      overallStage: json['overall_stage'] ?? json['overallStage'] ?? 'DEMO',
      overallStatus: json['overall_status'] ?? json['overallStatus'] ?? 'IN_PROGRESS',
      progressPercent: json['progress_percent'] is int
          ? json['progress_percent']
          : int.tryParse(json['progress_percent']?.toString() ?? '') ??
              (json['progressPercent'] is int
                  ? json['progressPercent']
                  : int.tryParse(json['progressPercent']?.toString() ?? '') ?? 0),
      demoStatus: json['demo_status'] ?? json['demoStatus'] ?? 'NOT_STARTED',
      demoAssignedToId: json['demo_assigned_to_id']?.toString() ?? json['demoAssignedToId']?.toString() ?? '',
      demoAssignedToName: json['demo_assigned_to_name'] ?? json['demoAssignedToName'] ?? '',
      demoAssignedDate: json['demo_assigned_date'] ?? json['demoAssignedDate'] ?? '',
      demoCompletedDate: json['demo_completed_date'] ?? json['demoCompletedDate'] ?? '',
      demoNotes: json['demo_notes'] ?? json['demoNotes'] ?? '',
      setupStatus: json['setup_status'] ?? json['setupStatus'] ?? 'NOT_STARTED',
      setupAssignedToId: json['setup_assigned_to_id']?.toString() ?? json['setupAssignedToId']?.toString() ?? '',
      setupAssignedToName: json['setup_assigned_to_name'] ?? json['setupAssignedToName'] ?? '',
      setupAssignedDate: json['setup_assigned_date'] ?? json['setupAssignedDate'] ?? '',
      setupCompletedDate: json['setup_completed_date'] ?? json['setupCompletedDate'] ?? '',
      setupNotes: json['setup_notes'] ?? json['setupNotes'] ?? '',
      trainingStatus: json['training_status'] ?? json['trainingStatus'] ?? 'NOT_STARTED',
      trainingAssignedToId: json['training_assigned_to_id']?.toString() ?? json['trainingAssignedToId']?.toString() ?? '',
      trainingAssignedToName: json['training_assigned_to_name'] ?? json['trainingAssignedToName'] ?? '',
      trainingAssignedDate: json['training_assigned_date'] ?? json['trainingAssignedDate'] ?? '',
      trainingCompletedDate: json['training_completed_date'] ?? json['trainingCompletedDate'] ?? '',
      trainingNotes: json['training_notes'] ?? json['trainingNotes'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      updatedAt: json['updated_at'] ?? json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'leadId': leadId,
      'restaurant_name': restaurantName,
      'lead_owner_id': leadOwnerId,
      'lead_owner_name': leadOwnerName,
      'overall_stage': overallStage,
      'overall_status': overallStatus,
      'progress_percent': progressPercent,
      'demo_status': demoStatus,
      'demo_assigned_to_id': demoAssignedToId,
      'demo_assigned_to_name': demoAssignedToName,
      'demo_assigned_date': demoAssignedDate,
      'demo_completed_date': demoCompletedDate,
      'demo_notes': demoNotes,
      'setup_status': setupStatus,
      'setup_assigned_to_id': setupAssignedToId,
      'setup_assigned_to_name': setupAssignedToName,
      'setup_assigned_date': setupAssignedDate,
      'setup_completed_date': setupCompletedDate,
      'setup_notes': setupNotes,
      'training_status': trainingStatus,
      'training_assigned_to_id': trainingAssignedToId,
      'training_assigned_to_name': trainingAssignedToName,
      'training_assigned_date': trainingAssignedDate,
      'training_completed_date': trainingCompletedDate,
      'training_notes': trainingNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
