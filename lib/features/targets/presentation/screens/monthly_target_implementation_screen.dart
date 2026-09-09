import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../manager/presentation/providers/role_providers.dart';
import '../../../manager/data/models/admin_models.dart';
import '../../data/models/monthly_target_model.dart';
import '../../data/models/implementation_model.dart';
import '../providers/target_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/data/models/assignable_user_model.dart';

class MonthlyTargetImplementationScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const MonthlyTargetImplementationScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<MonthlyTargetImplementationScreen> createState() => _MonthlyTargetImplementationScreenState();
}

class _MonthlyTargetImplementationScreenState extends ConsumerState<MonthlyTargetImplementationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final activeRole = ref.watch(activeRoleProvider);

    final isManagerOrAdmin = user?.role == 'SUPER_ADMIN' ||
        user?.role == 'COMPANY_ADMIN' ||
        user?.role == 'SALES_MANAGER' ||
        activeRole == AppUserRole.superAdmin ||
        activeRole == AppUserRole.companyAdmin ||
        activeRole == AppUserRole.salesManager;

    final myTargetAsync = ref.watch(myMonthlyTargetProvider);
    final teamTargetsAsync = ref.watch(teamMonthlyTargetsProvider);
    final myTasksAsync = ref.watch(myImplementationTasksProvider);
    final allImplementationsAsync = ref.watch(allImplementationsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0D1B) : const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Target & Implementation',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF281F33) : const Color(0xFF714B67),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(targetActionProvider.notifier).refreshAll();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.track_changes_rounded, size: 18), text: 'Monthly Target'),
            Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: 'Implementation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Monthly Target
          _buildTargetTab(context, isDark, isManagerOrAdmin, myTargetAsync, teamTargetsAsync),
          // Tab 2: Implementation Process
          _buildImplementationTab(context, isDark, isManagerOrAdmin, myTasksAsync, allImplementationsAsync),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MONTHLY TARGET
  // ==========================================

  Widget _buildTargetTab(
    BuildContext context,
    bool isDark,
    bool isManagerOrAdmin,
    AsyncValue<MonthlyTargetModel> myTargetAsync,
    AsyncValue<List<MonthlyTargetModel>> teamTargetsAsync,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. My Monthly Target Hero Card
          myTargetAsync.when(
            data: (target) => _buildMyTargetCard(context, target, isDark),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text('Error loading target: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),

          // 2. Admin & Sales Manager Team Target Roster
          if (isManagerOrAdmin) ...[
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      'Team Target Assignments',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Management View',
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            teamTargetsAsync.when(
              data: (team) {
                if (team.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, color: Colors.grey[400], size: 40.sp),
                        SizedBox(height: 12.h),
                        Text(
                          'No Sales Executives Assigned',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Sales Executives assigned to you will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: team.map((t) => _buildTeamMemberTargetCard(context, t, isDark)).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Text('Error loading team targets: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyTargetCard(BuildContext context, MonthlyTargetModel target, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3B2D4A), const Color(0xFF201828)]
              : [const Color(0xFF714B67), const Color(0xFF56354E)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header & Status Badge (Defensive Layout - Zero Overflow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
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
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Assigned by: ${target.assignedByName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                  ),
                  child: Text(
                    '${target.progressPercent}% Achieved',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.h),

            // Animated Progress Bar
            Stack(
              children: [
                Container(
                  height: 10.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (target.progressPercent / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 10.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(5.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.h),

            // 3-Pill Target Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Target',
                    '${target.targetLeads}',
                    'Leads Assigned',
                    Colors.white,
                    Colors.white70,
                  ),
                ),
                Container(width: 1, height: 36.h, color: Colors.white24),
                Expanded(
                  child: _buildMetricTile(
                    'Completed',
                    '${target.completedLeads}',
                    'Leads Closed',
                    const Color(0xFF34D399),
                    Colors.white70,
                  ),
                ),
                Container(width: 1, height: 36.h, color: Colors.white24),
                Expanded(
                  child: _buildMetricTile(
                    'Remaining',
                    '${target.remainingLeads}',
                    'To Reach 100%',
                    const Color(0xFFFBBF24),
                    Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String sub, Color valColor, Color labelColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: labelColor),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: valColor),
        ),
        SizedBox(height: 1.h),
        Text(
          sub,
          style: TextStyle(fontSize: 9.sp, color: labelColor.withValues(alpha: 0.8)),
        ),
      ],
    );
  }



  Widget _buildTeamMemberTargetCard(BuildContext context, MonthlyTargetModel t, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  t.userName.isNotEmpty ? t.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.userName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${t.userDesignation ?? 'Sales Executive'} • ${t.userTerritory ?? 'Ahmedabad'}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                tooltip: 'Edit Assigned Target',
                onPressed: () => _showAssignTargetModal(context, t),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${t.targetLeads} Leads',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
              ),
              Text(
                'Completed: ${t.completedLeads} / ${t.targetLeads} (${t.progressPercent}%)',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: t.progressPercent >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LinearProgressIndicator(
            value: (t.progressPercent / 100).clamp(0.0, 1.0),
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            color: t.progressPercent >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            minHeight: 6.h,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ],
      ),
    );
  }

  void _showAssignTargetModal(BuildContext context, MonthlyTargetModel t) {
    HapticFeedback.lightImpact();
    final targetCtrl = TextEditingController(text: '${t.targetLeads}');
    final notesCtrl = TextEditingController(text: t.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1A29) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Assign Target for ${t.userName}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              '${t.monthName} ${t.year} Sales Quota',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Leads (Monthly)',
                prefixIcon: const Icon(Icons.flag_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Manager Remarks / Instructions',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                onPressed: () async {
                  final newTarget = int.tryParse(targetCtrl.text.trim()) ?? 20;
                  Navigator.pop(ctx);
                  final success = await ref.read(targetActionProvider.notifier).assignTarget(
                        userId: t.userId,
                        targetLeads: newTarget,
                        month: t.month,
                        year: t.year,
                        notes: notesCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '✅ Target assigned successfully' : 'Failed to assign target'),
                        backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save & Update Target', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: IMPLEMENTATION PROCESS PIPELINE
  // ==========================================

  Widget _buildImplementationTab(
    BuildContext context,
    bool isDark,
    bool isManagerOrAdmin,
    AsyncValue<List<ImplementationModel>> myTasksAsync,
    AsyncValue<List<ImplementationModel>> allImplementationsAsync,
  ) {
    final listAsync = isManagerOrAdmin ? allImplementationsAsync : myTasksAsync;

    return Column(
      children: [
        // 3-Stage Explanation Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: isDark ? const Color(0xFF1E1A29) : const Color(0xFFF1F5F9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStageStepIndicator('1', 'Demo', isDark),
              Icon(Icons.arrow_forward_rounded, size: 14.sp, color: Colors.grey[400]),
              _buildStageStepIndicator('2', 'Software Setup', isDark),
              Icon(Icons.arrow_forward_rounded, size: 14.sp, color: Colors.grey[400]),
              _buildStageStepIndicator('3', 'Training', isDark),
            ],
          ),
        ),

        // Search and Filters
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => ref.read(implementationSearchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Search restaurant or lead owner...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Stage Filter Chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStageFilterChip('ALL', 'All Stages'),
                _buildStageFilterChip('DEMO', '1️⃣ Demo'),
                _buildStageFilterChip('SOFTWARE_SETUP', '2️⃣ Software Setup'),
                _buildStageFilterChip('TRAINING', '3️⃣ Training'),
                _buildStageFilterChip('COMPLETED', '✅ Live & Done'),
              ],
            ),
          ),
        ),

        // Implementation Cards List
        Expanded(
          child: listAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_remove_rounded, size: 48.sp, color: Colors.grey[400]),
                      SizedBox(height: 12.h),
                      Text('No implementation pipelines found', style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: items.length,
                itemBuilder: (ctx, idx) => _buildImplementationCard(context, items[idx], isDark, isManagerOrAdmin),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildStageStepIndicator(String step, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStageFilterChip(String stageKey, String label) {
    final current = ref.watch(implementationStageFilterProvider);
    final isSelected = current == stageKey;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        onSelected: (val) {
          if (val) ref.read(implementationStageFilterProvider.notifier).state = stageKey;
        },
      ),
    );
  }

  Widget _buildImplementationCard(
    BuildContext context,
    ImplementationModel item,
    bool isDark,
    bool isManagerOrAdmin,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Name & Overall Progress
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.restaurantName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Lead Owner: ${item.leadOwnerName}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: item.overallStatus == 'COMPLETED'
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${item.progressPercent}% Complete',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: item.overallStatus == 'COMPLETED' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // 3-Stage Progress Tiles Matrix
            _buildStageRow('1. Demo', item.demoStatus, item.demoAssignedToName, item.demoCompletedDate, isDark, () {
              _showStageActionModal(context, item, 'Demo', item.demoStatus, item.demoAssignedToName);
            }),
            SizedBox(height: 8.h),
            _buildStageRow('2. Software Setup', item.setupStatus, item.setupAssignedToName, item.setupCompletedDate, isDark, () {
              _showStageActionModal(context, item, 'Software Setup', item.setupStatus, item.setupAssignedToName);
            }),
            SizedBox(height: 8.h),
            _buildStageRow('3. Training', item.trainingStatus, item.trainingAssignedToName, item.trainingCompletedDate, isDark, () {
              _showStageActionModal(context, item, 'Training', item.trainingStatus, item.trainingAssignedToName);
            }),

            SizedBox(height: 12.h),

            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showStageActionModal(
                    context,
                    item,
                    item.overallStage == 'SOFTWARE_SETUP'
                        ? 'Software Setup'
                        : (item.overallStage == 'TRAINING' ? 'Training' : 'Demo'),
                    item.demoStatus,
                    item.demoAssignedToName,
                  ),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                  label: Text(isManagerOrAdmin ? 'Manage & Assign Stages' : 'Update My Stage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageRow(
    String stageTitle,
    String status,
    String assignedTo,
    String completedDate,
    bool isDark,
    VoidCallback onTap,
  ) {
    Color statusColor = Colors.grey;
    String statusText = 'Not Started';

    if (status.toUpperCase() == 'COMPLETED') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Completed';
    } else if (status.toUpperCase() == 'IN_PROGRESS') {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'In Progress';
    } else if (status.toUpperCase() == 'ASSIGNED') {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Assigned';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              status.toUpperCase() == 'COMPLETED' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: statusColor,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stageTitle,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  if (assignedTo.isNotEmpty)
                    Text(
                      '👤 $assignedTo ${completedDate.isNotEmpty ? "• $completedDate" : ""}',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                    )
                  else
                    Text('Unassigned', style: TextStyle(fontSize: 10.sp, color: Colors.grey[400])),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStageActionModal(
    BuildContext context,
    ImplementationModel item,
    String defaultStage,
    String currentStatus,
    String currentAssignee,
  ) {
    HapticFeedback.lightImpact();
    String selectedStage = defaultStage;
    String selectedStatus = currentStatus.isNotEmpty && currentStatus != 'NOT_STARTED' ? currentStatus : 'IN_PROGRESS';
    String? selectedExecutiveId;
    final remarksCtrl = TextEditingController();
    final assignableState = ref.read(assignableUsersProvider);
    final executives = assignableState.salesExecutives;

    // Helper to get assignee for stage from item
    String getStageAssigneeName(String stage) {
      if (stage == 'Demo') return item.demoAssignedToName;
      if (stage == 'Software Setup') return item.setupAssignedToName;
      if (stage == 'Training') return item.trainingAssignedToName;
      return '';
    }

    String getStageAssigneeId(String stage) {
      if (stage == 'Demo') return item.demoAssignedToId;
      if (stage == 'Software Setup') return item.setupAssignedToId;
      if (stage == 'Training') return item.trainingAssignedToId;
      return '';
    }

    String getStageStatus(String stage) {
      if (stage == 'Demo') return item.demoStatus;
      if (stage == 'Software Setup') return item.setupStatus;
      if (stage == 'Training') return item.trainingStatus;
      return 'IN_PROGRESS';
    }

    // Initial resolution for defaultStage
    final initialId = getStageAssigneeId(defaultStage);
    final initialName = getStageAssigneeName(defaultStage);

    if (initialId.isNotEmpty) {
      selectedExecutiveId = initialId;
    } else if (initialName.isNotEmpty) {
      final clean = initialName.split(' — ').first.trim().toLowerCase();
      final match = executives.where((e) => e.name.toLowerCase() == clean || e.name.toLowerCase().contains(clean)).firstOrNull;
      selectedExecutiveId = match?.id;
    } else if (currentAssignee.isNotEmpty) {
      final clean = currentAssignee.split(' — ').first.trim().toLowerCase();
      final match = executives.where((e) => e.name.toLowerCase() == clean || e.name.toLowerCase().contains(clean)).firstOrNull;
      selectedExecutiveId = match?.id;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Resolve current selected executive object
          final selectedExec = executives.where((e) => e.id == selectedExecutiveId).firstOrNull;
          final currentStageAssigneeName = getStageAssigneeName(selectedStage);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A29) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF714B67).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: const Icon(Icons.engineering_rounded, color: Color(0xFF714B67), size: 20),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Implementation Stage',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              item.restaurantName,
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Stage Selection Dropdown
                  Text(
                    'Select Stage',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStage,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Demo', child: Text('1️⃣ Demo Stage')),
                      DropdownMenuItem(value: 'Software Setup', child: Text('2️⃣ Software Setup Stage')),
                      DropdownMenuItem(value: 'Training', child: Text('3️⃣ Staff Training Stage')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedStage = v;
                          final stageId = getStageAssigneeId(v);
                          final stageName = getStageAssigneeName(v);
                          final st = getStageStatus(v);

                          if (stageId.isNotEmpty) {
                            selectedExecutiveId = stageId;
                          } else if (stageName.isNotEmpty) {
                            final clean = stageName.split(' — ').first.trim().toLowerCase();
                            final match = executives.where((e) => e.name.toLowerCase() == clean || e.name.toLowerCase().contains(clean)).firstOrNull;
                            selectedExecutiveId = match?.id;
                          } else {
                            selectedExecutiveId = null;
                          }

                          if (st.isNotEmpty && st != 'NOT_STARTED') {
                            selectedStatus = st;
                          }
                        });
                      }
                    },
                  ),
                  SizedBox(height: 14.h),

                  // 1. Responsible Sales Executive Section (Compact, Horizontal, Non-wrapping Card)
                  Text(
                    'Responsible Sales Executive',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    onTap: () {
                      _openExecutiveSelectionSheet(ctx, executives, selectedExecutiveId, isDark, (chosen) {
                        setModalState(() {
                          selectedExecutiveId = chosen.id;
                        });
                      });
                    },
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF281F33) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selectedExec != null
                              ? const Color(0xFFF97316).withValues(alpha: 0.6)
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with initial letter
                          CircleAvatar(
                            radius: 18.r,
                            backgroundColor: selectedExec != null ? const Color(0xFFF97316) : Colors.grey[400],
                            child: Text(
                              selectedExec != null && selectedExec.name.trim().isNotEmpty
                                  ? selectedExec.name.trim()[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Executive Name & Designation • EMP ID (Guaranteed single-line, no wrapping)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedExec != null
                                      ? selectedExec.name
                                      : (currentStageAssigneeName.isNotEmpty
                                          ? currentStageAssigneeName.split(' — ').first
                                          : 'No Sales Executive Assigned'),
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  selectedExec != null
                                      ? '${selectedExec.designation} • ${selectedExec.employeeId}'
                                      : (currentStageAssigneeName.isNotEmpty
                                          ? 'Sales Executive'
                                          : 'Tap to assign a Sales Executive'),
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // Dropdown indicator
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            size: 24.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Status Selection Dropdown
                  Text(
                    'Stage Status',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ASSIGNED', child: Text('👤 Assigned & Dispatched')),
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('⚙️ In Progress (Active)')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('✅ Completed Successfully')),
                      DropdownMenuItem(value: 'NOT_STARTED', child: Text('⏳ Not Started')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedStatus = v);
                    },
                  ),
                  SizedBox(height: 12.h),

                  Text(
                    'Remarks & Progress Notes',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Menu configuration done, staff training scheduled for tomorrow...',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        final chosenExec = executives.where((e) => e.id == selectedExecutiveId).firstOrNull;

                        // Check for conflict
                        if (chosenExec != null && chosenExec.isAvailable == false) {
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 8),
                                  Text('Conflict Warning'),
                                ],
                              ),
                              content: Text(
                                '${chosenExec.name} (${chosenExec.designation}) is currently marked as "${chosenExec.badgeText}". Do you want to proceed with assigning this stage?',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (proceed != true) return;
                        }

                        if (chosenExec != null) {
                          await ref.read(targetActionProvider.notifier).assignStage(
                                id: item.id,
                                stage: selectedStage,
                                assignedToId: chosenExec.id,
                                assignedToName: '${chosenExec.name} — ${chosenExec.designation}',
                                notes: remarksCtrl.text.trim(),
                              );
                        }

                        final success = await ref.read(targetActionProvider.notifier).updateStageStatus(
                              id: item.id,
                              stage: selectedStage,
                              status: selectedStatus,
                              notes: remarksCtrl.text.trim(),
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? '✅ Stage & Assignee updated successfully' : 'Failed to update stage'),
                              backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Save & Dispatch Stage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openExecutiveSelectionSheet(
    BuildContext context,
    List<AssignableUserModel> executives,
    String? currentSelectedId,
    bool isDark,
    ValueChanged<AssignableUserModel> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExecutivePickerSheet(
        executives: executives,
        selectedId: currentSelectedId,
        isDark: isDark,
        onSelected: (exec) {
          onSelected(exec);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Searchable Database Sales Executive Picker Bottom Sheet
class _ExecutivePickerSheet extends StatefulWidget {
  final List<AssignableUserModel> executives;
  final String? selectedId;
  final bool isDark;
  final ValueChanged<AssignableUserModel> onSelected;

  const _ExecutivePickerSheet({
    required this.executives,
    required this.selectedId,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<_ExecutivePickerSheet> createState() => _ExecutivePickerSheetState();
}

class _ExecutivePickerSheetState extends State<_ExecutivePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = widget.executives.where((e) {
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
          e.designation.toLowerCase().contains(query) ||
          e.employeeId.toLowerCase().contains(query) ||
          e.territory.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1A29) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Responsible Sales Executive',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '🔍 Search by name, designation, or ID...',
              hintStyle: TextStyle(fontSize: 12.5.sp, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF97316)),
              filled: true,
              fillColor: widget.isDark ? const Color(0xFF281F33) : const Color(0xFFF1F5F9),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching sales executives found in database.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: widget.isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (ctx, index) {
                      final exec = filtered[index];
                      final isSelected = widget.selectedId == exec.id;

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                        leading: CircleAvatar(
                          radius: 18.r,
                          backgroundColor: const Color(0xFFF97316),
                          child: Text(
                            exec.name.trim().isNotEmpty ? exec.name.trim()[0].toUpperCase() : 'E',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                          ),
                        ),
                        title: Text(
                          exec.name,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${exec.designation} • ${exec.employeeId}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: widget.isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: exec.isAvailable
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                exec.isAvailable ? 'Available' : 'Assigned',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: exec.isAvailable ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? const Color(0xFFF97316) : Colors.grey.withValues(alpha: 0.5),
                              size: 20.sp,
                            ),
                          ],
                        ),
                        onTap: () => widget.onSelected(exec),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
