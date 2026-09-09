import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../data/models/admin_models.dart';
import '../providers/role_providers.dart';

class SuperAdminHubScreen extends ConsumerStatefulWidget {
  const SuperAdminHubScreen({super.key});

  @override
  ConsumerState<SuperAdminHubScreen> createState() => _SuperAdminHubScreenState();
}

class _SuperAdminHubScreenState extends ConsumerState<SuperAdminHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamMembersProvider.notifier).fetchTeamFromBackend();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Executive Top Header
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          SizedBox(width: 12.w),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFDE047), size: 18),
                                SizedBox(width: 6.w),
                                Text(
                                  'Super Admin HQ',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Global Organization & RBAC Control',
                              style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7.w,
                            height: 7.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'LIVE HQ',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white),
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
                  indicatorColor: const Color(0xFFFDE047),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 11.5.sp),
                  tabs: const [
                    Tab(icon: Icon(Icons.public_rounded, size: 16), text: 'Global Pulse'),
                    Tab(icon: Icon(Icons.people_alt_rounded, size: 16), text: 'Users & RBAC'),
                    Tab(icon: Icon(Icons.price_change_rounded, size: 16), text: 'POS Pricing'),
                    Tab(icon: Icon(Icons.location_city_rounded, size: 16), text: 'Territories'),
                    Tab(icon: Icon(Icons.security_rounded, size: 16), text: 'Audit Logs'),
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
                _buildGlobalPulseTab(isDark),
                _buildUsersRbacTab(isDark),
                _buildPricingTab(isDark),
                _buildTerritoriesTab(isDark),
                _buildAuditLogsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: GLOBAL MULTI-CITY PULSE
  // ==========================================
  Widget _buildGlobalPulseTab(bool isDark) {
    final zones = ref.watch(territoryZonesProvider);
    final members = ref.watch(teamMembersProvider);

    final totalReps = members.where((m) => m.role == AppUserRole.salesExecutive).length;
    final totalClosedDeals = members.fold<int>(0, (sum, m) => sum + m.closedDealsCount);
    final totalRevenue = members.fold<double>(0.0, (sum, m) => sum + m.totalRevenueGenerated);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // National Revenue Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Revenue (ARR)',
                  value: '₹${(totalRevenue / 100000).toStringAsFixed(2)} Lakhs',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF10B981),
                  subtitle: '+28.4% vs last month',
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildMetricCard(
                  title: 'Deals Closed',
                  value: '$totalClosedDeals Outlets',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF6366F1),
                  subtitle: '78% Conversion',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'On-Ground Reps',
                  value: '$totalReps Reps Active',
                  icon: Icons.directions_walk_rounded,
                  color: const Color(0xFFF59E0B),
                  subtitle: '4 Territories Covered',
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildMetricCard(
                  title: 'Average Deal Size',
                  value: '₹18,500',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFEC4899),
                  subtitle: 'Annual Pro Dominance',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Territory Breakdown Section
          _buildSectionHeader('Multi-City Territory Performance', Icons.map_rounded),
          SizedBox(height: 10.h),
          ...zones.map((zone) {
            final progress = (zone.achievedRevenue / zone.targetRevenue).clamp(0.0, 1.0);
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
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
                          zone.zoneName,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${zone.city} City',
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        'Manager: ${zone.assignedManagerName}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        '${zone.activeRepsCount} Reps • ${zone.totalComplexesCount} Complexes',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.h,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 0.8 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Achieved: ₹${(zone.achievedRevenue / 1000).toStringAsFixed(0)}k / Target ₹${(zone.targetRevenue / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600]),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: USERS & RBAC MANAGEMENT
  // ==========================================
  Widget _buildUsersRbacTab(bool isDark) {
    final members = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeamMemberDialog(context),
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: members.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_off_rounded, size: 48.sp, color: Colors.grey[400]),
                    SizedBox(height: 12.h),
                    Text(
                      'No Organization Users Found',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Use the button below to register managers or field sales representatives.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              physics: const BouncingScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
          final member = members[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: member.isActive
                    ? (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomAvatar(
                      imageUrl: member.avatarUrl,
                      name: member.name,
                      size: 40.r,
                      userId: member.id,
                      backgroundColor: member.role.color.withValues(alpha: 0.15),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: member.role.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  member.role.displayName,
                                  style: TextStyle(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: member.role.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${member.email} • ${member.phone}',
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showUserRoleOptions(member),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📍 ${member.territory}',
                        style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${member.closedDealsCount} Deals • ₹${(member.totalRevenueGenerated / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 3: POS PRICING & RATE CARDS
  // ==========================================
  Widget _buildPricingTab(bool isDark) {
    final plans = ref.watch(pricingTiersProvider);

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: plan.isPopular ? const Color(0xFF7C3AED) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              width: plan.isPopular ? 1.8 : 1.0,
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
                      plan.planName,
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '🔥 TOP SELLER',
                        style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Text(
                    'Software: ₹${plan.softwarePrice.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    ' + Hardware: ₹${plan.hardwareBundlePrice.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: plan.includedFeatures.map((feat) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '✓ $feat',
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Max ASM Discount: ${plan.maxDiscountPercentAllowed}%',
                    style: TextStyle(fontSize: 11.sp, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditPricingDialog(plan),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Edit Rate'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      textStyle: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: TERRITORIES & MASTER DATA
  // ==========================================
  Widget _buildTerritoriesTab(bool isDark) {
    final complexes = [
      {'name': 'Godrej City Square & Garden City', 'area': 'Jagatpur', 'cafes': 14, 'city': 'Ahmedabad'},
      {'name': 'Vandematram Icon & Crosswind', 'area': 'Gota', 'cafes': 12, 'city': 'Ahmedabad'},
      {'name': 'Savvy Swaraj Plaza & High Street', 'area': 'Jagatpur Road', 'cafes': 8, 'city': 'Ahmedabad'},
      {'name': 'Gota Cross Road Commercial Hub', 'area': 'SG Highway', 'cafes': 10, 'city': 'Ahmedabad'},
      {'name': 'Shayona City Commercial Arc', 'area': 'Gota', 'cafes': 7, 'city': 'Ahmedabad'},
      {'name': 'VR Mall & Dumas Road Food Street', 'area': 'Vesu', 'cafes': 22, 'city': 'Surat'},
    ];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Mapped Commercial Complexes', Icons.domain_rounded),
        SizedBox(height: 10.h),
        ...complexes.map((c) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] as String, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold)),
                      Text('${c['area']} • ${c['city']}', style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${c['cafes']} Outlets',
                    style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 5: SYSTEM AUDIT LOGS
  // ==========================================
  Widget _buildAuditLogsTab(bool isDark) {
    final logs = ref.watch(auditLogsProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Security Audit Stream', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📥 Exported full audit log & lead database to CSV successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  textStyle: TextStyle(fontSize: 10.5.sp),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final timeStr = DateFormat('hh:mm a • dd MMM').format(log.timestamp);
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: log.actorRole.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            log.actionType,
                            style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: log.actorRole.color),
                          ),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      log.details,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Actor: ${log.actorName} (${log.actorRole.displayName}) • IP: ${log.ipAddress}',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helpers & Modals ---

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
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
              Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
              Icon(icon, size: 18.sp, color: color),
            ],
          ),
          SizedBox(height: 6.h),
          Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 3.h),
          Text(subtitle, style: TextStyle(fontSize: 9.5.sp, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF7C3AED)),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showUserRoleOptions(TeamMemberModel member) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: Color(0xFF10B981)),
              title: const Text('Set Role: Sales Executive (FSE)'),
              onTap: () {
                ref.read(teamMembersProvider.notifier).updateMemberRole(member.id, AppUserRole.salesExecutive);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF2563EB)),
              title: const Text('Set Role: Sales Manager (ASM)'),
              onTap: () {
                ref.read(teamMembersProvider.notifier).updateMemberRole(member.id, AppUserRole.salesManager);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C3AED)),
              title: const Text('Set Role: Super Admin'),
              onTap: () {
                ref.read(teamMembersProvider.notifier).updateMemberRole(member.id, AppUserRole.superAdmin);
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(member.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: member.isActive ? Colors.red : Colors.green),
              title: Text(member.isActive ? 'Deactivate Account' : 'Activate Account'),
              onTap: () {
                ref.read(teamMembersProvider.notifier).toggleMemberActive(member.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTeamMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final territoryCtrl = TextEditingController(text: 'Ahmedabad North (Gota & Jagatpur)');
    AppUserRole selectedRole = AppUserRole.salesExecutive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Invite New Team Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'e.g. Nirav Patel'),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'nirav.p@liverestro.com'),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number *', hintText: '+91 98250 99887'),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: territoryCtrl,
                  decoration: const InputDecoration(labelText: 'Assigned Territory *'),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<AppUserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Assigned Role'),
                  items: AppUserRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => selectedRole = val ?? AppUserRole.salesExecutive),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                final newMember = TeamMemberModel(
                  id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 98765 43210',
                  role: selectedRole,
                  territory: territoryCtrl.text.trim(),
                  city: 'Ahmedabad',
                );
                ref.read(teamMembersProvider.notifier).addMember(newMember);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎉 Invited ${newMember.name} as ${newMember.role.displayName}!')),
                );
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPricingDialog(PricingTierModel plan) {
    final swCtrl = TextEditingController(text: plan.softwarePrice.toStringAsFixed(0));
    final hwCtrl = TextEditingController(text: plan.hardwareBundlePrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${plan.planName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: swCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Software Subscription Price (₹)'),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: hwCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hardware Bundle Price (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sw = double.tryParse(swCtrl.text.trim()) ?? plan.softwarePrice;
              final hw = double.tryParse(hwCtrl.text.trim()) ?? plan.hardwareBundlePrice;
              ref.read(pricingTiersProvider.notifier).updatePlanPricing(plan.id, sw, hw);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Updated POS Rate Card successfully!')),
              );
            },
            child: const Text('Save Pricing'),
          ),
        ],
      ),
    );
  }
}
