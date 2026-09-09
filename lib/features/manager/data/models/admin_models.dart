import 'package:flutter/material.dart';

/// The core roles for LiveRestro Sales CRM
enum AppUserRole {
  superAdmin,
  companyAdmin,
  salesManager,
  salesExecutive;

  String get displayName {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Super Admin';
      case AppUserRole.companyAdmin:
        return 'Company / Admin';
      case AppUserRole.salesManager:
        return 'Sales Manager';
      case AppUserRole.salesExecutive:
        return 'Sales Executive';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AppUserRole.superAdmin:
        return '👑 Super Admin';
      case AppUserRole.companyAdmin:
        return '🏢 Company Admin';
      case AppUserRole.salesManager:
        return '🎖️ Sales Manager';
      case AppUserRole.salesExecutive:
        return '🏃 Sales Executive';
    }
  }

  String get description {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Full system access';
      case AppUserRole.companyAdmin:
        return 'Manage organization';
      case AppUserRole.salesManager:
        return 'Manage team & reports';
      case AppUserRole.salesExecutive:
        return 'Leads, visits & follow-ups';
    }
  }

  Color get color {
    switch (this) {
      case AppUserRole.superAdmin:
        return const Color(0xFF5B4DDB); // Purple / Indigo
      case AppUserRole.companyAdmin:
        return const Color(0xFF10B981); // Emerald Green
      case AppUserRole.salesManager:
        return const Color(0xFFF97316); // Orange
      case AppUserRole.salesExecutive:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserRole.superAdmin:
        return Icons.security_rounded;
      case AppUserRole.companyAdmin:
        return Icons.business_rounded;
      case AppUserRole.salesManager:
        return Icons.groups_rounded;
      case AppUserRole.salesExecutive:
        return Icons.person_rounded;
    }
  }
}

