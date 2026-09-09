import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../../manager/presentation/providers/role_providers.dart';
import '../../../visits/presentation/providers/visit_providers.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/environment.dart';
import 'package:dio/dio.dart';

final leaderboardTimeframeProvider = StateProvider<String>((ref) => 'month');

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardUser>>((ref) async {
  final timeframe = ref.watch(leaderboardTimeframeProvider);
  final token = await getIt<SecureStorageService>().getAuthToken();
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 5),
    headers: {'Content-Type': 'application/json'},
  ));

  for (final base in Environment.resolvedApiCandidates) {
    try {
      final res = await dio.get(
        '$base/api/users/leaderboard',
        queryParameters: {'timeframe': timeframe},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200 && res.data != null && res.data['data'] is List) {
        Environment.activeWorkingBaseUrl = base;
        final List<dynamic> list = res.data['data'];
        
        return list.map((e) {
          final rawRevenue = (e['rawRevenue'] ?? e['revenue'] ?? 0.0).toDouble();
          return LeaderboardUser(
            rank: 0,
            id: e['id'] ?? '',
            name: e['name'] ?? '',
            city: e['city'] ?? '',
            leads: e['leads'] ?? 0,
            rawRevenue: rawRevenue,
            revenue: '₹ ${rawRevenue.toStringAsFixed(0)}',
            visits: e['visits'] ?? 0,
            conversionRate: '100%',
            avatarColor: const Color(0xFF6366F1),
            badges: const [],
          );
        }).toList();
      }
    } catch (_) {}
  }
  return const [];
});

class LeaderboardUser {
  final int rank;
  final String id;
  final String name;
  final String city;
  final int leads;
  final double rawRevenue;
  final String revenue;
  final int visits;
  final String conversionRate;
  final Color avatarColor;
  final bool isCurrentUser;
  final List<String> badges;

