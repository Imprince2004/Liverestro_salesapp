import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../data/models/admin_models.dart';
import '../providers/role_providers.dart';
import 'register_executive_modal.dart';

class TeamExecutiveListScreen extends ConsumerStatefulWidget {
  const TeamExecutiveListScreen({super.key});

  @override
  ConsumerState<TeamExecutiveListScreen> createState() => _TeamExecutiveListScreenState();
}

class _TeamExecutiveListScreenState extends ConsumerState<TeamExecutiveListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendWhatsApp(String phone, String name) async {
    final msg = Uri.encodeComponent('Hello $name, checking in on your daily merchant acquisition visits and target.');
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showExecutiveDetailsSheet(BuildContext context, TeamMemberModel rep, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Header Card: Avatar + Name + EMP ID Pill + Active Badge
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.5.w),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF714B67), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: _buildAvatar(rep, 28.r, isDark),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14.w,
                            height: 14.w,
                            decoration: BoxDecoration(
                              color: rep.isActive ? const Color(0xFF10B981) : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  rep.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (rep.employeeId.isNotEmpty) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF714B67).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6.r),
                                        border: Border.all(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        rep.employeeId,
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF714B67),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: (rep.isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: (rep.isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      rep.isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: rep.isActive ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            rep.designation,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF714B67),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Section 1: Professional Details Card
              _buildSectionCard(
                context,
                title: 'Professional Details',
                icon: Icons.badge_outlined,
                isDark: isDark,
                children: [
                  _buildDetailRow('Employee ID', rep.employeeId, isDark, isHighlight: true),
                  _buildDivider(isDark),
                  _buildDetailRow('Date of Joining LiveRestro', rep.dateOfJoining, isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('Designation', rep.designation, isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('Added By', rep.addedBy, isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('Assigned Beat Area', rep.territory, isDark),
                ],
              ),
              SizedBox(height: 14.h),

              // Section 2: Contact Information Card
              _buildSectionCard(
                context,
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                isDark: isDark,
                children: [
                  _buildDetailRow('Mobile Number', rep.phone, isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('Email Address', rep.email, isDark),
                ],
              ),
              SizedBox(height: 14.h),

              // Section 3: Field Beat & Territory Card
              _buildSectionCard(
                context,
                title: 'Beat & Territory Assignment',
                icon: Icons.map_outlined,
                isDark: isDark,
                children: [
                  _buildDetailRow('Assigned Beat Area', rep.territory, isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('City HQ', rep.city, isDark),
                ],
              ),
              SizedBox(height: 14.h),

              // Section 4: Performance & Target Progress
              _buildSectionCard(
                context,
                title: 'Target & Daily Performance',
                icon: Icons.track_changes_rounded,
                isDark: isDark,
                children: [
                  _buildDetailRow('Daily Visits Goal', '${rep.visitsTarget} Outlets / Day', isDark),
                  _buildDivider(isDark),
                  _buildDetailRow('Visits Completed Today', '${rep.visitsToday} Visits Done', isDark, statusColor: const Color(0xFF10B981)),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: (rep.visitsTarget > 0 ? (rep.visitsToday / rep.visitsTarget).clamp(0.0, 1.0) : 0.0),
                      minHeight: 8.h,
                      backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              // Bottom Actions: Call & WhatsApp
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(rep.phone),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF714B67),
                        side: const BorderSide(color: Color(0xFF714B67), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      icon: Icon(Icons.call_rounded, size: 17.sp),
                      label: Text('Call Executive', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsApp(rep.phone, rep.name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      icon: Icon(Icons.chat_bubble_rounded, size: 17.sp, color: Colors.white),
                      label: Text('WhatsApp', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: const Color(0xFF714B67)),
              SizedBox(width: 7.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isHighlight = false, Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: statusColor ?? (isHighlight ? const Color(0xFF714B67) : (isDark ? Colors.white : const Color(0xFF1E293B))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(TeamMemberModel rep, double radius, bool isDark) {
    return CustomAvatar(
      imageUrl: rep.avatarUrl,
      name: rep.name,
      size: radius * 2,
      userId: rep.id,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 8.h, color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMembers = ref.watch(teamMembersProvider);
    final isLoading = ref.watch(teamLoadingProvider);
    final errorMessage = ref.watch(teamErrorProvider);

    final executives = allMembers.where((m) => m.role == AppUserRole.salesExecutive).toList();

    // Calculate real dynamic metrics directly from PostgreSQL records
    final totalRegistered = executives.length;
    final activeCount = executives.where((e) => e.isActive).length;
    final inactiveCount = executives.where((e) => !e.isActive).length;

    String dailyTargetGoalText;
    if (executives.isNotEmpty) {
      final targets = executives.map((e) => e.visitsTarget > 0 ? e.visitsTarget : 8).toList();
      final allSame = targets.every((t) => t == targets.first);
      if (allSame) {
        dailyTargetGoalText = '${targets.first} / Rep';
      } else {
        final avg = (targets.reduce((a, b) => a + b) / targets.length).round();
        dailyTargetGoalText = '$avg / Rep';
      }
    } else {
      dailyTargetGoalText = '0 / Rep';
    }

    // Filter by search & status
    final filteredExecutives = executives.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.phone.contains(_searchQuery) ||
          m.territory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.email.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_filterStatus == 'ACTIVE') return matchesSearch && m.isActive;
      if (_filterStatus == 'INACTIVE') return matchesSearch && !m.isActive;
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Registered Sales Executives',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Add New Sales Executive',
            icon: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1E3A8A), size: 20),
            ),
            onPressed: () {
              RegisterExecutiveModal.show(context).then((_) {
                ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
              });
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamMembersProvider.notifier).fetchTeamFromBackend(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Summary Metrics Header Card
              _buildMetricsHeader(totalRegistered, activeCount, inactiveCount, dailyTargetGoalText, isDark),
              SizedBox(height: 16.h),

              // Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by Name, EMP ID, Phone, Beat...',
                  hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Filter Chips Row
              Row(
                children: [
                  _buildFilterChip('All Executives ($totalRegistered)', 'ALL', isDark),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Active ($activeCount)', 'ACTIVE', isDark),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Inactive ($inactiveCount)', 'INACTIVE', isDark),
                ],
              ),
              SizedBox(height: 16.h),

              // Executive List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Executive Member Records (${filteredExecutives.length})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Tap to inspect',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              if (isLoading && executives.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                )
              else if (errorMessage != null && executives.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 36.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_off_rounded, size: 42.sp, color: Colors.red),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Unable to load Sales Executives. Please try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('Retry', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else if (filteredExecutives.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 36.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF714B67).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people_outline_rounded, size: 42.sp, color: const Color(0xFF714B67)),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No Executives Found'
                            : 'No Sales Executives Registered',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No sales executive records matched "$_searchQuery".'
                            : 'Start by registering your first Sales Executive under your management team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 18.h),
                      if (_searchQuery.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear Search'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            RegisterExecutiveModal.show(context).then((_) {
                              ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF714B67),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: Text('Register First Sales Executive', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                )
              else
                ...filteredExecutives.map((rep) => _buildExecutiveCard(context, rep, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsHeader(int total, int active, int inactive, String dailyTargetGoal, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFF93C5FD), size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    'Manager Team Overview',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text('LiveRestro CRM', style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildMetricTile('Registered', '$total', Icons.groups_rounded),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricTile('Active', '$active', Icons.person_outline_rounded),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildMetricTile('Inactive', '$inactive', Icons.person_off_outlined),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricTile('Daily Goal', dailyTargetGoal, Icons.track_changes_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF93C5FD)),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              height: 1.1,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveCard(BuildContext context, TeamMemberModel rep, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: () => _showExecutiveDetailsSheet(context, rep, isDark),
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name, Employee ID badge, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(rep, 24.r, isDark),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  rep.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (rep.employeeId.isNotEmpty) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6.r),
                                        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        rep.employeeId,
                                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
                                    decoration: BoxDecoration(
                                      color: (rep.isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: (rep.isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      rep.isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: rep.isActive ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${rep.designation} • Joined ${rep.dateOfJoining}',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Middle Info: Territory, Mobile, Target
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${rep.territory}, ${rep.city}',
                              style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 14.sp, color: const Color(0xFF10B981)),
                          SizedBox(width: 6.w),
                          Text(
                            rep.phone,
                            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                          const Spacer(),
                          Text(
                            'Target: ${rep.visitsToday}/${rep.visitsTarget} visits',
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Bottom Action Buttons: Call, WhatsApp, View Details
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(rep.phone),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                        ),
                        icon: Icon(Icons.call_rounded, size: 14.sp),
                        label: Text('Call', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendWhatsApp(rep.phone, rep.name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          elevation: 1,
                        ),
                        icon: Icon(Icons.chat_bubble_rounded, size: 14.sp, color: Colors.white),
                        label: Text('WhatsApp', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      tooltip: 'View Full Profile Details',
                      onPressed: () => _showExecutiveDetailsSheet(context, rep, isDark),
                      icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF714B67)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
