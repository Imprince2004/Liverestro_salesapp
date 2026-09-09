import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../../leads/presentation/screens/lead_list_screen.dart';
import '../../../profile/presentation/screens/check_in_screen.dart';
import '../../../profile/presentation/screens/documents_hub_screen.dart';
import '../../../profile/presentation/screens/help_support_screen.dart';
import '../../../profile/presentation/screens/leaderboard_screen.dart';
import '../../../profile/presentation/screens/my_profile_detail_screen.dart';
import '../../../profile/presentation/screens/notification_hub_screen.dart';
import '../../../profile/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../profile/presentation/screens/settings_hub_screen.dart';
import '../../../restaurants/presentation/screens/restaurant_search_screen.dart';
import '../../../restaurants/presentation/screens/nearby_food_places_screen.dart';
import '../../../visits/presentation/screens/visit_list_screen.dart';
import '../../../visits/presentation/providers/visit_providers.dart';
import '../../../leads/presentation/screens/follow_ups_screen.dart';
import '../../../leads/presentation/providers/follow_ups_provider.dart';
import '../../../tracking/presentation/screens/gps_tracking_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../tasks/presentation/screens/tasks_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../profile/presentation/screens/product_catalog_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../leads/presentation/screens/create_lead_screen.dart';
import '../../../visits/presentation/screens/start_visit_screen.dart';
import '../../../orders/presentation/screens/pos_software_orders_screen.dart';
import '../../../auth/presentation/screens/admin_pin_reset_requests_modal.dart';
import '../../../manager/data/models/admin_models.dart';
import '../../../manager/presentation/providers/role_providers.dart';
import '../../../manager/presentation/screens/super_admin_hub_screen.dart';
import '../../../manager/presentation/screens/manager_hub_screen.dart';
import '../../../tasks/presentation/screens/manager_task_assignment_modal.dart';
import '../../../manager/presentation/screens/register_executive_modal.dart';
import '../../../manager/presentation/screens/team_executive_list_screen.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../targets/presentation/providers/target_providers.dart';
import '../../../targets/presentation/screens/monthly_target_implementation_screen.dart';
import '../../../targets/data/models/monthly_target_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final activeRole = ref.watch(activeRoleProvider);
    final rawRole = (user?.role ?? '').toUpperCase();
    final designation = (user?.designation ?? '').toLowerCase();

    final isAdmin = rawRole == 'SUPER_ADMIN' ||
        rawRole == 'COMPANY_ADMIN' ||
        rawRole.contains('ADMIN') ||
        designation.contains('admin') ||
        activeRole == AppUserRole.superAdmin ||
        activeRole == AppUserRole.companyAdmin;

    final isManager = !isAdmin && (rawRole == 'SALES_MANAGER' ||
        rawRole.contains('MANAGER') ||
        designation.contains('manager') ||
        activeRole == AppUserRole.salesManager);

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildDashboardHome(context),
          const LeadListScreen(),
          isAdmin
              ? const ManagerHubScreen()
              : (isManager ? const TeamExecutiveListScreen() : const VisitListScreen()),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndex,
        isAdmin: isAdmin,
        isManager: isManager,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeRole = ref.watch(activeRoleProvider);
    final rawRole = (user?.role ?? '').toUpperCase();
    final designation = (user?.designation ?? '').toLowerCase();

    final isAdmin = rawRole == 'SUPER_ADMIN' ||
        rawRole == 'COMPANY_ADMIN' ||
        rawRole.contains('ADMIN') ||
        designation.contains('admin') ||
        activeRole == AppUserRole.superAdmin ||
        activeRole == AppUserRole.companyAdmin;

    final isManager = !isAdmin && (rawRole == 'SALES_MANAGER' ||
        rawRole.contains('MANAGER') ||
        designation.contains('manager') ||
        activeRole == AppUserRole.salesManager);

    if (isAdmin) {
      return _buildAdminManagementDashboard(context, isDark);
    }

    final topPadding = MediaQuery.of(context).padding.top;

    final leadsAsync = ref.watch(leadListProvider);
    final totalLeadsCount = leadsAsync.value?.length ?? 0;
    final now = DateTime.now();
    final newLeadsCount = (leadsAsync.value ?? []).where((l) {
      final dt = DateTime.tryParse(l.createdAt);
      if (dt == null) return false;
      return now.difference(dt).inHours < 24;
    }).length;

    final assignedTasks = ref.watch(myAssignedTasksProvider);
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);
    final visitsAsync = ref.watch(visitListProvider);
    final myTargetAsync = ref.watch(myMonthlyTargetProvider);

    final followUpsState = ref.watch(followUpsProvider);
    final followUpsDueCount = followUpsState.todayCount + followUpsState.overdueCount;

    final hive = getIt<HiveStorageService>();
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (hive.get<String>('user_name') ?? 'User');

    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good afternoon,';
    } else {
      timeGreeting = 'Good evening,';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0D1B) : const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16.w,
                topPadding + (isManager ? 24.h : 10.h),
                16.w,
                isManager ? 24.h : 16.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF281F33) : const Color(0xFF714B67),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Greeting & Actions Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting & Name Column on Left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeGreeting,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Theme Switcher Button
                      GestureDetector(
                        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                        child: Container(
                          padding: EdgeInsets.all(8.5.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.nightlight_round,
                            color: Colors.white,
                            size: 17.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Notifications Bell with Live Counter Badge
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationHubScreen(),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(8.5.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 19.sp,
                              ),
                              if (unreadNotifCount > 0)
                                Positioned(
                                  right: -3,
                                  top: -3,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4.5.w, vertical: 1.5.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF281F33) : const Color(0xFF714B67),
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: BoxConstraints(minWidth: 14.w, minHeight: 14.w),
                                    child: Center(
                                      child: Text(
                                        unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5.sp,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // User Avatar on Right (tap to view profile)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyProfileDetailScreen()),
                          ).then((_) {
                            ref.read(authNotifierProvider.notifier).refreshProfile();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.8.w),
                          ),
                          child: Builder(
                            builder: (context) {
                              final userId = user?.id ?? hive.get<String>('user_id') ?? '';
                              final savedPath = (userId.isNotEmpty)
                                  ? hive.get<String>('user_profile_image_path_$userId')
                                  : null;
                              if (savedPath != null && File(savedPath).existsSync()) {
                                return CircleAvatar(
                                  radius: 20.r,
                                  backgroundImage: FileImage(File(savedPath)),
                                );
                              } else if (user?.profilePhoto != null && user!.profilePhoto.isNotEmpty && user.profilePhoto.startsWith('http')) {
                                return CircleAvatar(
                                  radius: 20.r,
                                  backgroundImage: NetworkImage(user.profilePhoto),
                                );
                              } else {
                                final initial = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';
                                return CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isManager) ...[
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        // Card 1: Today's Tasks
                        Expanded(
                          child: _buildHeaderMetricCard(
                            icon: Icons.task_alt_rounded,
                            value: '${assignedTasks.length}',
                            label: "Today's Tasks",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TasksScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Card 2: Follow-Ups Due
                        Expanded(
                          child: _buildHeaderMetricCard(
                            icon: Icons.event_repeat_rounded,
                            value: '$followUpsDueCount',
                            label: 'Follow-Ups Due',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FollowUpsScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Card 3: Active Leads
                        Expanded(
                          child: _buildHeaderMetricCard(
                            icon: Icons.storefront_rounded,
                            value: '$totalLeadsCount',
                            label: 'Active Leads',
                            onTap: () => setState(() => _navIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Dynamic Role Command Center Banners (Strictly isolated by authenticated backend role)
                  if (rawRole == 'SUPER_ADMIN' || activeRole == AppUserRole.superAdmin) ...[
                    _buildSuperAdminBanner(context, isDark),
                    SizedBox(height: 16.h),
                  ] else if (rawRole == 'COMPANY_ADMIN' || activeRole == AppUserRole.companyAdmin) ...[
                    _buildCompanyAdminBanner(context, isDark),
                    SizedBox(height: 16.h),
                  ] else if (isManager) ...[
                    _buildSalesManagerBanner(context, isDark),
                    SizedBox(height: 16.h),
                  ],

                  // Quick Power Actions Strip (1-Tap Fast Actions)
                  _buildQuickPowerActionsStrip(context, isDark),
                  SizedBox(height: 16.h),

                  // Dedicated Sales Manager Assigned Tasks Section
                  _buildAssignedTasksByManagerSection(context, isDark, assignedTasks),
                  SizedBox(height: 16.h),

                  // Dynamic Monthly Target & Implementation Progress Module (Live Database-Driven)
                  _buildMonthlyTargetAndImplementationModule(context, isDark),
                  SizedBox(height: 18.h),



                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Key Performance Metrics',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Summary Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 1.12,
                    children: [
                      _buildSummaryCard(
                        'Visits Today',
                        '${visitsAsync.value?.length ?? 0}',
                        'Live Beat',
                        Icons.location_on_rounded,
                        const Color(0xFF6366F1),
                        isDark,
                        progress: 0.8,
                        onTap: () => setState(() => _navIndex = 2),
                      ),
                      _buildSummaryCard(
                        'Active Leads',
                        '$totalLeadsCount',
                        '+$newLeadsCount New',
                        Icons.group_add_rounded,
                        const Color(0xFFF59E0B),
                        isDark,
                        progress: 0.65,
                        onTap: () => setState(() => _navIndex = 1),
                      ),
                      _buildSummaryCard(
                        'Follow Ups',
                        '$followUpsDueCount',
                        '${followUpsState.todayCount} Due Today',
                        Icons.access_time_filled_rounded,
                        const Color(0xFF3B82F6),
                        isDark,
                        progress: 0.5,
                        onTap: () => _showFollowUpsSheet(context, isDark),
                      ),
                      _buildSummaryCard(
                        'Target Goal',
                        '${myTargetAsync.value?.progressPercent ?? 0}%',
                        'Target: ${myTargetAsync.value?.targetLeads ?? 0}',
                        Icons.pie_chart_rounded,
                        const Color(0xFF10B981),
                        isDark,
                        progress: ((myTargetAsync.value?.progressPercent ?? 0) / 100).clamp(0.0, 1.0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MonthlyTargetImplementationScreen(initialTabIndex: 0),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  _buildMainModules(context),

                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 6.w),
                          Text(
                            'Today\'s Beat Schedule',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => _navIndex = 2),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  visitsAsync.when(
                    data: (visits) {
                      if (visits.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.event_available_rounded, size: 36.sp, color: Colors.grey[400]),
                              SizedBox(height: 8.h),
                              Text(
                                'No scheduled beat visits for today',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Use Start Visit or Near Cafes to record your client visits.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: visits.map((visit) {
                          final status = visit.status.isNotEmpty ? visit.status : 'Scheduled';
                          Color statusColor = const Color(0xFFF59E0B);
                          if (status.toUpperCase().contains('COMPLET')) {
                            statusColor = const Color(0xFF10B981);
                          } else if (status.toUpperCase().contains('PROGRESS')) {
                            statusColor = const Color(0xFF3B82F6);
                          } else if (status.toUpperCase().contains('CANCEL')) {
                            statusColor = const Color(0xFFEF4444);
                          }

                          final timeStr = visit.startTime.isNotEmpty ? visit.startTime : '10:00 AM';
                          const phoneStr = '+91 98250 12345';

                          return _buildScheduleItem(
                            timeStr,
                            visit.restaurantName,
                            visit.address,
                            phoneStr,
                            status,
                            statusColor,
                            isDark,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (_, __) => Column(
                      children: [
                        _buildScheduleItem(
                          '10:00 AM',
                          'Spice Junction Fine Dine',
                          'Plot 42, Mg Road, Connaught Place',
                          '+91 98250 12345',
                          'Completed',
                          const Color(0xFF10B981),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white.withValues(alpha: 0.9)),
            SizedBox(height: 4.h),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPowerActionsStrip(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildPowerActionBtn(
                label: 'New Lead',
                icon: Icons.person_add_alt_1_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateLeadScreen()),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPowerActionBtn(
                label: 'Near Cafes',
                icon: Icons.storefront_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyFoodPlacesScreen()),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPowerActionBtn(
                label: 'Tasks',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPowerActionBtn(
                label: 'AI Pitch',
                icon: Icons.auto_awesome_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerActionBtn({
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE8EAF2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedTasksByManagerSection(BuildContext context, bool isDark, List<TaskModel> assignedTasks) {
    if (assignedTasks.isEmpty) return const SizedBox.shrink();

    final pendingTasks = assignedTasks.where((t) => t.status.toUpperCase() != 'COMPLETED').toList();
    final displayTasks = pendingTasks.isNotEmpty ? pendingTasks : assignedTasks.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF714B67).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF714B67), size: 18),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Tasks from Sales Manager',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (pendingTasks.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${pendingTasks.length} New',
                        style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TasksScreen()),
              ),
              child: Text(
                'View All (${assignedTasks.length})',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...displayTasks.map((task) {
          final isDone = task.status.toUpperCase() == 'COMPLETED';
          final cleanDueDate = task.dueDate.contains('T')
              ? task.dueDate.split('T')[0]
              : task.dueDate;
          Color priorityColor = const Color(0xFF10B981);
          if (task.priority.toUpperCase() == 'HIGH' || task.priority.toUpperCase() == 'URGENT') {
            priorityColor = const Color(0xFFEF4444);
          } else if (task.priority.toUpperCase() == 'MEDIUM') {
            priorityColor = const Color(0xFFF59E0B);
          }

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2D1F2A), AppColors.surfaceDark]
                    : [const Color(0xFFFDF8FC), Colors.white],
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.35 : 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Manager Attribution Pill (Safe Row constraints to prevent overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF714B67).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.supervisor_account_rounded, size: 13.sp, color: const Color(0xFF714B67)),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                'Assigned by Manager: ${task.managerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF714B67),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Restaurant & Task Info
                if (task.restaurantName.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF714B67),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.restaurant_rounded, color: Colors.white, size: 14.sp),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.restaurantName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            if (task.location.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 12.sp, color: Colors.grey[500]),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      task.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],

                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                ],

                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 11.sp, color: Colors.grey[500]),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Due Date: $cleanDueDate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        isDone ? 'COMPLETED' : 'PENDING ACTION',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.bold,
                          color: isDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),

                // Direct Action Buttons
                if (!isDone) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (task.restaurantName.isNotEmpty) ...[
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StartVisitScreen(
                                    restaurantName: task.restaurantName,
                                    address: task.location.isNotEmpty ? task.location : 'Assigned Beat Location',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.rocket_launch_rounded, size: 14.sp),
                            label: Text(
                              'Start Visit Now',
                              style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          onPressed: () async {
                            final ok = await ref.read(taskListProvider.notifier).updateStatus(task.id, 'COMPLETED');
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Task marked as Completed!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.check_circle_outline_rounded, size: 14.sp),
                          label: Text(
                            'Mark Done',
                            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthlyTargetAndImplementationModule(BuildContext context, bool isDark) {
    final targetAsync = ref.watch(myMonthlyTargetProvider);
 
    return targetAsync.when(
      data: (target) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(22.r),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyTargetImplementationScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Month Name and "View Details"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: const Icon(Icons.track_changes_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${target.monthName} ${target.year} Target',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      'Assigned by: ${target.assignedByName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${target.progressPercent}%',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
 
                    SizedBox(height: 14.h),
 
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: (target.progressPercent / 100).clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        color: const Color(0xFF10B981),
                        minHeight: 8.h,
                      ),
                    ),
 
                    SizedBox(height: 12.h),
 
                    // Target Stats Strip (Clean 3-column Layout without icons)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Target',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${target.targetLeads}',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Leads Assigned',
                                style: TextStyle(fontSize: 9.5.sp, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32.h, color: isDark ? Colors.white24 : Colors.grey[300]),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Completed',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${target.completedLeads}',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Leads Closed',
                                style: TextStyle(fontSize: 9.5.sp, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32.h, color: isDark ? Colors.white24 : Colors.grey[300]),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Remaining',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${target.remainingLeads}',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'To Reach 100%',
                                style: TextStyle(fontSize: 9.5.sp, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }



  Widget _buildSummaryCard(
    String label,
    String count,
    String badgeText,
    IconData icon,
    Color accentColor,
    bool isDark, {
    double progress = 0.7,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.22),
                            accentColor.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(icon, color: accentColor, size: 16.sp),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10.sp,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3.h,
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  void _showFollowUpsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_filled_rounded,
                          color: const Color(0xFF3B82F6),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Follow-Up Actions',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '2 Due Today',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              _buildFollowUpItem(
                'The Royal Spice Fine Dine',
                'Owner: Amit Patel • POS Upgrade discussion',
                '03:00 PM Today',
                const Color(0xFFF59E0B),
                isDark,
              ),
              SizedBox(height: 10.h),
              _buildFollowUpItem(
                'Tandoori Treat Dine & Bar',
                'Owner: Suresh Shah • Demo feedback & pricing',
                '05:30 PM Today',
                const Color(0xFF10B981),
                isDark,
              ),
              SizedBox(height: 10.h),
              _buildFollowUpItem(
                'Tea Post - Desi Cafe',
                'Owner: Bhavesh Shah • Contract signature visit',
                'Tomorrow 11:00 AM',
                const Color(0xFF6366F1),
                isDark,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _navIndex = 2);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    'Open Visit Calendar',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowUpItem(
    String restaurantName,
    String subtitle,
    String timeDue,
    Color tagColor,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12.sp, color: tagColor),
                    SizedBox(width: 4.w),
                    Text(
                      timeDue,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: tagColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.phone_rounded, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling $restaurantName...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildMainModules(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modules = [
      {'title': 'Dashboard', 'icon': Icons.bar_chart_rounded, 'color': const Color(0xFF5B3FD4)},
      {'title': 'POS Clients', 'icon': Icons.point_of_sale_rounded, 'color': const Color(0xFFF97316)},
      {'title': 'Restaurants', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFFF7A00)},
      {'title': 'Leads', 'icon': Icons.person_search_rounded, 'color': const Color(0xFF00BFA5)},
      {'title': 'Follow Ups', 'icon': Icons.access_time_rounded, 'color': const Color(0xFF4A90E2)},
      {'title': 'Attendance', 'icon': Icons.lock_person_rounded, 'color': const Color(0xFF00ACC1)},
      {'title': 'GPS Tracking', 'icon': Icons.location_on_rounded, 'color': const Color(0xFFF44336)},
      {'title': 'Reports', 'icon': Icons.description_rounded, 'color': const Color(0xFF3F51B5)},
      {'title': 'Calendar', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFFFFB300)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MAIN MODULES',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${modules.length} Services',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[500],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.82,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final Color color = module['color'] as Color;

              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () =>
                      _handleModuleTap(context, module['title'] as String),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          module['icon'] as IconData,
                          color: color,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        module['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleModuleTap(BuildContext context, String title) {
    HapticFeedback.lightImpact();
    if (title == 'POS Clients') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PosSoftwareOrdersScreen()),
      );
    } else if (title == 'Restaurants') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantSearchScreen()),
      );
    } else if (title == 'Attendance') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CheckInScreen()),
      );
    } else if (title == 'Leads') {
      setState(() => _navIndex = 1); // Switch to Leads tab
    } else if (title == 'Follow Ups') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FollowUpsScreen()),
      );
    } else if (title == 'GPS Tracking') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GpsTrackingScreen()),
      );
    } else if (title == 'Calendar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarScreen()),
      );
    } else if (title == 'Tasks') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TasksScreen()),
      );
    } else if (title == 'AI Assistant') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
      );
    } else if (title == 'Reports') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      );
    } else if (title == 'Notifications') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationHubScreen()),
      );
    } else if (title == 'Documents') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentsHubScreen()),
      );
    } else if (title == 'Products') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
      );
    } else if (title == 'Settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
      );
    } else if (title == 'Leader Board' || title == 'Dashboard') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
      );
    } else if (title == 'Targets' || title == 'Monthly Target' || title == 'Implementation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MonthlyTargetImplementationScreen()),
      );
    } else if (title == 'Support') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
      );
    } else if (title == 'Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyProfileDetailScreen()),
      );
    } else if (title == 'More') {
      setState(() => _navIndex = 3); // Switch to Profile/More tab
    }
  }

  Widget _buildScheduleItem(
    String time,
    String title,
    String location,
    String phone,
    String status,
    Color statusColor,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 18),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                  final uri = Uri.parse('tel:$cleanPhone');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 10.w),
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: Color(0xFF6366F1), size: 18),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final query = Uri.encodeComponent('$title, $location');
                  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminBanner(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.4 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF714B67).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.admin_panel_settings_rounded, color: const Color(0xFF714B67), size: 18.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Super Admin HQ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'GLOBAL VIEW',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Multi-City Revenue, User & RBAC Management, POS Rate Cards, and Audit Trail Stream.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminHubScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: const Text('Open Super Admin HQ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF714B67),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAdminBanner(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.4 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF714B67).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.business_center_rounded, color: const Color(0xFF714B67), size: 18.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Company Admin Portal',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'ORGANIZATION HQ',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Organization Profile, Sales Managers, Field Executives, Price Lists, and Outlet Operations.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagerHubScreen()),
                    );
                  },
                  icon: const Icon(Icons.people_alt_rounded, size: 15),
                  label: const Text('Manage Team'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    textStyle: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ManagerTaskAssignmentModal.show(context);
                  },
                  icon: Icon(Icons.assignment_add, size: 14.sp, color: const Color(0xFF714B67)),
                  label: Text('Task', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AdminPinResetRequestsModal.show(context);
                  },
                  icon: Icon(Icons.lock_reset_rounded, size: 14.sp, color: const Color(0xFFF97316)),
                  label: Text('PIN Resets', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF97316))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesManagerBanner(BuildContext context, bool isDark) {
    final teamMembers = ref.watch(teamMembersProvider);
    final execCount = teamMembers.where((m) => m.role == AppUserRole.salesExecutive).length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.4 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF714B67).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.manage_accounts_rounded, color: const Color(0xFF714B67), size: 18.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Sales Manager (ASM)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'TERRITORY RADAR',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Live Field Rep GPS Radar, Registered Executive Details, and Lead Assignment Hub.',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            ),
          ),
          SizedBox(height: 12.h),

          // Primary Featured Action: View Registered Sales Executives Details
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeamExecutiveListScreen()),
                );
              },
              icon: const Icon(Icons.people_alt_rounded, size: 16),
              label: Text('View Registered Sales Executives ($execCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF714B67),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Secondary Quick Actions (Equally aligned 3-column row without PIN Resets)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagerHubScreen()),
                    );
                  },
                  icon: Icon(Icons.radar_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                  label: Text(
                    'Live Radar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    RegisterExecutiveModal.show(context);
                  },
                  icon: Icon(Icons.person_add_alt_1_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                  label: Text(
                    'Register Rep',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ManagerTaskAssignmentModal.show(context);
                  },
                  icon: Icon(Icons.assignment_add, size: 14.sp, color: const Color(0xFF714B67)),
                  label: Text(
                    'Task',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEDICATED ADMIN MANAGEMENT CONTROL CENTER
  // ==========================================
  Widget _buildAdminManagementDashboard(BuildContext context, bool isDark) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final topPadding = MediaQuery.of(context).padding.top;
    final teamMembers = ref.watch(teamMembersProvider);
    final leadsAsync = ref.watch(leadListProvider);
    final totalLeadsCount = leadsAsync.value?.length ?? 0;
    final myTargetAsync = ref.watch(myMonthlyTargetProvider);
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

    final managersCount = teamMembers.where((m) => m.role == AppUserRole.salesManager).length;
    final execsCount = teamMembers.where((m) => m.role == AppUserRole.salesExecutive).length;
    final activeUsersCount = teamMembers.where((m) => m.isActive).length;

    final hive = getIt<HiveStorageService>();
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (hive.get<String>('user_name') ?? 'System Admin');

    final hour = DateTime.now().hour;
    String timeGreeting = (hour >= 5 && hour < 12)
        ? 'Good morning,'
        : (hour >= 12 && hour < 17)
            ? 'Good afternoon,'
            : 'Good evening,';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0D1B) : const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Admin Executive Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, topPadding + 10.h, 16.w, 16.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF281F33) : const Color(0xFF714B67),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Greeting & Actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeGreeting,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 19.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCD34D),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'ADMIN HQ',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF3B0764),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Theme Switcher
                      GestureDetector(
                        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                        child: Container(
                          padding: EdgeInsets.all(8.5.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.nightlight_round,
                            color: Colors.white,
                            size: 17.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Notifications Bell
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationHubScreen()),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(8.5.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.notifications_outlined, color: Colors.white, size: 19.sp),
                              if (unreadNotifCount > 0)
                                Positioned(
                                  right: -3,
                                  top: -3,
                                  child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(minWidth: 13.w, minHeight: 13.w),
                                    child: Text(
                                      unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                                      style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // User Avatar
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyProfileDetailScreen()),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.8.w),
                          ),
                          child: CircleAvatar(
                            radius: 19.r,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'A',
                              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Admin High-Level 3 Metric KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderMetricCard(
                          icon: Icons.groups_rounded,
                          value: '${teamMembers.length}',
                          label: 'Team Members',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TeamExecutiveListScreen()),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildHeaderMetricCard(
                          icon: Icons.track_changes_rounded,
                          value: '${myTargetAsync.value?.progressPercent ?? 0}%',
                          label: 'Org Target Goal',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MonthlyTargetImplementationScreen(initialTabIndex: 0)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildHeaderMetricCard(
                          icon: Icons.storefront_rounded,
                          value: '$totalLeadsCount',
                          label: 'Pipeline Leads',
                          onTap: () => setState(() => _navIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Admin Control Hub Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Section 1: Team & User Governance Card
                  _buildAdminUserGovernanceSection(context, isDark, managersCount, execsCount, activeUsersCount),
                  SizedBox(height: 14.h),

                  // Section 2: Organization Target & Achievement Hub
                  _buildAdminTargetManagementSection(context, isDark, myTargetAsync),
                  SizedBox(height: 14.h),

                  // Section 3: Task & Implementation Assignment Module
                  _buildAdminTaskAssignmentSection(context, isDark),
                  SizedBox(height: 14.h),

                  // Section 4: Security & PIN Reset Approvals
                  _buildAdminPinResetSection(context, isDark),
                  SizedBox(height: 14.h),

                  // Section 5: Live Radar & Monitoring
                  _buildAdminMonitoringRadarSection(context, isDark, execsCount),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminUserGovernanceSection(
    BuildContext context,
    bool isDark,
    int managersCount,
    int execsCount,
    int activeUsersCount,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF714B67).withValues(alpha: isDark ? 0.35 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF714B67), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User & Role Management',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$managersCount Sales Managers • $execsCount Sales Executives',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '$activeUsersCount Active',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Register new employees, activate/deactivate accounts, assign designation, and manage territories across the organization.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeamExecutiveListScreen()),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                    label: const Text('Manage Users & Roles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF714B67),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton.icon(
                    onPressed: () => RegisterExecutiveModal.show(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('+ Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF714B67),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTargetManagementSection(
    BuildContext context,
    bool isDark,
    AsyncValue<MonthlyTargetModel> myTargetAsync,
  ) {
    final target = myTargetAsync.value;
    final progress = target?.progressPercent ?? 0;
    final targetLeads = target?.targetLeads ?? 30;
    final targetVisits = target?.targetVisits ?? 80;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.track_changes_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Target Management',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Goal: $targetLeads Leads • $targetVisits Visits',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '$progress% Achieved',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 7.h,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyTargetImplementationScreen(initialTabIndex: 0)),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text('Manage & Assign Monthly Targets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                textStyle: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTaskAssignmentSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.assignment_add, color: Color(0xFF10B981), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task & Activity Assignment',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Demo • Setup • Training • Custom Activities',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Assign high-priority tasks and lead activities to Sales Managers or directly to Sales Executives backed by live database verification.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ManagerTaskAssignmentModal.show(context),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text('Assign Team Task / Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                textStyle: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPinResetSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.35 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF97316), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN Reset Requests & Approvals',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Admin PIN Verification Required',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Review employee requests to reset forgotten security PINs. Enter Admin PIN to approve requests securely.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AdminPinResetRequestsModal.show(context),
              icon: const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFFF97316)),
              label: const Text('Review PIN Reset Requests', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF97316)),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMonitoringRadarSection(BuildContext context, bool isDark, int execsCount) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E192B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.35 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.radar_rounded, color: Color(0xFF3B82F6), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Team Radar & Analytics',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'GPS Tracking & Performance Reports',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Monitor real-time field executive GPS locations, battery percentages, visit beats, and executive sales reports.',
            style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600]),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagerHubScreen()),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Live Team Radar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    textStyle: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.analytics_rounded, size: 16, color: Color(0xFF3B82F6)),
                  label: const Text('Reports', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

