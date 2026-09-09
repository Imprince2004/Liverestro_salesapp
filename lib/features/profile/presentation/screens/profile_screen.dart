import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../manager/data/models/admin_models.dart';
import '../../../manager/presentation/providers/role_providers.dart';
import '../../../manager/presentation/screens/super_admin_hub_screen.dart';
import '../../../manager/presentation/screens/manager_hub_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'my_profile_detail_screen.dart';
import 'product_catalog_screen.dart';
import 'leaderboard_screen.dart';
import 'notification_hub_screen.dart';
import 'settings_hub_screen.dart';
import 'help_support_screen.dart';
import '../../../manager/presentation/screens/team_executive_list_screen.dart';
import '../../../targets/presentation/screens/monthly_target_implementation_screen.dart';
import '../../../tasks/presentation/screens/manager_task_assignment_modal.dart';
import '../../../auth/presentation/screens/admin_pin_reset_requests_modal.dart';
import '../../../reports/presentation/screens/reports_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeRole = ref.watch(activeRoleProvider);

    final hive = getIt<HiveStorageService>();
    final displayName = user?.name ?? hive.get<String>('user_name') ?? 'Prince Chandarana';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, ref, displayName, user, activeRole, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),

                  // Dedicated Portal Banner for Super Admin (Strictly isolated)
                  if ((user?.role == 'SUPER_ADMIN' || activeRole == AppUserRole.superAdmin) && user?.role != 'SALES_EXECUTIVE') ...[
                    _buildSuperAdminPortalCard(context, isDark),
                    SizedBox(height: 16.h),
                  ],

                  _buildMenuSection(context, ref, activeRole, isDark),
                  SizedBox(height: 20.h),
                  _buildLogoutButton(context, ref),
                  SizedBox(height: 18.h),
                  _buildVersionFooter(context),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    WidgetRef ref,
    String name,
    UserEntity? user,
    AppUserRole activeRole,
    bool isDark,
  ) {
    final territory = user?.territory ?? (user?.role == 'SALES_MANAGER' ? 'Ahmedabad Zone Command' : 'Ahmedabad Central');
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 120.h + topPadding,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E192B) : const Color(0xFF714B67),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E192B) : const Color(0xFF714B67),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ambient Decorative Frosted Circles
              Positioned(
                top: -30.h,
                right: -20.w,
                child: Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -20.h,
                left: -20.w,
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Main Header Content
              Positioned(
                left: 18.w,
                right: 18.w,
                top: topPadding + 22.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Executive Avatar with Gold/Emerald Ring
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFCD34D), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Builder(
                              builder: (context) {
                                final hive = getIt<HiveStorageService>();
                                final userId = user?.id ?? hive.get<String>('user_id') ?? '';
                                final savedPath = (userId.isNotEmpty)
                                    ? hive.get<String>('user_profile_image_path_$userId')
                                    : null;
                                if (savedPath != null && File(savedPath).existsSync()) {
                                  return CircleAvatar(
                                    radius: 28.r,
                                    backgroundImage: FileImage(File(savedPath)),
                                  );
                                } else if (user?.profilePhoto != null && user!.profilePhoto.isNotEmpty && user.profilePhoto.startsWith('http')) {
                                  return CircleAvatar(
                                    radius: 28.r,
                                    backgroundImage: NetworkImage(user.profilePhoto),
                                  );
                                } else {
                                  final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
                                  return CircleAvatar(
                                    radius: 28.r,
                                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Icon(Icons.check, size: 9.sp, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14.w),

                    // User Info Columns
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 12.sp, color: const Color(0xFFFCD34D)),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  territory,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              // Role Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(activeRole.icon, size: 10.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      activeRole.displayName,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6.w),
                              // Online Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
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
                                      'Online',
                                      style: TextStyle(
                                        color: const Color(0xFF6EE7B7),
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminPortalCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B0764), Color(0xFF6B21A8), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFDE047), size: 22),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '👑 Super Admin HQ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Multi-City Revenue & RBAC Hub',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminHubScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDE047),
              foregroundColor: const Color(0xFF3B0764),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
            child: const Text('Open HQ'),
          ),
        ],
      ),
    );
  }



  Widget _buildMenuSection(
    BuildContext context,
    WidgetRef ref,
    AppUserRole activeRole,
    bool isDark,
  ) {
    final authUser = ref.watch(authNotifierProvider).user;
    final isAdmin = (authUser?.role == 'SUPER_ADMIN' ||
        authUser?.role == 'COMPANY_ADMIN' ||
        activeRole == AppUserRole.superAdmin ||
        activeRole == AppUserRole.companyAdmin);

    if (isAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'ADMINISTRATION & GOVERNANCE'),
          SizedBox(height: 10.h),
          _buildActionTile(
            context,
            icon: Icons.people_alt_rounded,
            title: 'User & Role Management',
            badgeText: 'ADMIN',
            gradientColors: const [Color(0xFF714B67), Color(0xFF5B3852)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeamExecutiveListScreen()),
            ),
          ),
          _buildActionTile(
            context,
            icon: Icons.track_changes_rounded,
            title: 'Monthly Target Management',
            gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MonthlyTargetImplementationScreen(initialTabIndex: 0)),
            ),
          ),
          _buildActionTile(
            context,
            icon: Icons.assignment_add,
            title: 'Assign Team Tasks & Activities',
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () => ManagerTaskAssignmentModal.show(context),
          ),
          _buildActionTile(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'PIN Reset Requests & Approvals',
            badgeText: 'SECURITY',
            gradientColors: const [Color(0xFFF97316), Color(0xFFEA580C)],
            onTap: () => AdminPinResetRequestsModal.show(context),
          ),
          _buildActionTile(
            context,
            icon: Icons.radar_rounded,
            title: 'Team Live Radar & Monitoring',
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerHubScreen()),
            ),
          ),
          _buildActionTile(
            context,
            icon: Icons.assessment_rounded,
            title: 'Executive Reports & Closed Deals',
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),

          SizedBox(height: 18.h),
          _buildSectionHeader(context, 'ADMIN SETTINGS & SECURITY'),
          SizedBox(height: 10.h),
          _buildActionTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Admin Profile',
            gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProfileDetailScreen()),
            ),
          ),
          _buildActionTile(
            context,
            icon: Icons.settings_outlined,
            title: 'Security, Change PIN & 2FA',
            gradientColors: const [Color(0xFF78716C), Color(0xFF57534E)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
            ),
          ),
          _buildActionTile(
            context,
            icon: Icons.notifications_none_outlined,
            title: 'Notification Hub',
            gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationHubScreen()),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'ACCOUNT & FIELD WORK'),
        SizedBox(height: 10.h),
        _buildActionTile(
          context,
          icon: Icons.person_outline_rounded,
          title: 'My Profile',
          gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyProfileDetailScreen()),
          ),
        ),
        _buildActionTile(
          context,
          icon: Icons.how_to_reg_rounded,
          title: 'Attendance & Geo Check-In',
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          onTap: () => context.push(RouteNames.attendance),
        ),

        SizedBox(height: 18.h),
        _buildSectionHeader(context, 'SALES TOOLS & COLLATERAL'),
        SizedBox(height: 10.h),
        _buildActionTile(
          context,
          icon: Icons.auto_awesome_rounded,
          title: 'AI Sales Pitch Copilot',
          badgeText: 'AI POWERED',
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
          ),
        ),
        _buildActionTile(
          context,
          icon: Icons.inventory_2_outlined,
          title: 'POS Catalog & Hardware Book',
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
          ),
        ),
        _buildActionTile(
          context,
          icon: Icons.emoji_events_outlined,
          title: 'Territory Leaderboard',
          gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          ),
        ),

        SizedBox(height: 18.h),
        _buildSectionHeader(context, 'PREFERENCES & SUPPORT'),
        SizedBox(height: 10.h),
        _buildActionTile(
          context,
          icon: Icons.notifications_none_outlined,
          title: 'Notifications Hub',
          gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationHubScreen()),
          ),
        ),
        _buildActionTile(
          context,
          icon: Icons.settings_outlined,
          title: 'Settings & Security',
          gradientColors: const [Color(0xFF78716C), Color(0xFF57534E)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
          ),
        ),
        _buildActionTile(
          context,
          icon: Icons.headset_mic_rounded,
          title: 'Help, Support & Manager SOS',
          gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 19.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: gradientColors.first.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.bold,
                              color: gradientColors.first,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
        label: Text(
          'Sign Out of Session',
          style: TextStyle(
            color: const Color(0xFFEF4444),
            fontSize: 13.5.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        onPressed: () => _confirmLogout(context, ref),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8.w),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to end your current session? Unsynced offline leads are safely saved in local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'LiveRestro Enterprise Sales CRM',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Version 2.5.0 (Build 2026.08.10) • Connected to LiveRestro Cloud',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
