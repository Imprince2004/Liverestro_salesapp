import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class MyProfileDetailScreen extends ConsumerStatefulWidget {
  const MyProfileDetailScreen({super.key});

  @override
  ConsumerState<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends ConsumerState<MyProfileDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hive = getIt<HiveStorageService>();
    final rawRole = user?.role ?? hive.get<String>('user_role') ?? 'SALES_EXECUTIVE';
    final userRoleStr = rawRole.replaceAll('_', ' ');

    final isAdmin = rawRole == 'SUPER_ADMIN' ||
        rawRole == 'COMPANY_ADMIN' ||
        rawRole.toUpperCase().contains('ADMIN') ||
        (user?.designation != null && user!.designation.toLowerCase().contains('admin'));

    final isManager = rawRole == 'SALES_MANAGER';
    final isExecutive = !isAdmin && !isManager;

    final dynamicName = user?.name ?? hive.get<String>('user_name') ?? (isAdmin ? 'LiveRestro Admin' : 'User');
    final dynamicPhone = user?.phone ?? hive.get<String>('user_phone') ?? '';
    final dynamicEmail = user?.email ?? hive.get<String>('user_email') ?? '';
    final dynamicEmployeeId = user?.employeeId ?? hive.get<String>('user_employee_id') ?? (isAdmin ? '' : '');
    final dynamicDoj = user?.dateOfJoining ?? hive.get<String>('user_date_of_joining') ?? '';
    final dynamicDob = user?.dateOfBirth ?? hive.get<String>('user_date_of_birth');
    final dynamicDesignation = user?.designation ??
        hive.get<String>('user_designation') ??
        (isAdmin ? 'Company Administrator' : (isManager ? 'Sales Manager' : 'Sales Executive'));
    final dynamicTerritory = user?.territory ??
        hive.get<String>('user_territory') ??
        (isAdmin ? 'Gujarat Headquarters' : 'Ahmedabad North (Gota & Jagatpur)');
    final dynamicAddedBy = user?.addedBy ?? hive.get<String>('user_added_by') ?? 'Not Available';

    final effectiveUser = user ??
        UserEntity(
          id: hive.get<String>('user_id') ?? (isAdmin ? 'usr_companyadmin_002' : 'usr_sales_manager_001'),
          name: dynamicName,
          email: dynamicEmail,
          phone: dynamicPhone,
          role: userRoleStr,
          employeeId: dynamicEmployeeId,
          dateOfJoining: dynamicDoj,
          dateOfBirth: dynamicDob,
          designation: dynamicDesignation,
          territory: dynamicTerritory,
          addedBy: dynamicAddedBy,
          isPinSet: true,
          status: 'ACTIVE',
        );

    final manager = user?.assignedManager;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // 1. Top Profile Header Card
            _buildProfileCard(
              context,
              effectiveUser,
              dynamicName,
              dynamicEmployeeId,
              dynamicDesignation,
              isAdmin: isAdmin,
              isDark: isDark,
            ),
            SizedBox(height: 18.h),

            // 2. Account Information (for Admin) OR Professional Information (for Manager/Executive)
            if (isAdmin)
              _buildAdminAccountInfoSection(
                context,
                effectiveUser,
                dynamicDesignation,
                dynamicTerritory,
                isDark,
              )
            else
              _buildProfessionalSection(
                context,
                effectiveUser,
                dynamicEmployeeId,
                dynamicDoj,
                dynamicDesignation,
                dynamicTerritory,
                isDark,
              ),
            SizedBox(height: 18.h),

            // 3. Personal Details (Full Name, Mobile Number, Email Address)
            _buildPersonalDetailsSection(context, dynamicName, dynamicPhone, dynamicEmail, isDark),
            SizedBox(height: 18.h),

            // 4. Assigned Sales Manager (ONLY for Sales Executive when manager is assigned)
            if (isExecutive && manager != null) ...[
              _buildAssignedManagerSection(context, manager, isDark),
              SizedBox(height: 18.h),
            ],

            SizedBox(height: 6.h),

            // 5. Edit Profile Details CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.push(RouteNames.editProfile, extra: effectiveUser);
                  if (mounted) {
                    await ref.read(authNotifierProvider.notifier).refreshProfile();
                    if (mounted) setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                child: Text(
                  'Edit Profile Details',
                  style: TextStyle(fontSize: 15.sp, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // --- 1. Top Profile Card ---
  Widget _buildProfileCard(
    BuildContext context,
    UserEntity user,
    String displayName,
    String employeeId,
    String designation, {
    required bool isAdmin,
    required bool isDark,
  }) {
    final hive = getIt<HiveStorageService>();
    final userId = user.id.isNotEmpty ? user.id : (hive.get<String>('user_id') ?? '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF714B67), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomAvatar(
                  imageUrl: user.profilePhoto,
                  name: displayName,
                  size: 72.r,
                  userId: userId,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.check, size: 10.sp, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),

          // Role Badge: For Admin show designation badge, for employees show EMP ID
          if (isAdmin)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF714B67).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                  SizedBox(width: 5.w),
                  Text(
                    designation.isNotEmpty ? designation : 'Company Administrator',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF714B67),
                    ),
                  ),
                ],
              ),
            )
          else if (employeeId.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF714B67).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF714B67).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Employee ID: $employeeId',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF714B67),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2A. Admin Account Information Card ---
  Widget _buildAdminAccountInfoSection(
    BuildContext context,
    UserEntity user,
    String designation,
    String territory,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 18.sp, color: const Color(0xFF714B67)),
              SizedBox(width: 8.w),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildInfoRow('Designation', designation.isNotEmpty ? designation : 'Company Administrator', isDark, isHighlight: true),
          _buildDivider(isDark),
          _buildInfoRow('Assigned Area', territory.isNotEmpty ? territory : 'Gujarat Headquarters', isDark),
          _buildDivider(isDark),
          _buildInfoRow('Account Status', user.status.isNotEmpty ? user.status : 'ACTIVE', isDark, statusColor: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  // --- 2B. Professional Information Card (For Managers / Executives) ---
  Widget _buildProfessionalSection(
    BuildContext context,
    UserEntity user,
    String employeeId,
    String doj,
    String designation,
    String territory,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 18.sp, color: const Color(0xFF714B67)),
              SizedBox(width: 8.w),
              Text(
                'Professional Information',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (employeeId.isNotEmpty) ...[
            _buildInfoRow('Employee ID', employeeId, isDark, isHighlight: true),
            _buildDivider(isDark),
          ],
          _buildInfoRow('Date of Joining', doj, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Designation', designation, isDark),
          _buildDivider(isDark),
          _buildInfoRow(
            'Added By',
            user.addedBy.isNotEmpty ? user.addedBy : 'Not Available',
            isDark,
            isHighlight: user.addedBy.isNotEmpty && user.addedBy != 'Not Available',
          ),
          _buildDivider(isDark),
          _buildInfoRow('Assigned Territory', territory, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Account Status', user.status.isNotEmpty ? user.status : 'ACTIVE', isDark, statusColor: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  // --- 3. Personal Details Card ---
  Widget _buildPersonalDetailsSection(
    BuildContext context,
    String name,
    String phone,
    String email,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18.sp, color: const Color(0xFF714B67)),
              SizedBox(width: 8.w),
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildInfoRow('Full Name', name, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Mobile Number', phone, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Email Address', email, isDark),
        ],
      ),
    );
  }

  // --- 4. Assigned Sales Manager Card (Only for Executives) ---
  Widget _buildAssignedManagerSection(BuildContext context, ManagerSummaryEntity manager, bool isDark) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.supervisor_account_rounded, size: 18.sp, color: const Color(0xFF714B67)),
              SizedBox(width: 8.w),
              Text(
                'Assigned Sales Manager',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildInfoRow('Manager Name', manager.name, isDark, isHighlight: true),
          _buildDivider(isDark),
          _buildInfoRow('Designation', manager.designation, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Region / Area', manager.territory, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Email Address', manager.email, isDark),
          _buildDivider(isDark),
          _buildInfoRow('Contact Number', manager.phone, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isHighlight = false, Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
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
    return Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9));
  }
}