/// Team member model for User & RBAC management
class TeamMemberModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AppUserRole role;
  final String territory;
  final String city;
  final bool isActive;
  final String avatarUrl;
  final String employeeId;
  final String dateOfJoining;
  final String designation;
  final int activeLeadsCount;
  final int closedDealsCount;
  final double totalRevenueGenerated;
  final String currentStatus; // 'On Visit', 'Traveling', 'Idle', 'Checked Out'
  final String currentOutlet;
  final String liveLocation;
  final int batteryPercent;
  final int visitsToday;
  final int visitsTarget;
  final double distanceTraveledKm;
  final String? registeredByUserId;
  final String addedBy;

  const TeamMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.territory,
    required this.city,
    this.isActive = true,
    this.avatarUrl = '',
    this.employeeId = 'EMP004',
    this.dateOfJoining = '15 Feb 2024',
    this.designation = 'Sales Executive',
    this.activeLeadsCount = 0,
    this.closedDealsCount = 0,
    this.totalRevenueGenerated = 0.0,
    this.currentStatus = 'Idle',
    this.currentOutlet = 'None',
    this.liveLocation = 'Ahmedabad',
    this.batteryPercent = 85,
    this.visitsToday = 0,
    this.visitsTarget = 8,
    this.distanceTraveledKm = 0.0,
    this.registeredByUserId,
    this.addedBy = 'Not Available',
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    AppUserRole role = AppUserRole.salesExecutive;
    final roleStr = (json['role'] ?? '').toString().toUpperCase();
    if (roleStr == 'SUPER_ADMIN') {
      role = AppUserRole.superAdmin;
    } else if (roleStr == 'COMPANY_ADMIN') {
      role = AppUserRole.companyAdmin;
    } else if (roleStr == 'SALES_MANAGER') {
      role = AppUserRole.salesManager;
    }

    return TeamMemberModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Executive',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: role,
      territory: json['territory'] ?? 'Ahmedabad North',
      city: json['city'] ?? 'Ahmedabad',
      isActive: (json['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE',
      avatarUrl: json['profile_photo'] ?? json['profilePhoto'] ?? '',
      employeeId: json['employee_id'] ?? json['employeeId'] ?? 'EMP004',
      dateOfJoining: json['date_of_joining'] ?? json['dateOfJoining'] ?? '2024-02-15',
      designation: json['designation'] ?? (role == AppUserRole.salesManager ? 'Sales Manager' : 'Sales Executive'),
      activeLeadsCount: json['active_leads_count'] ?? json['activeLeadsCount'] ?? 0,
      closedDealsCount: json['closed_deals_count'] ?? json['closedDealsCount'] ?? 0,
      totalRevenueGenerated: (json['total_revenue_generated'] ?? json['totalRevenueGenerated'] ?? 0.0).toDouble(),
      currentStatus: json['current_status'] ?? json['currentStatus'] ?? 'Idle',
      currentOutlet: json['current_outlet'] ?? json['currentOutlet'] ?? 'None',
      liveLocation: json['live_location'] ?? json['liveLocation'] ?? '${json['territory'] ?? 'Ahmedabad'}, Gujarat',
      batteryPercent: json['battery_percent'] ?? json['batteryPercent'] ?? 100,
      visitsToday: json['visits_today'] ?? json['visitsToday'] ?? 0,
      visitsTarget: (json['visits_target'] ?? json['visitsTarget'] ?? 8) is int ? (json['visits_target'] ?? json['visitsTarget'] ?? 8) : int.tryParse((json['visits_target'] ?? json['visitsTarget'] ?? 8).toString()) ?? 8,
      distanceTraveledKm: (json['distance_traveled_km'] ?? json['distanceTraveledKm'] ?? 0.0).toDouble(),
      registeredByUserId: json['registered_by_user_id'] ?? json['registeredByUserId'],
      addedBy: json['added_by'] ?? json['addedBy'] ?? json['registered_by_name'] ?? 'Not Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role == AppUserRole.superAdmin
          ? 'SUPER_ADMIN'
          : role == AppUserRole.companyAdmin
              ? 'COMPANY_ADMIN'
              : role == AppUserRole.salesManager
                  ? 'SALES_MANAGER'
                  : 'SALES_EXECUTIVE',
      'territory': territory,
      'city': city,
      'status': isActive ? 'ACTIVE' : 'INACTIVE',
      'profile_photo': avatarUrl,
      'employee_id': employeeId,
      'date_of_joining': dateOfJoining,
      'designation': designation,
      'active_leads_count': activeLeadsCount,
      'closed_deals_count': closedDealsCount,
      'total_revenue_generated': totalRevenueGenerated,
      'current_status': currentStatus,
      'current_outlet': currentOutlet,
      'live_location': liveLocation,
      'battery_percent': batteryPercent,
      'visits_today': visitsToday,
      'visits_target': visitsTarget,
      'distance_traveled_km': distanceTraveledKm,
      'registered_by_user_id': registeredByUserId,
      'added_by': addedBy,
    };
  }

  TeamMemberModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    AppUserRole? role,
    String? territory,
    String? city,
    bool? isActive,
    String? avatarUrl,
    String? employeeId,
    String? dateOfJoining,
    String? designation,
    int? activeLeadsCount,
    int? closedDealsCount,
    double? totalRevenueGenerated,
    String? currentStatus,
    String? currentOutlet,
    String? liveLocation,
    int? batteryPercent,
    int? visitsToday,
    int? visitsTarget,
    double? distanceTraveledKm,
    String? registeredByUserId,
    String? addedBy,
  }) {
    return TeamMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      territory: territory ?? this.territory,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      employeeId: employeeId ?? this.employeeId,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      designation: designation ?? this.designation,
      activeLeadsCount: activeLeadsCount ?? this.activeLeadsCount,
      closedDealsCount: closedDealsCount ?? this.closedDealsCount,
      totalRevenueGenerated: totalRevenueGenerated ?? this.totalRevenueGenerated,
      currentStatus: currentStatus ?? this.currentStatus,
      currentOutlet: currentOutlet ?? this.currentOutlet,
      liveLocation: liveLocation ?? this.liveLocation,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      visitsToday: visitsToday ?? this.visitsToday,
      visitsTarget: visitsTarget ?? this.visitsTarget,
      distanceTraveledKm: distanceTraveledKm ?? this.distanceTraveledKm,
      registeredByUserId: registeredByUserId ?? this.registeredByUserId,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}

