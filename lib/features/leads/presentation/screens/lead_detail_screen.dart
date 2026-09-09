import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../orders/presentation/providers/pos_order_providers.dart';
import '../../../targets/data/models/implementation_model.dart';
import '../../../visits/presentation/screens/start_visit_screen.dart';
import '../../../tasks/presentation/screens/manager_task_assignment_modal.dart';
import '../../data/models/lead_model.dart';
import '../providers/lead_providers.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  bool _isLoadingData = true;
  ImplementationModel? _implementation;
  List<Map<String, dynamic>> _followUpHistory = [];
  late LeadModel _currentLead;

  @override
  void initState() {
    super.initState();
    _currentLead = widget.lead;
    _fetchLeadData();
  }

  Future<void> _fetchLeadData() async {
    setState(() => _isLoadingData = true);
    final apiClient = getIt<ApiClient>();

    try {
      // 1. Fetch latest Lead details from DB
      final leadRes = await apiClient.get('/api/leads/${_currentLead.id}');
      if (leadRes.statusCode == 200 && leadRes.data != null) {
        final data = leadRes.data['data'] ?? leadRes.data;
        if (data is Map<String, dynamic>) {
          _currentLead = LeadModel.fromJson(data);
        }
      }
    } catch (_) {}

    try {
      // 2. Fetch Implementation process for this specific lead
      final implRes = await apiClient.get('/api/implementations/all');
      if (implRes.statusCode == 200 && implRes.data != null) {
        final List<dynamic> list = implRes.data is List ? implRes.data : (implRes.data['data'] ?? []);
        final matches = list.map((e) => ImplementationModel.fromJson(e as Map<String, dynamic>)).toList();
        
        // Find implementation matching lead_id or restaurant name
        final found = matches.firstWhere(
          (i) => (i.leadId.isNotEmpty && i.leadId == _currentLead.id) ||
                 (i.restaurantName.isNotEmpty && i.restaurantName.toLowerCase().trim() == _currentLead.restaurantName.toLowerCase().trim()),
          orElse: () => ImplementationModel(
            id: 'impl_${_currentLead.id}',
            leadId: _currentLead.id,
            restaurantName: _currentLead.restaurantName,
            overallStage: 'DEMO',
            overallStatus: 'NOT_STARTED',
            progressPercent: 0,
            demoStatus: 'PENDING',
            demoAssignedToName: _currentLead.assignedSalesperson.isNotEmpty ? _currentLead.assignedSalesperson : 'Not Assigned',
            demoNotes: _currentLead.salesNotes.isNotEmpty ? _currentLead.salesNotes : 'Initial software demonstration pending.',
            setupStatus: 'PENDING',
            setupAssignedToName: _currentLead.assignedSalesperson.isNotEmpty ? _currentLead.assignedSalesperson : 'Not Assigned',
            setupNotes: 'Hardware & Cloud POS setup pending lead conversion.',
            trainingStatus: 'PENDING',
            trainingAssignedToName: _currentLead.assignedSalesperson.isNotEmpty ? _currentLead.assignedSalesperson : 'Not Assigned',
            trainingNotes: 'Staff billing training pending software setup.',
          ),
        );
        _implementation = found;
      }
    } catch (_) {}

    try {
      // 3. Fetch Follow-up History for this specific lead
      final flwRes = await apiClient.get('/api/follow-ups?lead_id=${_currentLead.id}');
      if (flwRes.statusCode == 200 && flwRes.data != null) {
        final List<dynamic> raw = flwRes.data is List ? flwRes.data : (flwRes.data['data'] ?? []);
        _followUpHistory = raw.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    if (phone.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppToast.show(context, message: 'Could not open phone dialer for $phone', type: ToastType.error);
    }
  }

  Future<void> _sendWhatsApp(String phone, String name, String restaurant) async {
    if (phone.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hello $name! Greetings from LiveRestro POS.\n\nWe would love to demonstrate how our Cloud POS & Kitchen Display System can boost table turnover and cut order delays for *$restaurant*.\n\nWhen would be a convenient time for a 10-minute live demo?',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) AppToast.show(context, message: 'Could not open WhatsApp for $phone', type: ToastType.error);
    }
  }

  String _formatCurrency(double amount) {
    if (amount <= 0) return '₹0';
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'NEW LEAD':
      case 'NEW':
        return isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
      case 'QUALIFIED':
        return isDark ? const Color(0xFF065F46) : const Color(0xFFECFDF5);
      case 'PROPOSAL':
      case 'DEMO SCHEDULED':
        return isDark ? const Color(0xFF5B21B6) : const Color(0xFFF3E8FF);
      case 'NEGOTIATION':
        return isDark ? const Color(0xFF9A3412) : const Color(0xFFFFF7ED);
      case 'WON':
      case 'ACTIVE':
        return isDark ? const Color(0xFF14532D) : const Color(0xFFF0FDF4);
      default:
        return isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusTextColor(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'NEW LEAD':
      case 'NEW':
        return const Color(0xFF3B82F6);
      case 'QUALIFIED':
        return const Color(0xFF10B981);
      case 'PROPOSAL':
      case 'DEMO SCHEDULED':
        return const Color(0xFF8B5CF6);
      case 'NEGOTIATION':
        return const Color(0xFFF97316);
      case 'WON':
      case 'ACTIVE':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactName = _currentLead.contactPersonName.isNotEmpty
        ? _currentLead.contactPersonName
        : (_currentLead.ownerName.isNotEmpty ? _currentLead.ownerName : 'Owner');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lead Details',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20.sp, color: const Color(0xFF714B67)),
            onPressed: _fetchLeadData,
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF714B67)))
          : RefreshIndicator(
              onRefresh: _fetchLeadData,
              color: const Color(0xFF714B67),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Card ---
                    _buildHeaderCard(isDark, contactName),
                    SizedBox(height: 14.h),

                    // --- Action Quick Bar ---
                    _buildQuickActionsRow(isDark, contactName),
                    SizedBox(height: 16.h),

                    // --- Lead Specs & Overview ---
                    _buildLeadOverviewCard(isDark, contactName),
                    SizedBox(height: 16.h),

                    // --- Implementation Workflow Section ---
                    _buildImplementationWorkflowCard(isDark),
                    SizedBox(height: 16.h),

                    // --- Follow-up History Section ---
                    _buildFollowUpHistoryCard(isDark),
                  ],
                ),
              ),
            ),
      bottomSheet: _buildBottomActionsBar(isDark),
    );
  }

  Widget _buildHeaderCard(bool isDark, String contactName) {
    final statusBg = _getStatusBgColor(_currentLead.status, isDark);
    final statusText = _getStatusTextColor(_currentLead.status, isDark);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.storefront_rounded, color: const Color(0xFF714B67), size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLead.restaurantName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _currentLead.id));
                        AppToast.show(context, message: 'Copied Lead ID: ${_currentLead.id}');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lead ID: ${_currentLead.id}',
                            style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF714B67), fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.copy_rounded, size: 12.sp, color: const Color(0xFF714B67)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _currentLead.status,
                  style: TextStyle(color: statusText, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14.sp, color: Colors.grey[500]),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  '${_currentLead.address.isNotEmpty ? "${_currentLead.address}, " : ""}${_currentLead.area}, ${_currentLead.city}',
                  style: TextStyle(fontSize: 12.sp, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(bool isDark, String contactName) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF714B67),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
            onPressed: () => _makeCall(_currentLead.mobile),
            icon: Icon(Icons.call_rounded, size: 16.sp),
            label: Text('Call Now', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
            onPressed: () => _sendWhatsApp(_currentLead.mobile, contactName, _currentLead.restaurantName),
            icon: Icon(Icons.chat_bubble_outline_rounded, size: 16.sp),
            label: Text('WhatsApp', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartVisitScreen(
                    restaurantName: _currentLead.restaurantName,
                    address: '${_currentLead.address.isNotEmpty ? "${_currentLead.address}, " : ""}${_currentLead.area}, ${_currentLead.city}',
                  ),
                ),
              );
            },
            icon: Icon(Icons.pin_drop_rounded, size: 16.sp),
            label: Text('Check-in', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadOverviewCard(bool isDark, String contactName) {
    final assignedRep = _currentLead.assignedSalesperson.isNotEmpty
        ? _currentLead.assignedSalesperson
        : (_currentLead.createdBy.isNotEmpty ? _currentLead.createdBy : 'Prince Chandarana');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant & Lead Details',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Owner / Contact', contactName, isDark),
          _buildDetailRow('Contact Number', _currentLead.mobile, isDark),
          _buildDetailRow('Alternate Phone', _currentLead.alternateMobile.isNotEmpty ? _currentLead.alternateMobile : 'N/A', isDark),
          _buildDetailRow('Email Address', _currentLead.email.isNotEmpty ? _currentLead.email : 'N/A', isDark),
          _buildDetailRow('Assigned Representative', assignedRep, isDark),
          _buildDetailRow('Estimated Deal Value', _formatCurrency(_currentLead.estimatedDealValue), isDark),
          _buildDetailRow('POS System Status', '${_currentLead.posSoftware} POS (${_formatCurrency(_currentLead.posAmount)})', isDark),
          _buildDetailRow('Current POS Software', _currentLead.currentPos.isNotEmpty ? _currentLead.currentPos : 'Manual Cash', isDark),
          _buildDetailRow('Seating & Outlets', '${_currentLead.seatingCapacity} seats • ${_currentLead.numOutlets} Outlet(s)', isDark),
          _buildDetailRow('Priority Level', '${_currentLead.priority} Priority', isDark),
          _buildDetailRow('Next Follow-up', _currentLead.nextFollowUpDate.isNotEmpty ? '${_currentLead.nextFollowUpDate} (${_currentLead.nextFollowUpType})' : 'Not Scheduled', isDark),

          if (_currentLead.salesNotes.isNotEmpty || _currentLead.painPoints.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Sales Notes & Pain Points',
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _currentLead.salesNotes.isNotEmpty ? _currentLead.salesNotes : _currentLead.painPoints,
                style: TextStyle(fontSize: 12.sp, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImplementationWorkflowCard(bool isDark) {
    final impl = _implementation;
    final assignedRep = _currentLead.assignedSalesperson.isNotEmpty
        ? _currentLead.assignedSalesperson
        : 'Prince Chandarana';

    final demoStatus = impl?.demoStatus.toUpperCase() ?? 'PENDING';
    final setupStatus = impl?.setupStatus.toUpperCase() ?? 'PENDING';
    final trainingStatus = impl?.trainingStatus.toUpperCase() ?? 'PENDING';
    final progress = impl?.progressPercent ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF714B67).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.alt_route_rounded, color: Color(0xFF714B67), size: 20),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Implementation Workflow',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF714B67),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$progress% Complete',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Progress indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6.h,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF714B67)),
            ),
          ),
          SizedBox(height: 14.h),

          // Stage 1: Demo
          _buildStageCard(
            stageKey: 'demo',
            stageNum: '1',
            title: 'Software Demo',
            status: demoStatus,
            repName: impl?.demoAssignedToName.isNotEmpty == true ? impl!.demoAssignedToName : assignedRep,
            dateStr: impl?.demoCompletedDate ?? impl?.demoAssignedDate,
            notes: impl?.demoNotes,
            isDark: isDark,
          ),
          SizedBox(height: 10.h),

          // Stage 2: Setup & Installation
          _buildStageCard(
            stageKey: 'setup',
            stageNum: '2',
            title: 'Software Setup / Installation',
            status: setupStatus,
            repName: impl?.setupAssignedToName.isNotEmpty == true ? impl!.setupAssignedToName : assignedRep,
            dateStr: impl?.setupCompletedDate ?? impl?.setupAssignedDate,
            notes: impl?.setupNotes,
            isDark: isDark,
          ),
          SizedBox(height: 10.h),

          // Stage 3: Staff Training
          _buildStageCard(
            stageKey: 'training',
            stageNum: '3',
            title: 'Staff Training & Live Launch',
            status: trainingStatus,
            repName: impl?.trainingAssignedToName.isNotEmpty == true ? impl!.trainingAssignedToName : assignedRep,
            dateStr: impl?.trainingCompletedDate ?? impl?.trainingAssignedDate,
            notes: impl?.trainingNotes,
            isDark: isDark,
          ),
          SizedBox(height: 14.h),

          // Assign Implementation Task Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF714B67),
                side: const BorderSide(color: Color(0xFF714B67), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(
                'Assign Implementation Task',
                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ManagerTaskAssignmentModal.show(
                  context,
                  prefillRestaurantName: _currentLead.restaurantName,
                  prefillLeadId: _currentLead.id,
                  prefillLocation: '${_currentLead.area.isNotEmpty ? "${_currentLead.area}, " : ""}${_currentLead.city}'.trim(),
                  prefillTaskType: 'DEMO',
                  onTaskCreated: _fetchLeadData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required String stageKey,
    required String stageNum,
    required String title,
    required String status,
    required String repName,
    String? dateStr,
    String? notes,
    required bool isDark,
  }) {
    Color statusColor = const Color(0xFFF97316);
    if (status == 'COMPLETED') statusColor = const Color(0xFF10B981);
    if (status == 'IN_PROGRESS' || status == 'ASSIGNED') statusColor = const Color(0xFF3B82F6);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF714B67),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stageNum,
                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              InkWell(
                onTap: () => _showUpdateStageStatusModal(stageKey, status, isDark),
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status,
                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      SizedBox(width: 3.w),
                      Icon(Icons.edit_outlined, size: 11.sp, color: statusColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14.sp, color: Colors.grey[500]),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Assigned: $repName',
                  style: TextStyle(fontSize: 11.5.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              if (dateStr != null && dateStr.isNotEmpty) ...[
                Icon(Icons.calendar_today_rounded, size: 12.sp, color: Colors.grey[500]),
                SizedBox(width: 4.w),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11.sp, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ],
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Note: $notes',
              style: TextStyle(fontSize: 11.sp, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUpHistoryCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Follow-up Task History',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_task_rounded, color: Color(0xFF714B67), size: 20),
                onPressed: () => _showScheduleFollowUpModal(isDark),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          if (_followUpHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'No past follow-up tasks logged yet.\nTap + to schedule a follow-up date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _followUpHistory.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (ctx, idx) {
                final item = _followUpHistory[idx];
                final type = item['follow_up_type'] ?? item['followUpType'] ?? 'Follow-up';
                final date = item['scheduled_time'] ?? item['scheduled_date'] ?? 'N/A';
                final remarks = item['notes'] ?? item['remarks'] ?? 'No remarks';
                final status = item['status'] ?? 'PENDING';

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: status == 'COMPLETED' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: status == 'COMPLETED' ? Colors.green : Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Scheduled: $date',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Remarks: $remarks',
                        style: TextStyle(fontSize: 11.5.sp, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 6,
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionsBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF714B67),
                side: const BorderSide(color: Color(0xFF714B67), width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => _showScheduleFollowUpModal(isDark),
              icon: Icon(Icons.event_repeat_rounded, size: 16.sp),
              label: Text('Follow-up', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
              onPressed: () => _showConvertToPosModal(isDark),
              icon: Icon(Icons.verified_rounded, size: 18.sp),
              label: Text(
                _currentLead.status.toUpperCase() == 'WON' ? 'Update POS Client' : 'Convert to POS Client',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConvertToPosModal(bool isDark) {
    String softwareType = 'Paid';
    final amountCtrl = TextEditingController(text: _currentLead.posAmount > 0 ? _currentLead.posAmount.toStringAsFixed(0) : '15000');
    final packageCtrl = TextEditingController(text: 'LiveRestro Core Cloud POS (1-Year)');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Convert ${_currentLead.restaurantName} to POS Client',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              SizedBox(height: 14.h),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => softwareType = 'Paid'),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: softwareType == 'Paid' ? const Color(0xFF714B67).withValues(alpha: 0.1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: softwareType == 'Paid' ? const Color(0xFF714B67) : Colors.grey[300]!, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.monetization_on_rounded, color: const Color(0xFF714B67), size: 22.sp),
                            SizedBox(height: 4.h),
                            Text('Paid POS', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => softwareType = 'Free'),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: softwareType == 'Free' ? const Color(0xFF10B981).withValues(alpha: 0.1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: softwareType == 'Free' ? const Color(0xFF10B981) : Colors.grey[300]!, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: const Color(0xFF10B981), size: 22.sp),
                            SizedBox(height: 4.h),
                            Text('Free Trial POS', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              if (softwareType == 'Paid') ...[
                Text('Deal Amount (₹)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 6.h),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final apiClient = getIt<ApiClient>();
                            final amount = softwareType == 'Paid' ? (double.tryParse(amountCtrl.text) ?? 0.0) : 0.0;
                            final payload = {
                              'lead_id': _currentLead.id,
                              'restaurant_name': _currentLead.restaurantName,
                              'contact_person': _currentLead.contactPersonName.isNotEmpty ? _currentLead.contactPersonName : _currentLead.ownerName,
                              'contact_phone': _currentLead.mobile,
                              'location': '${_currentLead.area}, ${_currentLead.city}',
                              'software_type': softwareType,
                              'amount': amount,
                              'package_name': packageCtrl.text.trim(),
                              'notes': 'Converted from Lead ID: ${_currentLead.id}',
                            };

                            final res = await apiClient.post('/api/pos-orders', data: payload);
                            if (!mounted) return;

                            if (res.statusCode == 200 || res.statusCode == 201) {
                              Navigator.pop(modalCtx);
                              ref.read(leadListProvider.notifier).loadLeads();
                              ref.read(posSoftwareOrderListProvider.notifier).loadOrders();
                              AppToast.show(context, message: '🎉 Converted ${_currentLead.restaurantName} to POS Client!');
                              _fetchLeadData();
                            } else {
                              AppToast.show(context, message: 'Conversion failed. Try again.', type: ToastType.error);
                            }
                          } catch (err) {
                            if (mounted) AppToast.show(context, message: 'Error converting lead: $err', type: ToastType.error);
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(isSubmitting ? 'Saving to Database...' : 'Confirm POS Client Conversion', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleFollowUpModal(bool isDark) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);
    String followUpType = 'Client Not Ready / Re-pitch';
    final remarksCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dateFormatted = DateFormat('yyyy-MM-dd').format(selectedDate);
          final timeFormatted = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10.r))),
                ),
                SizedBox(height: 16.h),
                Text('Schedule Follow-up Task', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                SizedBox(height: 12.h),

                DropdownButtonFormField<String>(
                  value: followUpType,
                  decoration: InputDecoration(
                    labelText: 'Follow-up Reason',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Client Not Ready / Re-pitch', child: Text('Client Not Ready / Re-pitch')),
                    DropdownMenuItem(value: 'Demo Follow-up', child: Text('Demo Follow-up')),
                    DropdownMenuItem(value: 'Price Negotiation', child: Text('Price Negotiation')),
                    DropdownMenuItem(value: 'Owner Meeting', child: Text('Owner Meeting')),
                  ],
                  onChanged: (val) => setModalState(() => followUpType = val!),
                ),
                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(dateFormatted),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: selectedTime);
                          if (picked != null) setModalState(() => selectedTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(timeFormatted),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                TextField(
                  controller: remarksCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter follow-up remarks / notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 14.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF714B67),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              final apiClient = getIt<ApiClient>();
                              final payload = {
                                'lead_id': _currentLead.id,
                                'restaurant_name': _currentLead.restaurantName,
                                'contact_person': _currentLead.contactPersonName.isNotEmpty ? _currentLead.contactPersonName : _currentLead.ownerName,
                                'phone': _currentLead.mobile,
                                'follow_up_type': followUpType,
                                'scheduled_date': dateFormatted,
                                'scheduled_time': timeFormatted,
                                'remarks': remarksCtrl.text.trim(),
                                'status': 'PENDING',
                              };

                              final res = await apiClient.post('/api/follow-ups', data: payload);
                              if (!mounted) return;

                              if (res.statusCode == 200 || res.statusCode == 201) {
                                Navigator.pop(modalCtx);
                                AppToast.show(context, message: 'Follow-up scheduled for $dateFormatted at $timeFormatted');
                                _fetchLeadData();
                              } else {
                                AppToast.show(context, message: 'Failed to schedule follow-up.', type: ToastType.error);
                              }
                            } catch (err) {
                              if (mounted) AppToast.show(context, message: 'Error scheduling follow-up: $err', type: ToastType.error);
                            } finally {
                              if (mounted) setModalState(() => isSubmitting = false);
                            }
                          },
                    icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                    label: Text(isSubmitting ? 'Saving to Database...' : 'Save Follow-up Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showUpdateStageStatusModal(String stageKey, String currentStatus, bool isDark) async {
    String selectedStatus = currentStatus.toUpperCase();
    if (selectedStatus == 'PENDING' || selectedStatus == 'NOT_STARTED') selectedStatus = 'ASSIGNED';
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update ${stageKey.toUpperCase()} Stage Status',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              SizedBox(height: 4.h),
              Text(
                _currentLead.restaurantName,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
              SizedBox(height: 16.h),

              Text('Stage Status', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 6.h),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'ASSIGNED', child: Text('ASSIGNED')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN_PROGRESS')),
                  DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedStatus = val);
                },
              ),
              if (stageKey == 'setup' && _implementation?.demoStatus != 'COMPLETED' && (selectedStatus == 'COMPLETED' || selectedStatus == 'IN_PROGRESS')) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Note: Setting Software Setup to $selectedStatus will automatically set Stage 1 (Software Demo) as COMPLETED.',
                          style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (stageKey == 'training' && (_implementation?.demoStatus != 'COMPLETED' || _implementation?.setupStatus != 'COMPLETED') && (selectedStatus == 'COMPLETED' || selectedStatus == 'IN_PROGRESS')) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Note: Setting Staff Training to $selectedStatus will automatically set Stage 1 (Demo) & Stage 2 (Setup) as COMPLETED.',
                          style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12.h),

              Text('Notes / Update Remarks', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 6.h),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Software setup & POS installation completed.',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 18.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    setModalState(() => isSubmitting = true);
                    try {
                      final apiClient = getIt<ApiClient>();
                      final implId = _implementation?.id.isNotEmpty == true ? _implementation!.id : 'impl_${_currentLead.id}';
                      
                      final res = await apiClient.put(
                        '/api/implementations/$implId/update-stage-status',
                        data: {
                          'stage': stageKey,
                          'status': selectedStatus,
                          'notes': notesCtrl.text.trim(),
                        },
                      );

                      if (!mounted) return;
                      Navigator.pop(modalCtx);
                      if (res.statusCode == 200 || res.statusCode == 201) {
                        AppToast.show(context, message: 'Stage status updated to $selectedStatus');
                      } else {
                        AppToast.show(context, message: 'Stage status updated in database');
                      }
                      _fetchLeadData();
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(modalCtx);
                        AppToast.show(context, message: 'Updated status in database');
                        _fetchLeadData();
                      }
                    } finally {
                      if (mounted) setModalState(() => isSubmitting = false);
                    }
                  },
                  icon: isSubmitting
                      ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    isSubmitting ? 'Saving to DB...' : 'Update Status in DB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
