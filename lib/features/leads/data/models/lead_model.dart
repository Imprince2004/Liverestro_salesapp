class LeadModel {
  // Step 1: Lead & Contact Info
  final String id;
  final String contactPersonName;
  final String restaurantName;
  final String mobile;
  final String whatsapp;
  final String alternateMobile;
  final String email;
  final String preferredContactMethod; // Call, WhatsApp, Email, Visit
  final String bestTimeToContact;
  final String leadSource; // Website, Referral, Cold Call, Field Visit, WhatsApp, Social Media, Advertisement, Existing Customer, Other
  final String status; // New, Contacted, Interested, Qualified, Demo Scheduled, Proposal Sent, Negotiation, Won, Lost
  final String priority; // Low, Medium, High, Urgent

  // Step 2: Restaurant Information
  final String businessType; // Restaurant, Café, Cloud Kitchen, Hotel, Bakery, QSR, Bar, Other
  final String address;
  final String city;
  final String area;
  final String pincode;
  final double latitude;
  final double longitude;
  final int numOutlets;
  final int seatingCapacity;
  final String cuisine;
  final String currentPos; // Petpooja, Posist, Manual Billing, Vyapar, Paper KOT, Other
  final String currentOrderingSystem;
  final List<String> deliveryPlatforms; // Swiggy, Zomato, Direct, Magicpin, ONDC
  final int monthlyOrders;
  final double estimatedMonthlyRevenue;

  // Step 3: Business Requirements
  final List<String> requiredSolutions; // POS, Billing, Inventory Management, Online Ordering, Delivery Management, Kitchen Management, Customer Loyalty, Restaurant Mobile App, Analytics & Reports, Multi-Outlet Management, Complete Restaurant Management
  final String painPoints;
  final String requiredSolutionNotes;
  final String currentCompetitor;
  final String reasonConsidering;
  final String expectedBenefits;
  final String? voiceNotePath;
  final String? aiSummary;

  // Step 4: Sales Qualification
  final String decisionMakerName;
  final String decisionMakerDesignation;
  final String budgetRange;
  final double estimatedDealValue;
  final int purchaseProbability; // 0 to 100 %
  final String expectedClosingDate;
  final String competitorNotes;
  final bool demoRequired;
  final String? demoDate;
  final bool proposalRequired;
  final String salesNotes;
  final String assignedSalesperson;
  final String assignedSalespersonId;
  final String createdBy;
  final String createdById;

  final String posSoftware; // Free, Paid
  final double posAmount;
  final String nextFollowUpDate;
  final String nextFollowUpTime;
  final String nextFollowUpType; // Call, WhatsApp, Meeting, Demo, Restaurant Visit, Email
  final String followUpNotes;
  final bool hasReminder;
  final List<String> visitPhotos;
  final String? checkInSelfiePath;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String createdAt;
  final String updatedAt;
  final bool isSynced;

  const LeadModel({
    required this.id,
    required this.contactPersonName,
    required this.restaurantName,
    required this.mobile,
    this.whatsapp = '',
    this.alternateMobile = '',
    this.email = '',
    this.preferredContactMethod = 'Call',
    this.bestTimeToContact = 'Morning (11 AM - 1 PM)',
    this.leadSource = 'Field Visit',
    this.status = 'New',
    this.priority = 'Medium',
    this.businessType = 'Restaurant',
    this.address = '',
    this.city = 'Ahmedabad',
    this.area = 'Jagatpur',
    this.pincode = '',
    this.latitude = 23.1118,
    this.longitude = 72.5442,
    this.numOutlets = 1,
    this.seatingCapacity = 15,
    this.cuisine = 'Multi-Cuisine',
    this.currentPos = 'Manual Billing',
    this.currentOrderingSystem = 'None',
    this.deliveryPlatforms = const ['Swiggy', 'Zomato'],
    this.monthlyOrders = 300,
    this.estimatedMonthlyRevenue = 250000.0,
    this.requiredSolutions = const ['POS & Billing', 'Kitchen Display System (KDS)'],
    this.painPoints = '',
    this.requiredSolutionNotes = '',
    this.currentCompetitor = 'None',
    this.reasonConsidering = 'Looking for modern cloud POS with low hardware cost',
    this.expectedBenefits = 'Faster table turnover and automated inventory',
    this.voiceNotePath,
    this.aiSummary,
    this.decisionMakerName = '',
    this.decisionMakerDesignation = 'Owner / Managing Partner',
    this.budgetRange = '₹25,000 - ₹50,000',
    this.estimatedDealValue = 35000.0,
    this.purchaseProbability = 70,
    this.expectedClosingDate = '',
    this.competitorNotes = '',
    this.demoRequired = true,
    this.demoDate,
    this.proposalRequired = true,
    this.salesNotes = '',
    this.assignedSalesperson = 'Prince Chandarana',
    this.assignedSalespersonId = 'EMP00125',
    this.createdBy = 'Prince Chandarana',
    this.createdById = 'EMP00125',
    this.posSoftware = 'Free',
    this.posAmount = 0.0,
    this.nextFollowUpDate = '',
    this.nextFollowUpTime = '',
    this.nextFollowUpType = 'Restaurant Visit',
    this.followUpNotes = '',
    this.hasReminder = true,
    this.visitPhotos = const [],
    this.checkInSelfiePath,
    this.checkInLatitude,
    this.checkInLongitude,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  // Backward compatibility getter for older screens
  String get ownerName => contactPersonName.isNotEmpty ? contactPersonName : decisionMakerName;
  String get gstNumber => '';
  double get avgBilling => monthlyOrders > 0 ? (estimatedMonthlyRevenue / monthlyOrders) : 0.0;
  String get competitorPos => currentCompetitor;
  double get expectedRevenue => estimatedDealValue;
  String? get attachmentPath => visitPhotos.isNotEmpty ? visitPhotos.first : null;
  String get notes => salesNotes.isNotEmpty ? salesNotes : requiredSolutionNotes;
  String get followUpDate => nextFollowUpDate;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final rawPos = (json['posSoftware'] ?? json['pos_software'] ?? 'Free').toString();
    final isPaid = rawPos.toUpperCase() == 'PAID';
    final parsedPosAmount = (json['posAmount'] as num?)?.toDouble() ?? (json['pos_amount'] as num?)?.toDouble() ?? 0.0;

    return LeadModel(
      id: json['id'] as String? ?? '',
      contactPersonName: json['contactPersonName'] as String? ?? (json['contact_person_name'] as String? ?? (json['ownerName'] as String? ?? '')),
      restaurantName: json['restaurantName'] as String? ?? (json['restaurant_name'] as String? ?? ''),
      mobile: json['mobile'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      alternateMobile: json['alternateMobile'] as String? ?? (json['alternate_mobile'] as String? ?? ''),
      email: json['email'] as String? ?? '',
      preferredContactMethod: json['preferredContactMethod'] as String? ?? (json['preferred_contact_method'] as String? ?? 'Call'),
      bestTimeToContact: json['bestTimeToContact'] as String? ?? (json['best_time_to_contact'] as String? ?? 'Morning (11 AM - 1 PM)'),
      leadSource: json['leadSource'] as String? ?? (json['lead_source'] as String? ?? 'Field Visit'),
      status: json['status'] as String? ?? 'New',
      priority: json['priority'] as String? ?? 'Medium',
      businessType: json['businessType'] as String? ?? (json['business_type'] as String? ?? 'Restaurant'),
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Ahmedabad',
      area: json['area'] as String? ?? 'Jagatpur',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.1118,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.5442,
      numOutlets: json['numOutlets'] as int? ?? (json['num_outlets'] as int? ?? 1),
      seatingCapacity: json['seatingCapacity'] as int? ?? (json['seating_capacity'] as int? ?? 15),
      cuisine: json['cuisine'] as String? ?? 'Multi-Cuisine',
      currentPos: json['currentPos'] as String? ?? (json['current_pos'] as String? ?? 'Manual Billing'),
      currentOrderingSystem: json['currentOrderingSystem'] as String? ?? (json['current_ordering_system'] as String? ?? 'None'),
      deliveryPlatforms: (json['deliveryPlatforms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['Swiggy', 'Zomato'],
      monthlyOrders: json['monthlyOrders'] as int? ?? (json['monthly_orders'] as int? ?? 300),
      estimatedMonthlyRevenue: (json['estimatedMonthlyRevenue'] as num?)?.toDouble() ?? (json['estimated_monthly_revenue'] as num?)?.toDouble() ?? 250000.0,
      requiredSolutions: (json['requiredSolutions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['POS & Billing', 'Kitchen Display System (KDS)'],
      painPoints: json['painPoints'] as String? ?? (json['pain_points'] as String? ?? ''),
      requiredSolutionNotes: json['requiredSolutionNotes'] as String? ?? (json['required_solution_notes'] as String? ?? ''),
      currentCompetitor: json['currentCompetitor'] as String? ?? (json['current_competitor'] as String? ?? 'None'),
      reasonConsidering: json['reasonConsidering'] as String? ?? (json['reason_considering'] as String? ?? ''),
      expectedBenefits: json['expectedBenefits'] as String? ?? (json['expected_benefits'] as String? ?? ''),
      voiceNotePath: json['voiceNotePath'] as String? ?? json['audio_url'] as String?,
      aiSummary: json['aiSummary'] as String? ?? json['transcription_summary'] as String?,
      decisionMakerName: json['decisionMakerName'] as String? ?? (json['decision_maker_name'] as String? ?? ''),
      decisionMakerDesignation: json['decisionMakerDesignation'] as String? ?? (json['decision_maker_designation'] as String? ?? 'Owner / Managing Partner'),
      budgetRange: json['budgetRange'] as String? ?? (json['budget_range'] as String? ?? '₹25,000 - ₹50,000'),
      estimatedDealValue: (json['estimatedDealValue'] as num?)?.toDouble() ?? (json['estimated_deal_value'] as num?)?.toDouble() ?? 35000.0,
      purchaseProbability: json['purchaseProbability'] as int? ?? (json['purchase_probability'] as int? ?? 70),
      expectedClosingDate: json['expectedClosingDate'] as String? ?? (json['expected_closing_date'] as String? ?? ''),
      competitorNotes: json['competitorNotes'] as String? ?? (json['competitor_notes'] as String? ?? ''),
      demoRequired: json['demoRequired'] as bool? ?? (json['demo_required'] as bool? ?? true),
      demoDate: json['demoDate'] as String? ?? json['demo_date'] as String?,
      proposalRequired: json['proposalRequired'] as bool? ?? (json['proposal_required'] as bool? ?? true),
      salesNotes: json['salesNotes'] as String? ?? (json['sales_notes'] as String? ?? ''),
      assignedSalesperson: json['assignedSalesperson'] as String? ?? (json['assigned_salesperson'] as String? ?? 'Prince Chandarana'),
      assignedSalespersonId: json['assignedSalespersonId'] as String? ?? (json['assigned_salesperson_id'] as String? ?? 'EMP00125'),
      createdBy: json['createdBy'] as String? ?? (json['created_by'] as String? ?? 'Prince Chandarana'),
      createdById: json['createdById'] as String? ?? (json['created_by_id'] as String? ?? 'EMP00125'),
      posSoftware: isPaid ? 'Paid' : 'Free',
      posAmount: isPaid ? parsedPosAmount : 0.0,
      nextFollowUpDate: json['nextFollowUpDate'] as String? ?? (json['next_follow_up_date'] as String? ?? ''),
      nextFollowUpTime: json['nextFollowUpTime'] as String? ?? (json['next_follow_up_time'] as String? ?? '11:00 AM'),
      nextFollowUpType: json['nextFollowUpType'] as String? ?? (json['next_follow_up_type'] as String? ?? 'Restaurant Visit'),
      followUpNotes: json['followUpNotes'] as String? ?? (json['follow_up_notes'] as String? ?? ''),
      hasReminder: json['hasReminder'] as bool? ?? (json['has_reminder'] as bool? ?? true),
      visitPhotos: (json['visitPhotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      checkInSelfiePath: json['checkInSelfiePath'] as String?,
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String? ?? (json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] as String? ?? (json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactPersonName': contactPersonName,
      'restaurantName': restaurantName,
      'mobile': mobile,
      'whatsapp': whatsapp,
      'alternateMobile': alternateMobile,
      'email': email,
      'preferredContactMethod': preferredContactMethod,
      'bestTimeToContact': bestTimeToContact,
      'leadSource': leadSource,
      'status': status,
      'priority': priority,
      'businessType': businessType,
      'address': address,
      'city': city,
      'area': area,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'numOutlets': numOutlets,
      'seatingCapacity': seatingCapacity,
      'cuisine': cuisine,
      'currentPos': currentPos,
      'currentOrderingSystem': currentOrderingSystem,
      'deliveryPlatforms': deliveryPlatforms,
      'monthlyOrders': monthlyOrders,
      'estimatedMonthlyRevenue': estimatedMonthlyRevenue,
      'requiredSolutions': requiredSolutions,
      'painPoints': painPoints,
      'requiredSolutionNotes': requiredSolutionNotes,
      'currentCompetitor': currentCompetitor,
      'reasonConsidering': reasonConsidering,
      'expectedBenefits': expectedBenefits,
      'voiceNotePath': voiceNotePath,
      'aiSummary': aiSummary,
      'decisionMakerName': decisionMakerName,
      'decisionMakerDesignation': decisionMakerDesignation,
      'budgetRange': budgetRange,
      'estimatedDealValue': estimatedDealValue,
      'purchaseProbability': purchaseProbability,
      'expectedClosingDate': expectedClosingDate,
      'competitorNotes': competitorNotes,
      'demoRequired': demoRequired,
      'demoDate': demoDate,
      'proposalRequired': proposalRequired,
      'salesNotes': salesNotes,
      'assignedSalesperson': assignedSalesperson,
      'assignedSalespersonId': assignedSalespersonId,
      'createdBy': createdBy,
      'createdById': createdById,
      'posSoftware': posSoftware,
      'pos_software': posSoftware,
      'posAmount': posAmount,
      'pos_amount': posAmount,
      'nextFollowUpDate': nextFollowUpDate,
      'nextFollowUpTime': nextFollowUpTime,
      'nextFollowUpType': nextFollowUpType,
      'followUpNotes': followUpNotes,
      'hasReminder': hasReminder,
      'visitPhotos': visitPhotos,
      'checkInSelfiePath': checkInSelfiePath,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isSynced': isSynced,
    };
  }

  LeadModel copyWith({
    String? id,
    String? contactPersonName,
    String? restaurantName,
    String? mobile,
    String? whatsapp,
    String? alternateMobile,
    String? email,
    String? preferredContactMethod,
    String? bestTimeToContact,
    String? leadSource,
    String? status,
    String? priority,
    String? businessType,
    String? address,
    String? city,
    String? area,
    String? pincode,
    double? latitude,
    double? longitude,
    int? numOutlets,
    int? seatingCapacity,
    String? cuisine,
    String? currentPos,
    String? currentOrderingSystem,
    List<String>? deliveryPlatforms,
    int? monthlyOrders,
    double? estimatedMonthlyRevenue,
    List<String>? requiredSolutions,
    String? painPoints,
    String? requiredSolutionNotes,
    String? currentCompetitor,
    String? reasonConsidering,
    String? expectedBenefits,
    String? voiceNotePath,
    String? aiSummary,
    String? decisionMakerName,
    String? decisionMakerDesignation,
    String? budgetRange,
    double? estimatedDealValue,
    int? purchaseProbability,
    String? expectedClosingDate,
    String? competitorNotes,
    bool? demoRequired,
    String? demoDate,
    bool? proposalRequired,
    String? salesNotes,
    String? assignedSalesperson,
    String? assignedSalespersonId,
    String? createdBy,
    String? createdById,
    String? posSoftware,
    double? posAmount,
    String? nextFollowUpDate,
    String? nextFollowUpTime,
    String? nextFollowUpType,
    String? followUpNotes,
    bool? hasReminder,
    List<String>? visitPhotos,
    String? checkInSelfiePath,
    double? checkInLatitude,
    double? checkInLongitude,
    String? createdAt,
    String? updatedAt,
    bool? isSynced,
  }) {
    return LeadModel(
      id: id ?? this.id,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      restaurantName: restaurantName ?? this.restaurantName,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      alternateMobile: alternateMobile ?? this.alternateMobile,
      email: email ?? this.email,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      bestTimeToContact: bestTimeToContact ?? this.bestTimeToContact,
      leadSource: leadSource ?? this.leadSource,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      numOutlets: numOutlets ?? this.numOutlets,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      cuisine: cuisine ?? this.cuisine,
      currentPos: currentPos ?? this.currentPos,
      currentOrderingSystem: currentOrderingSystem ?? this.currentOrderingSystem,
      deliveryPlatforms: deliveryPlatforms ?? this.deliveryPlatforms,
      monthlyOrders: monthlyOrders ?? this.monthlyOrders,
      estimatedMonthlyRevenue: estimatedMonthlyRevenue ?? this.estimatedMonthlyRevenue,
      requiredSolutions: requiredSolutions ?? this.requiredSolutions,
      painPoints: painPoints ?? this.painPoints,
      requiredSolutionNotes: requiredSolutionNotes ?? this.requiredSolutionNotes,
      currentCompetitor: currentCompetitor ?? this.currentCompetitor,
      reasonConsidering: reasonConsidering ?? this.reasonConsidering,
      expectedBenefits: expectedBenefits ?? this.expectedBenefits,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      aiSummary: aiSummary ?? this.aiSummary,
      decisionMakerName: decisionMakerName ?? this.decisionMakerName,
      decisionMakerDesignation: decisionMakerDesignation ?? this.decisionMakerDesignation,
      budgetRange: budgetRange ?? this.budgetRange,
      estimatedDealValue: estimatedDealValue ?? this.estimatedDealValue,
      purchaseProbability: purchaseProbability ?? this.purchaseProbability,
      expectedClosingDate: expectedClosingDate ?? this.expectedClosingDate,
      competitorNotes: competitorNotes ?? this.competitorNotes,
      demoRequired: demoRequired ?? this.demoRequired,
      demoDate: demoDate ?? this.demoDate,
      proposalRequired: proposalRequired ?? this.proposalRequired,
      salesNotes: salesNotes ?? this.salesNotes,
      assignedSalesperson: assignedSalesperson ?? this.assignedSalesperson,
      assignedSalespersonId: assignedSalespersonId ?? this.assignedSalespersonId,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      posSoftware: posSoftware ?? this.posSoftware,
      posAmount: posAmount ?? this.posAmount,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      nextFollowUpTime: nextFollowUpTime ?? this.nextFollowUpTime,
      nextFollowUpType: nextFollowUpType ?? this.nextFollowUpType,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      hasReminder: hasReminder ?? this.hasReminder,
      visitPhotos: visitPhotos ?? this.visitPhotos,
      checkInSelfiePath: checkInSelfiePath ?? this.checkInSelfiePath,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