/// POS Rate Card / Pricing Plan
class PricingTierModel {
  final String id;
  final String planName;
  final String billingPeriod; // 'Quarterly', 'Annual', '3-Year Platinum'
  final double softwarePrice;
  final double hardwareBundlePrice;
  final List<String> includedFeatures;
  final bool isPopular;
  final int maxDiscountPercentAllowed;

  const PricingTierModel({
    required this.id,
    required this.planName,
    required this.billingPeriod,
    required this.softwarePrice,
    required this.hardwareBundlePrice,
    required this.includedFeatures,
    this.isPopular = false,
    this.maxDiscountPercentAllowed = 15,
  });

  double get totalPrice => softwarePrice + hardwareBundlePrice;
}

/// Territory Zone & Commercial Complex Directory
class TerritoryZoneModel {
  final String id;
  final String zoneName;
  final String city;
  final String assignedManagerName;
  final int activeRepsCount;
  final int totalComplexesCount;
  final int totalOutletsMapped;
  final double targetRevenue;
  final double achievedRevenue;

  const TerritoryZoneModel({
    required this.id,
    required this.zoneName,
    required this.city,
    required this.assignedManagerName,
    required this.activeRepsCount,
    required this.totalComplexesCount,
    required this.totalOutletsMapped,
    required this.targetRevenue,
    required this.achievedRevenue,
  });
}

/// System Audit Trail Log for Super Admin
class AuditLogModel {
  final String id;
  final DateTime timestamp;
  final String actorName;
  final AppUserRole actorRole;
  final String actionType; // 'ROLE_CHANGE', 'DISCOUNT_OVERRIDE', 'LEAD_REASSIGN', 'LOGIN'
  final String details;
  final String ipAddress;

  const AuditLogModel({
    required this.id,
    required this.timestamp,
    required this.actorName,
    required this.actorRole,
    required this.actionType,
    required this.details,
    this.ipAddress = '192.168.1.45',
  });
}

/// Pending Approval Item for Sales Manager / Super Admin
class ApprovalRequestModel {
  final String id;
  final String repName;
  final String restaurantName;
  final String requestType; // 'Special Discount (18%)', 'Free KDS Trial', 'Travel Expense Claim'
  final String amountOrDetails;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime requestedAt;

  const ApprovalRequestModel({
    required this.id,
    required this.repName,
    required this.restaurantName,
    required this.requestType,
    required this.amountOrDetails,
    this.status = 'Pending',
    required this.requestedAt,
  });

  ApprovalRequestModel copyWith({String? status}) {
    return ApprovalRequestModel(
      id: id,
      repName: repName,
      restaurantName: restaurantName,
      requestType: requestType,
      amountOrDetails: amountOrDetails,
      status: status ?? this.status,
      requestedAt: requestedAt,
    );
  }
}

/// Unassigned Lead for Sales Manager Assignment Engine
class UnassignedLeadModel {
  final String id;
  final String restaurantName;
  final String contactPerson;
  final String mobile;
  final String area;
  final String category;
  final String source;
  final String recommendedRep;
  final String? assignedRepId;

  const UnassignedLeadModel({
    required this.id,
    required this.restaurantName,
    required this.contactPerson,
    required this.mobile,
    required this.area,
    required this.category,
    required this.source,
    required this.recommendedRep,
    this.assignedRepId,
  });

  UnassignedLeadModel copyWith({String? assignedRepId}) {
    return UnassignedLeadModel(
      id: id,
      restaurantName: restaurantName,
      contactPerson: contactPerson,
      mobile: mobile,
      area: area,
      category: category,
      source: source,
      recommendedRep: recommendedRep,
      assignedRepId: assignedRepId ?? this.assignedRepId,
    );
  }
}
