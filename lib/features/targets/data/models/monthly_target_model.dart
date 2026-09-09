class MonthlyTargetModel {
  final String id;
  final String userId;
  final String userName;
  final int month;
  final String monthName;
  final int year;
  final int targetLeads;
  final int targetVisits;
  final int completedLeads;
  final int remainingLeads;
  final int progressPercent;
  final String assignedById;
  final String assignedByName;
  final String notes;
  final String? userDesignation;
  final String? userTerritory;
  final String? employeeId;
  final String? profilePhoto;

  const MonthlyTargetModel({
    required this.id,
    required this.userId,
    this.userName = 'Sales Executive',
    required this.month,
    required this.monthName,
    required this.year,
    required this.targetLeads,
    this.targetVisits = 50,
    required this.completedLeads,
    required this.remainingLeads,
    required this.progressPercent,
    this.assignedById = '',
    this.assignedByName = 'Sales Manager',
    this.notes = '',
    this.userDesignation,
    this.userTerritory,
    this.employeeId,
    this.profilePhoto,
  });

  factory MonthlyTargetModel.fromJson(Map<String, dynamic> json) {
    final tLeads = json['target_leads'] ?? json['targetLeads'] ?? 20;
    final cLeads = json['completed_leads'] ?? json['completedLeads'] ?? 0;
    final rLeads = json['remaining_leads'] ?? json['remainingLeads'] ?? (tLeads - cLeads > 0 ? tLeads - cLeads : 0);
    final pPercent = json['progress_percent'] ?? json['progressPercent'] ?? (tLeads > 0 ? ((cLeads / tLeads) * 100).round() : 0);

    return MonthlyTargetModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Sales Executive',
      month: json['month'] is int ? json['month'] : int.tryParse(json['month']?.toString() ?? '') ?? DateTime.now().month,
      monthName: json['month_name'] ?? json['monthName'] ?? _getDefaultMonthName(json['month']),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      targetLeads: tLeads is int ? tLeads : int.tryParse(tLeads.toString()) ?? 20,
      targetVisits: json['target_visits'] ?? json['targetVisits'] ?? 50,
      completedLeads: cLeads is int ? cLeads : int.tryParse(cLeads.toString()) ?? 0,
      remainingLeads: rLeads is int ? rLeads : int.tryParse(rLeads.toString()) ?? 0,
      progressPercent: pPercent is int ? pPercent : int.tryParse(pPercent.toString()) ?? 0,
      assignedById: json['assigned_by_id']?.toString() ?? json['assignedById']?.toString() ?? '',
      assignedByName: json['assigned_by_name'] ?? json['assignedByName'] ?? 'Sales Manager',
      notes: json['notes'] ?? '',
      userDesignation: json['user_designation'] ?? json['userDesignation'],
      userTerritory: json['user_territory'] ?? json['userTerritory'],
      employeeId: json['employee_id'] ?? json['employeeId'],
      profilePhoto: json['profile_photo'] ?? json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'month': month,
      'month_name': monthName,
      'year': year,
      'target_leads': targetLeads,
      'target_visits': targetVisits,
      'completed_leads': completedLeads,
      'remaining_leads': remainingLeads,
      'progress_percent': progressPercent,
      'assigned_by_id': assignedById,
      'assigned_by_name': assignedByName,
      'notes': notes,
      'user_designation': userDesignation,
      'user_territory': userTerritory,
      'employee_id': employeeId,
      'profile_photo': profilePhoto,
    };
  }

  static String _getDefaultMonthName(dynamic m) {
    final mNum = int.tryParse(m?.toString() ?? '') ?? DateTime.now().month;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (mNum >= 1 && mNum <= 12) return months[mNum - 1];
    return 'Current Month';
  }
}