  const LeaderboardUser({
    required this.rank,
    required this.id,
    required this.name,
    required this.city,
    required this.leads,
    required this.rawRevenue,
    required this.revenue,
    required this.visits,
    required this.conversionRate,
    required this.avatarColor,
    this.isCurrentUser = false,
    required this.badges,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  LeaderboardUser copyWith({
    int? rank,
    bool? isCurrentUser,
  }) {
    return LeaderboardUser(
      rank: rank ?? this.rank,
      id: id,
      name: name,
      city: city,
      leads: leads,
      rawRevenue: rawRevenue,
      revenue: revenue,
      visits: visits,
      conversionRate: conversionRate,
      avatarColor: avatarColor,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      badges: badges,
    );
  }
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  int _timeframeIndex = 0; // 0: This Month, 1: Quarter, 2: All Time
  int _metricIndex = 0; // 0: Leads, 1: Revenue, 2: Visits
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(leaderboardProvider);
      await Future.wait([
        ref.read(teamMembersProvider.notifier).fetchTeamFromBackend(),
        ref.read(leadListProvider.notifier).loadLeads(),
        ref.refresh(visitListProvider.future),
        ref.read(leaderboardProvider.future),
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatRevenue(double amount) {
    if (amount >= 10000000) {
      return '₹ ${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹ ${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹ ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₹ ${amount.toStringAsFixed(0)}';
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFFF59E0B), // Gold / Amber
      Color(0xFF6366F1), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFFEC4899), // Pink
      AppColors.primary, // Brand Primary
      Color(0xFF06B6D4), // Cyan
      Color(0xFF8B5CF6), // Purple
      Color(0xFF14B8A6), // Teal
      Color(0xFFF97316), // Orange
      Color(0xFF64748B), // Slate
    ];
    return colors[index % colors.length];
  }

  List<String> _generateBadges(int rank, int closedLeads, double revenue) {
    final List<String> badges = [];
    if (rank == 1) badges.add('🏆 Gold Legend');
    if (rank == 2) badges.add('🥈 Silver Elite');
    if (rank == 3) badges.add('🥉 Bronze Star');
    if (revenue >= 1000000) badges.add('💎 Million Club');
    if (closedLeads >= 20) badges.add('⚡ Lightning Closer');
    if (closedLeads >= 10) badges.add('🎯 Top Converter');
    if (badges.isEmpty) badges.add('🌟 Rising Performer');
    return badges;
  }

  List<LeaderboardUser> _buildCalculatedLeaderboard(List<LeaderboardUser> apiUsers) {
    final authState = ref.watch(authNotifierProvider);
    final hive = getIt<HiveStorageService>();
    final currentUserId = authState.user?.id ?? hive.get<String>('user_id') ?? '';

    final List<LeaderboardUser> rawUsers = List.from(apiUsers);

    // Sort users dynamically according to selected metric
    if (_metricIndex == 0) {
      // Closed Leads
      rawUsers.sort((a, b) => b.leads.compareTo(a.leads));
    } else if (_metricIndex == 1) {
      // Revenue (₹)
      rawUsers.sort((a, b) => b.rawRevenue.compareTo(a.rawRevenue));
    } else {
      // Visits
      rawUsers.sort((a, b) => b.visits.compareTo(a.visits));
    }

    // Assign dynamic ranks & finalized badges
    final List<LeaderboardUser> rankedUsers = [];
    for (int i = 0; i < rawUsers.length; i++) {
      final rank = i + 1;
      final u = rawUsers[i];
      final isMe = u.id == currentUserId;

      rankedUsers.add(
        LeaderboardUser(
          rank: rank,
          id: u.id,
          name: u.name,
          city: u.city,
          leads: u.leads,
          rawRevenue: u.rawRevenue,
          revenue: _formatRevenue(u.rawRevenue),
          visits: u.visits,
          conversionRate: u.leads > 0 ? '${((u.leads / (u.leads + 5)) * 100).round()}%' : '78%',
          avatarColor: _getAvatarColor(i),
          isCurrentUser: isMe,
          badges: _generateBadges(rank, u.leads, u.rawRevenue),
        ),
      );
    }

    return rankedUsers;
  }

  List<LeaderboardUser> _getFilteredUsers(List<LeaderboardUser> users) {
    if (_searchQuery.trim().isEmpty) return users;
    final q = _searchQuery.toLowerCase().trim();
    return users.where((u) => u.name.toLowerCase().contains(q) || u.city.toLowerCase().contains(q)).toList();
  }

  void _showExecutiveProfile(LeaderboardUser user) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Profile Header
              Row(
                children: [
                  Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [user.avatarColor, user.avatarColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: user.avatarColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            if (user.isCurrentUser) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 13.sp, color: Colors.grey),
                            SizedBox(width: 3.w),
                            Text(
                              '${user.city} Region • Rank #${user.rank}',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // KPI Stats Grid
              Row(
                children: [
                  _buildProfileMetric('Leads Closed', '${user.leads}', isDark),
                  SizedBox(width: 10.w),
                  _buildProfileMetric('Revenue', user.revenue, isDark, highlight: true),
                  SizedBox(width: 10.w),
                  _buildProfileMetric('Win Rate', user.conversionRate, isDark),
                ],
              ),
              SizedBox(height: 18.h),

              // Badges Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Achievements & Badges',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: user.badges.map((b) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 22.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Sent Kudos to ${user.name}! 🚀'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.celebration_rounded, size: 18),
                      label: Text('Cheer Rep 👏', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileMetric(String label, String value, bool isDark, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
 
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final rankedUsers = leaderboardAsync.maybeWhen(
      data: (users) => _buildCalculatedLeaderboard(users),
      orElse: () => <LeaderboardUser>[],
    );
    final filteredUsers = _getFilteredUsers(rankedUsers);
    final top3 = filteredUsers.take(3).toList();
    final remainingUsers = filteredUsers.length > 3 ? filteredUsers.sublist(3) : <LeaderboardUser>[];
 
    final currentUser = rankedUsers.firstWhere(
      (u) => u.isCurrentUser,
      orElse: () => rankedUsers.isNotEmpty ? rankedUsers.first : const LeaderboardUser(
        rank: 1,
        id: '',
        name: 'You',
        city: 'Ahmedabad',
        leads: 0,
        rawRevenue: 0,
        revenue: '₹ 0',
        visits: 0,
        conversionRate: '0%',
        avatarColor: AppColors.primary,
        badges: [],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Sales Leaderboard',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Top 3 rankers this month qualify for the ₹25,000 President\'s Club reward!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: Column(
          children: [
            // Timeframe Tabs
            _buildTimeframeTabs(isDark),

            // Metric Filter Selector
            _buildMetricSelector(isDark),

            Expanded(
              child: (leaderboardAsync.isLoading || _isRefreshing) && rankedUsers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        children: [
                          // Podium Section (Top 3)
                          if (top3.isNotEmpty && _searchQuery.isEmpty)
                            _buildPodium(top3, isDark),

                          // Logged-in User Milestone Card
                          _buildMyRankBanner(currentUser, rankedUsers, isDark),

                          // Search Bar
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13.5.sp),
                              decoration: InputDecoration(
                                hintText: 'Search sales reps or cities...',
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20.sp),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),

                          // Remaining Rankings List
                          _buildRankingList(remainingUsers, isDark),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeTabs(bool isDark) {
    final tabs = ['This Month', 'Quarter (Q3)', 'All Time'];
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _timeframeIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _timeframeIndex = index);
                final timeframeStr = index == 0 ? 'month' : (index == 1 ? 'quarter' : 'all');
                ref.read(leaderboardTimeframeProvider.notifier).state = timeframeStr;
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      height: 2.5.h,
                      width: isSelected ? 36.w : 0,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMetricSelector(bool isDark) {
    final metrics = [
      {'label': 'Closed Leads', 'icon': Icons.group_add_rounded},
      {'label': 'Revenue (₹)', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'Visits', 'icon': Icons.location_on_rounded},
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
      child: Row(
        children: List.generate(metrics.length, (index) {
          final isSelected = _metricIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _metricIndex = index);
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      metrics[index]['icon'] as IconData,
                      size: 13.sp,
                      color: isSelected ? Colors.white : Colors.grey[500],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      metrics[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardUser> top3, bool isDark) {
    if (top3.length < 3) {
      if (top3.isEmpty) return const SizedBox.shrink();
      // Render single or dual podium items gracefully
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(top3.length, (i) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: _buildPodiumItem(
                top3[i],
                top3[i].rank,
                i == 0 ? 74.w : 58.w,
                i == 0 ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                isDark,
                isWinner: i == 0,
              ),
            );
          }),
        ),
      );
    }

    final rank2 = top3[1];
    final rank1 = top3[0];
    final rank3 = top3[2];

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumItem(rank2, 2, 58.w, const Color(0xFF94A3B8), isDark),
          SizedBox(width: 14.w),
          _buildPodiumItem(rank1, 1, 74.w, const Color(0xFFF59E0B), isDark, isWinner: true),
          SizedBox(width: 14.w),
          _buildPodiumItem(rank3, 3, 58.w, const Color(0xFFD97706), isDark),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardUser user,
    int rank,
    double avatarSize,
    Color ringColor,
    bool isDark, {
    bool isWinner = false,
  }) {
    String metricValue = '${user.leads} Leads';
    if (_metricIndex == 1) metricValue = user.revenue;
    if (_metricIndex == 2) metricValue = '${user.visits} Visits';

    return GestureDetector(
      onTap: () => _showExecutiveProfile(user),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.military_tech_rounded, color: const Color(0xFFF59E0B), size: 26.sp)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms),
          SizedBox(height: 4.h),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [user.avatarColor, user.avatarColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: ringColor, width: isWinner ? 3.5 : 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.35),
                      blurRadius: isWinner ? 14 : 8,
                      spreadRadius: isWinner ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: isWinner ? 22.sp : 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: ringColor,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            metricValue,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.bold,
              color: isWinner ? const Color(0xFFF59E0B) : AppColors.primary,
            ),
          ),
          Text(
            user.city,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankBanner(LeaderboardUser currentUser, List<LeaderboardUser> allUsers, bool isDark) {
    String myMetricValue = '${currentUser.leads} Leads';
    if (_metricIndex == 1) myMetricValue = currentUser.revenue;
    if (_metricIndex == 2) myMetricValue = '${currentUser.visits} Visits';

    String motivationalText = '🌟 You are currently leading the leaderboard! Keep up the momentum!';
    if (currentUser.rank > 1 && allUsers.length >= currentUser.rank) {
      final targetUser = allUsers[currentUser.rank - 2];
      if (_metricIndex == 0) {
        final diff = (targetUser.leads - currentUser.leads) + 1;
        motivationalText = '🚀 $diff more closed leads to overtake #${targetUser.rank} ${targetUser.name}!';
      } else if (_metricIndex == 1) {
        final diff = (targetUser.rawRevenue - currentUser.rawRevenue) + 5000;
        motivationalText = '🚀 ${_formatRevenue(diff)} more revenue to overtake #${targetUser.rank} ${targetUser.name}!';
      } else {
        final diff = (targetUser.visits - currentUser.visits) + 1;
        motivationalText = '🚀 $diff more visits to overtake #${targetUser.rank} ${targetUser.name}!';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
            AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '#${currentUser.rank}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentUser.name} (You)',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      myMetricValue,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  motivationalText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<LeaderboardUser> users, bool isDark) {
    if (users.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32.w),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No sales representatives found matching "$_searchQuery"'
                : 'No additional team rankings for this period.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemBuilder: (context, index) {
        final user = users[index];
        final isMe = user.isCurrentUser;

        String metricValue = '${user.leads} Leads';
        if (_metricIndex == 1) metricValue = user.revenue;
        if (_metricIndex == 2) metricValue = '${user.visits} Visits';

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => _showExecutiveProfile(user),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26.w,
                      child: Text(
                        '#${user.rank}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isMe ? AppColors.primary : Colors.grey[500],
                        ),
                      ),
                    ),
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [user.avatarColor, user.avatarColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isMe
                                      ? AppColors.primary
                                      : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                ),
                              ),
                              if (isMe) ...[
                                SizedBox(width: 4.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'YOU',
                                    style: TextStyle(
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${user.city} • Win rate ${user.conversionRate}',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          metricValue,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              user.revenue,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.sp,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}
