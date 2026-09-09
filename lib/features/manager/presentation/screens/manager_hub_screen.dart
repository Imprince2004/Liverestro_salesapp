import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../data/models/admin_models.dart';
import '../providers/role_providers.dart';
import 'register_executive_modal.dart';
import '../../../orders/presentation/screens/pos_software_orders_screen.dart';

class ManagerHubScreen extends ConsumerStatefulWidget {
  const ManagerHubScreen({super.key});

  @override
  ConsumerState<ManagerHubScreen> createState() => _ManagerHubScreenState();
}

class _ManagerHubScreenState extends ConsumerState<ManagerHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendWhatsApp(String phone, String name) async {
    final msg = Uri.encodeComponent('Hi $name, checking in on your morning beat progress. How is the lead pipeline?');
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Manager Top Header
          Container(
            padding: EdgeInsets.fromLTRB(16.w, topPadding + 10.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E192B) : AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.manage_accounts_rounded, color: Color(0xFF93C5FD), size: 18),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  'Sales Manager (ASM)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Territory Command & Field Team Radar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'RADAR ON',
                            style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  physics: const BouncingScrollPhysics(),
                  indicatorColor: const Color(0xFF93C5FD),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 11.5.sp),
                  tabs: const [
                    Tab(icon: Icon(Icons.radar_rounded, size: 16), text: 'Live Rep Radar'),
                    Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 16), text: 'Lead Assign'),
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 16), text: 'Team Board'),
                    Tab(icon: Icon(Icons.verified_user_rounded, size: 16), text: 'Approvals'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveRadarTab(isDark),
                _buildLeadAssignTab(isDark),
                _buildTeamLeaderboardTab(isDark),
                _buildApprovalsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: LIVE REP GPS RADAR & ATTENDANCE
  // ==========================================
  Widget _buildLiveRadarTab(bool isDark) {
    final members = ref.watch(teamMembersProvider);
    final fieldReps = members.where((m) => m.role == AppUserRole.salesExecutive).toList();

    final onDutyCount = fieldReps.where((r) => r.isActive && (r.currentStatus == 'On Visit' || r.currentStatus == 'Traveling' || r.visitsToday > 0)).length;
    final totalCount = fieldReps.length;
    final activeCount = fieldReps.where((r) => r.isActive).length;
    final totalVisits = fieldReps.fold<int>(0, (sum, r) => sum + r.visitsToday);
    final targetSum = fieldReps.fold<int>(0, (sum, r) => sum + (r.visitsTarget > 0 ? r.visitsTarget : 8));
    final targetPercent = targetSum > 0 ? ((totalVisits / targetSum) * 100).round() : 0;

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // Territory Live Stats Row
        Row(
          children: [
            Expanded(
              child: _buildRadarStatCard(
                title: 'On-Duty Field Reps',
                value: '$onDutyCount/$totalCount',
                subtitle: fieldReps.isEmpty ? 'No reps assigned' : '$activeCount Active Reps',
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildRadarStatCard(
                title: 'Total Visits Logged',
                value: '$totalVisits Visits',
                subtitle: fieldReps.isEmpty ? '0% Target' : '$targetPercent% Daily Target Met',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // POS Software Subscriptions & Revenue Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PosSoftwareOrdersScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POS Software Clients & Revenue',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Monitor Free vs Paid POS Subscriptions',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionHeader('Live Rep Radar', Icons.gps_fixed_rounded),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: () => RegisterExecutiveModal.show(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 13),
              label: const Text('+ Register Rep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        if (fieldReps.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.radar_rounded, size: 40.sp, color: Colors.grey[400]),
                SizedBox(height: 10.h),
                Text(
                  'No Sales Executives Registered',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Register sales executives to track their live GPS radar and visits in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...fieldReps.map((rep) {
          final isCheckIn = rep.currentStatus == 'On Visit';
          final statusColor = isCheckIn
              ? const Color(0xFF10B981)
              : (rep.currentStatus == 'Traveling' ? const Color(0xFF3B82F6) : Colors.grey);

          return InkWell(
            onTap: () => _showExecutiveDetailsSheet(context, rep, isDark),
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isCheckIn ? const Color(0xFF10B981).withValues(alpha: 0.5) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  width: isCheckIn ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Rep Avatar, Name, Employee ID, Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomAvatar(
                        imageUrl: rep.avatarUrl,
                        name: rep.name,
                        size: 36.r,
                        userId: rep.id,
                      ),
                      SizedBox(width: 8.w),
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
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5.r),
                                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    rep.employeeId,
                                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${rep.designation} • Joined ${rep.dateOfJoining}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rep.batteryPercent > 50 ? Icons.battery_full_rounded : Icons.battery_charging_full_rounded,
                            size: 14.sp,
                            color: rep.batteryPercent > 30 ? const Color(0xFF10B981) : Colors.red,
                          ),
                          Text(' ${rep.batteryPercent}%', style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold)),
                          SizedBox(width: 5.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              rep.currentStatus,
                              style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Location & Outlet Info
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                rep.currentOutlet,
                                style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                '${rep.territory}, ${rep.city}',
                                style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Rep Day Progress & Action Triggers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visits: ${rep.visitsToday}/${rep.visitsTarget} • ${rep.distanceTraveledKm} km traveled',
                        style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 20),
                            onPressed: () => _makeCall(rep.phone),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 14.w),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 20),
                            onPressed: () => _sendWhatsApp(rep.phone, rep.name),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 10.w),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
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
                          child: CustomAvatar(
                            imageUrl: rep.avatarUrl,
                            name: rep.name,
                            size: 56.r,
                            userId: rep.id,
                          ),
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
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
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

  Widget _buildDivider(bool isDark) {
    return Divider(height: 8.h, color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0));
  }

  // ==========================================
  // TAB 2: LEAD ASSIGNMENT ENGINE
  // ==========================================
  Widget _buildLeadAssignTab(bool isDark) {
    final unassignedLeads = ref.watch(unassignedLeadsProvider);
    final members = ref.watch(teamMembersProvider);
    final fieldReps = members.where((m) => m.role == AppUserRole.salesExecutive).toList();

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Inbound & Spotted Leads Awaiting Assignment', Icons.assignment_ind_rounded),
        SizedBox(height: 10.h),

        if (unassignedLeads.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 40.sp, color: const Color(0xFF10B981)),
                SizedBox(height: 10.h),
                Text(
                  'All Leads Assigned',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  'No spotted or inbound leads are currently pending assignment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...unassignedLeads.map((lead) {
            final isAssigned = lead.assignedRepId != null;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isAssigned ? const Color(0xFF10B981).withValues(alpha: 0.4) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lead.restaurantName,
                          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          lead.source,
                          style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${lead.contactPerson} • ${lead.mobile}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '📍 ${lead.area} (${lead.category})',
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10.h),

                  // Assignment Action
                  if (isAssigned)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          '✓ Assigned to ${lead.assignedRepId}',
                          style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested: ${lead.recommendedRep}',
                          style: TextStyle(fontSize: 10.5.sp, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAssignDialog(lead, fieldReps),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                          label: const Text('Assign Rep'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 3: TEAM LEADERBOARD & BEAT COMPLIANCE
  // ==========================================
  Widget _buildTeamLeaderboardTab(bool isDark) {
    final members = ref.watch(teamMembersProvider);
    final fieldReps = members.where((m) => m.role == AppUserRole.salesExecutive).toList();
    fieldReps.sort((a, b) => b.totalRevenueGenerated.compareTo(a.totalRevenueGenerated));

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionHeader('Territory Rep Leaderboard', Icons.military_tech_rounded),
            ),
            ElevatedButton.icon(
              onPressed: () => RegisterExecutiveModal.show(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
              label: const Text('+ Register Rep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        if (fieldReps.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined, size: 40.sp, color: Colors.grey[400]),
                SizedBox(height: 10.h),
                Text(
                  'No Team Data Yet',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Leaderboard rankings will appear once your sales executives are registered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...List.generate(fieldReps.length, (index) {
            final rep = fieldReps[index];
            final rank = index + 1;
            final rankColor = rank == 1
                ? const Color(0xFFF59E0B)
                : (rank == 2 ? const Color(0xFF94A3B8) : (rank == 3 ? const Color(0xFFB45309) : Colors.grey));

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: rank == 1 ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  width: rank == 1 ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: rankColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rep.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        Text('${rep.closedDealsCount} Deals Won • ${rep.activeLeadsCount} Pipeline',
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(rep.totalRevenueGenerated / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 4: PENDING APPROVALS HUB
  // ==========================================
  Widget _buildApprovalsTab(bool isDark) {
    final approvals = ref.watch(approvalRequestsProvider);

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Pending Rep Discount & Expense Approvals', Icons.verified_user_rounded),
        SizedBox(height: 10.h),

        if (approvals.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_outlined, size: 40.sp, color: const Color(0xFF10B981)),
                SizedBox(height: 10.h),
                Text(
                  'No Pending Approvals',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  'All rep discounts and expense claims have been processed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...approvals.map((appr) {
            final isPending = appr.status == 'Pending';
            final timeStr = DateFormat('hh:mm a').format(appr.requestedAt);

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appr.restaurantName,
                        style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(timeStr, style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Rep: ${appr.repName} • Request: ${appr.requestType}',
                  style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                ),
                SizedBox(height: 4.h),
                Text(
                  appr.amountOrDetails,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 10.h),

                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(approvalRequestsProvider.notifier).reject(appr.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('❌ Request rejected')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(approvalRequestsProvider.notifier).approve(appr.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Approved request successfully!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: appr.status == 'Approved'
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Status: ${appr.status}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: appr.status == 'Approved' ? const Color(0xFF059669) : Colors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Helpers & Modals ---

  Widget _buildRadarStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF2563EB)),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showAssignDialog(UnassignedLeadModel lead, List<TeamMemberModel> reps) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Assign ${lead.restaurantName} to Rep',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...reps.map((rep) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  child: Text(rep.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
                title: Text(rep.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${rep.activeLeadsCount} Active Leads • ${rep.liveLocation}'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  ref.read(unassignedLeadsProvider.notifier).assignLead(lead.id, rep.id, rep.name);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Assigned ${lead.restaurantName} to ${rep.name}!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
