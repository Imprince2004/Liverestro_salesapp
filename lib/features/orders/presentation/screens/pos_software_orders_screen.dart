import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../data/models/pos_software_order_model.dart';
import '../../../leads/data/models/lead_model.dart';
import '../providers/pos_order_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../targets/presentation/screens/monthly_target_implementation_screen.dart';
import '../../../targets/presentation/providers/target_providers.dart';
import '../../../targets/data/models/implementation_model.dart';


class PosSoftwareOrdersScreen extends ConsumerStatefulWidget {
  const PosSoftwareOrdersScreen({super.key});

  @override
  ConsumerState<PosSoftwareOrdersScreen> createState() => _PosSoftwareOrdersScreenState();
}

class _PosSoftwareOrdersScreenState extends ConsumerState<PosSoftwareOrdersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Free', 'Paid'
  final Map<String, bool> _expandedOrders = {};
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ordersAsync = ref.watch(posSoftwareOrderListProvider);
    final implementationsAsync = ref.watch(allImplementationsProvider);
    ref.watch(leadListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'POS Software Clients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(posSoftwareOrderListProvider.notifier).loadOrders();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing POS software clients from database...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'Loading POS clients...',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) {
          String title = 'Unable to Load POS Clients';
          String message = 'We couldn\'t connect to the server right now. Please check your internet connection and try again.';
          IconData icon = Icons.cloud_off_rounded;

          final errStr = err.toString().toLowerCase();
          if (errStr.contains('socketexception') || errStr.contains('connection refused') || errStr.contains('network_error') || errStr.contains('network') || errStr.contains('connect')) {
            title = 'Server Temporarily Unavailable';
            message = 'We\'re unable to connect to LiveRestro right now. Please try again.';
            icon = Icons.cloud_off_rounded;
          } else if (errStr.contains('unauthorized') || errStr.contains('expired') || errStr.contains('401')) {
            title = 'Session Expired';
            message = 'Please log in again to continue.';
            icon = Icons.lock_clock_rounded;
          } else if (errStr.contains('no internet') || errStr.contains('network_unreachable')) {
            title = 'No Internet Connection';
            message = 'Please check your connection and try again.';
            icon = Icons.wifi_off_rounded;
          } else if (errStr.contains('something went wrong')) {
            title = 'Something went wrong';
            message = 'Please try again.';
            icon = Icons.error_outline_rounded;
          }

          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.redAccent, size: 48.sp),
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(posSoftwareOrderListProvider.notifier).loadOrders(),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.point_of_sale_rounded, size: 48.sp, color: AppColors.primary),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No POS Clients Yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'POS software clients will appear here when a restaurant takes the POS software.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          final query = _searchCtrl.text.toLowerCase().trim();
          final filtered = orders.where((item) {
            final matchesFilter = _selectedFilter == 'All' ||
                (_selectedFilter == 'Free' && !item.isPaid) ||
                (_selectedFilter == 'Paid' && item.isPaid);

            final matchesQuery = query.isEmpty ||
                item.restaurantName.toLowerCase().contains(query) ||
                item.leadId.toLowerCase().contains(query) ||
                item.contactPerson.toLowerCase().contains(query) ||
                item.contactPhone.contains(query) ||
                item.location.toLowerCase().contains(query) ||
                item.assignedExecutiveName.toLowerCase().contains(query) ||
                item.assignedManagerName.toLowerCase().contains(query);

            return matchesFilter && matchesQuery;
          }).toList();

          final totalClients = orders.length;
          final freeClients = orders.where((o) => !o.isPaid).length;
          final paidClients = orders.where((o) => o.isPaid).length;
          final totalPaidRevenue = orders.where((o) => o.isPaid).fold<double>(0.0, (sum, o) => sum + o.amount);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Summary Metrics Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Column(
                    children: [
                      _buildSummaryMetrics(
                        isDark: isDark,
                        total: totalClients,
                        free: freeClients,
                        paid: paidClients,
                        revenue: totalPaidRevenue,
                      ),
                      SizedBox(height: 16.h),
                      _buildSearchBarAndFilter(isDark),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),

              // Orders List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56.sp, color: Colors.grey[400]),
                        SizedBox(height: 12.h),
                        Text(
                          'No matching POS clients found',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Try checking the spelling or changing search filter.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = filtered[index];
                        final match = (implementationsAsync.value ?? []).firstWhere(
                          (impl) => impl.leadId == order.leadId || impl.restaurantName.toLowerCase() == order.restaurantName.toLowerCase(),
                          orElse: () => const ImplementationModel(id: '', restaurantName: ''),
                        );
                        return _buildClientOrderCard(context, order, match.id.isNotEmpty ? match : null, isDark);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          final leads = ref.read(leadListProvider).value ?? [];
          _showAddPosOrderDialog(context, isDark, leads);
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New POS Client',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics({
    required bool isDark,
    required int total,
    required int free,
    required int paid,
    required double revenue,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Clients',
                  value: '$total',
                  icon: Icons.storefront_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              Container(height: 40.h, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricTile(
                  title: 'Free Software',
                  value: '$free',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              Container(height: 40.h, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricTile(
                  title: 'Paid Software',
                  value: '$paid',
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFF97316),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: const Color(0xFFF97316), size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Total POS Software Revenue',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(revenue),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5.sp,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBarAndFilter(bool isDark) {
    return Column(
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13.5.sp),
            decoration: InputDecoration(
              hintText: 'Search by Restaurant, Lead ID, Area, Exec...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5.sp),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // Filter Chips
        Row(
          children: [
            _buildFilterChip('All', 'All', isDark),
            SizedBox(width: 8.w),
            _buildFilterChip('Free', '🟢 Free Software', isDark),
            SizedBox(width: 8.w),
            _buildFilterChip('Paid', '💰 Paid Software', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = value);
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientOrderCard(BuildContext context, PosSoftwareOrderModel order, ImplementationModel? match, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Name + Lead ID & Status Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            order.leadId.isNotEmpty ? order.leadId : order.id,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.location_on_outlined, size: 12.sp, color: Colors.grey),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            order.location.isNotEmpty ? order.location : 'Ahmedabad',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // POS Status Badge
              _buildPosStatusBadge(order, isDark),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          SizedBox(height: 10.h),

          // Contact Person & Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 13.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          order.contactPerson.isNotEmpty ? order.contactPerson : 'Manager / Owner',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    if (order.contactPhone.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        order.contactPhone,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              if (order.contactPhone.isNotEmpty) ...[
                IconButton(
                  icon: Icon(Icons.call_rounded, color: const Color(0xFF10B981), size: 18.sp),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(6.w),
                  onPressed: () => launchUrl(Uri.parse('tel:${order.contactPhone}')),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  icon: Icon(Icons.chat_bubble_rounded, color: const Color(0xFF25D366), size: 18.sp),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(6.w),
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/91${order.contactPhone.replaceAll(RegExp(r'[^0-9]'), '')}')),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Team Section: Executive & Manager
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 12.sp, color: Colors.blueAccent),
                    SizedBox(width: 6.w),
                    Text(
                      'Executive: ',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        order.assignedExecutiveName.isNotEmpty ? order.assignedExecutiveName : 'Not Assigned',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, size: 12.sp, color: Colors.purpleAccent),
                    SizedBox(width: 6.w),
                    Text(
                      'Manager: ',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        order.assignedManagerName.isNotEmpty ? order.assignedManagerName : 'Not Assigned',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (match != null) ...[
            _buildImplementationTimeline(context, order, match, isDark),
          ],
          _buildPostSaleFollowUpCard(context, order, match, isDark),
          SizedBox(height: 10.h),

          // Implementation Status & Edit / Upgrade POS Status Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MonthlyTargetImplementationScreen(initialTabIndex: 1),
                    ),
                  );
                },
                icon: Icon(Icons.alt_route_rounded, size: 15.sp, color: const Color(0xFFF97316)),
                label: Text(
                  'Implementation Status',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF97316),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: () => _showEditPosStatusModal(context, order, isDark),
                icon: Icon(Icons.edit_note_rounded, size: 16.sp, color: AppColors.primary),
                label: Text(
                  'Edit / Upgrade POS Status',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImplementationTimeline(BuildContext context, PosSoftwareOrderModel order, ImplementationModel match, bool isDark) {
    final isExpanded = _expandedOrders[order.id] ?? false;
    final currentUser = ref.read(authNotifierProvider).user;
    final isAssignedRep = currentUser != null && order.assignedExecutiveId == currentUser.id;

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _expandedOrders[order.id] = !isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.alt_route_rounded, size: 16.sp, color: const Color(0xFFF97316)),
                    SizedBox(width: 6.w),
                    Text(
                      'Implementation Pipeline',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: match.progressPercent == 100
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${match.progressPercent}%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: match.progressPercent == 100 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: match.progressPercent / 100.0,
              minHeight: 4.h,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                match.progressPercent == 100 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),

          if (isExpanded) ...[
            SizedBox(height: 16.h),
            _buildTimelineStageItem(
              context: context,
              stageNum: '1',
              title: 'Demo',
              status: match.demoStatus,
              executive: match.demoAssignedToName,
              completedDate: match.demoCompletedDate,
              notes: match.demoNotes,
              isDark: isDark,
              onMarkAsDone: isAssignedRep && match.demoStatus != 'COMPLETED'
                  ? () => _markStageAsCompleted(match.id, 'demo')
                  : null,
            ),
            _buildTimelineDivider(isDark, match.demoStatus == 'COMPLETED'),
            _buildTimelineStageItem(
              context: context,
              stageNum: '2',
              title: 'Setup / Installation',
              status: match.setupStatus,
              executive: match.setupAssignedToName,
              completedDate: match.setupCompletedDate,
              notes: match.setupNotes,
              isDark: isDark,
              onMarkAsDone: isAssignedRep && match.demoStatus == 'COMPLETED' && match.setupStatus != 'COMPLETED'
                  ? () => _markStageAsCompleted(match.id, 'setup')
                  : null,
            ),
            _buildTimelineDivider(isDark, match.setupStatus == 'COMPLETED'),
            _buildTimelineStageItem(
              context: context,
              stageNum: '3',
              title: 'Staff Training',
              status: match.trainingStatus,
              executive: match.trainingAssignedToName,
              completedDate: match.trainingCompletedDate,
              notes: match.trainingNotes,
              isDark: isDark,
              onMarkAsDone: isAssignedRep && match.setupStatus == 'COMPLETED' && match.trainingStatus != 'COMPLETED'
                  ? () => _markStageAsCompleted(match.id, 'training')
                  : null,
            ),
            _buildTimelineDivider(isDark, match.trainingStatus == 'COMPLETED'),
            _buildTimelineStageItem(
              context: context,
              stageNum: '4',
              title: 'Completed',
              status: match.overallStatus == 'COMPLETED' ? 'COMPLETED' : 'PENDING',
              executive: order.assignedExecutiveName,
              completedDate: match.overallStatus == 'COMPLETED' ? match.updatedAt.split('T')[0] : '',
              notes: match.overallStatus == 'COMPLETED' ? 'Implementation fully verified!' : 'Awaiting previous stages',
              isDark: isDark,
              onMarkAsDone: null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStageItem({
    required BuildContext context,
    required String stageNum,
    required String title,
    required String status,
    required String executive,
    required String completedDate,
    required String notes,
    required bool isDark,
    required VoidCallback? onMarkAsDone,
  }) {
    Color dotColor = Colors.grey;
    IconData icon = Icons.circle_outlined;
    if (status == 'COMPLETED') {
      dotColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (status == 'IN_PROGRESS' || status == 'ASSIGNED') {
      dotColor = const Color(0xFF3B82F6);
      icon = Icons.pending_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator dot
        Container(
          margin: EdgeInsets.only(top: 2.h),
          child: Icon(icon, color: dotColor, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$stageNum. $title',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: dotColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (executive.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Responsible: $executive',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                ),
              ],
              if (completedDate.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Completed: $completedDate',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
              ],
              if (notes.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  'Remarks: $notes',
                  style: TextStyle(fontSize: 11.sp, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                ),
              ],
              if (onMarkAsDone != null) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  height: 28.h,
                  child: ElevatedButton.icon(
                    onPressed: onMarkAsDone,
                    icon: Icon(Icons.check_rounded, size: 14.sp, color: Colors.white),
                    label: Text(
                      'Mark as Done',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDark, bool isCompleted) {
    return Container(
      height: 16.h,
      margin: EdgeInsets.only(left: 8.w),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 2.w,
          ),
        ),
      ),
    );
  }

  Future<void> _markStageAsCompleted(String implId, String stage) async {
    HapticFeedback.mediumImpact();
    AppToast.show(context, message: 'Updating $stage status to Completed...', type: ToastType.info);

    final success = await ref.read(targetActionProvider.notifier).updateStageStatus(
      id: implId,
      stage: stage,
      status: 'COMPLETED',
      completedDate: DateTime.now().toIso8601String().split('T')[0],
      notes: 'Marked complete by assigned Sales Executive.',
    );

    if (!mounted) return;

    if (success) {
      await ref.read(posSoftwareOrderListProvider.notifier).loadOrders();
      ref.invalidate(allImplementationsProvider);
      AppToast.show(context, message: '🎉 ${stage.toUpperCase()} marked as completed! Pipeline advanced to next stage.');
    } else {
      AppToast.show(context, message: 'Failed to update stage status. Please try again.', type: ToastType.error);
    }
  }

  Widget _buildPosStatusBadge(PosSoftwareOrderModel order, bool isDark) {
    if (order.isPaid) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFF97316), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💰', style: TextStyle(fontSize: 11.sp)),
                SizedBox(width: 4.w),
                Text(
                  'PAID POS',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            Text(
              currencyFormatter.format(order.amount),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🟢', style: TextStyle(fontSize: 11.sp)),
          SizedBox(width: 4.w),
          Text(
            'FREE POS (₹0)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal to Edit / Upgrade POS Status ---
  void _showEditPosStatusModal(BuildContext context, PosSoftwareOrderModel order, bool isDark) {
    String currentType = order.posType;
    final amountCtrl = TextEditingController(text: order.amount > 0 ? order.amount.toInt().toString() : '15000');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Update POS Software Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  order.restaurantName,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16.h),

                // Free / Paid Selector
                Text(
                  'Select POS Software Plan *',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => currentType = 'Free'),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: currentType == 'Free'
                                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: currentType == 'Free' ? const Color(0xFF10B981) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🆓', style: TextStyle(fontSize: 16.sp)),
                              SizedBox(width: 8.w),
                              Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: currentType == 'Free'
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => currentType = 'Paid'),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: currentType == 'Paid'
                                ? const Color(0xFFF97316).withValues(alpha: isDark ? 0.25 : 0.12)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: currentType == 'Paid' ? const Color(0xFFF97316) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('💰', style: TextStyle(fontSize: 16.sp)),
                              SizedBox(width: 8.w),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: currentType == 'Paid'
                                      ? const Color(0xFFF97316)
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (currentType == 'Paid') ...[
                  SizedBox(height: 14.h),
                  Text(
                    'POS Software Amount (₹) *',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15.sp, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFF97316)),
                      hintText: 'e.g. 15000',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    ),
                  ),
                ],

                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amountVal = currentType == 'Paid'
                                ? (double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0.0)
                                : 0.0;

                            if (currentType == 'Paid' && amountVal <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid paid amount (₹)')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final success = await ref.read(posSoftwareOrderListProvider.notifier).updatePosStatus(
                                  orderId: order.id,
                                  posType: currentType,
                                  amount: amountVal,
                                );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success 
                                    ? '✅ POS status updated successfully' 
                                    : '❌ Unable to update POS status\nPlease try again. If the problem continues, check the server connection.'),
                                  backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Modal to Add New POS Order from database leads ---
  void _showAddPosOrderDialog(BuildContext context, bool isDark, List<LeadModel> leads) {
    String selectedLeadId = leads.isNotEmpty ? leads.first.id : '';
    String posType = 'Free';
    final amountCtrl = TextEditingController(text: '15000');
    final customRestaurantCtrl = TextEditingController();
    final customPersonCtrl = TextEditingController();
    final customPhoneCtrl = TextEditingController();
    final customAreaCtrl = TextEditingController(text: 'Ahmedabad');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final selectedLead = leads.where((l) => l.id == selectedLeadId).firstOrNull;

          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
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
                  SizedBox(height: 16.h),
                  Text(
                    'Add POS Software Client',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Select existing restaurant lead from database or create new entry',
                    style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 14.h),

                  if (leads.isEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'No leads available in the database. Please create a lead in the Leads module first.',
                              style: TextStyle(fontSize: 12.sp, color: Colors.redAccent, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  if (leads.isNotEmpty) ...[
                    Text('Select Restaurant Lead from Database *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedLeadId.isNotEmpty ? selectedLeadId : leads.first.id,
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          items: leads.map((l) {
                            return DropdownMenuItem<String>(
                              value: l.id,
                              child: Text(
                                '${l.restaurantName} (${l.id})',
                                style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedLeadId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  if (selectedLead != null) ...[
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('👤 Contact: ${selectedLead.contactPersonName} (${selectedLead.mobile})', style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                          SizedBox(height: 2.h),
                          Text('📍 Location: ${selectedLead.area} ${selectedLead.city}', style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                          SizedBox(height: 2.h),
                          Text('👥 Assigned Rep: ${selectedLead.assignedSalesperson}', style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // Free / Paid Selector
                  Text('POS Software Plan *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => posType = 'Free'),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: posType == 'Free' ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: posType == 'Free' ? const Color(0xFF10B981) : Colors.transparent, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🆓', style: TextStyle(fontSize: 16.sp)),
                                SizedBox(width: 8.w),
                                Text('Free', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: posType == 'Free' ? const Color(0xFF10B981) : (isDark ? Colors.white70 : const Color(0xFF334155)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => posType = 'Paid'),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: posType == 'Paid' ? const Color(0xFFF97316).withValues(alpha: isDark ? 0.25 : 0.12) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: posType == 'Paid' ? const Color(0xFFF97316) : Colors.transparent, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('💰', style: TextStyle(fontSize: 16.sp)),
                                SizedBox(width: 8.w),
                                Text('Paid', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: posType == 'Paid' ? const Color(0xFFF97316) : (isDark ? Colors.white70 : const Color(0xFF334155)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (posType == 'Paid') ...[
                    SizedBox(height: 12.h),
                    Text('POS Software Amount (₹) *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.sp, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFF97316)),
                        hintText: 'e.g. 15000',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                      ),
                    ),
                  ],

                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (leads.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Please register a restaurant lead first.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final amountVal = posType == 'Paid'
                            ? (double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0.0)
                            : 0.0;

                        final payload = {
                          'lead_id': selectedLead?.id ?? 'LR-NEW',
                          'restaurant_name': selectedLead?.restaurantName ?? customRestaurantCtrl.text.trim(),
                          'contact_person': selectedLead?.contactPersonName ?? customPersonCtrl.text.trim(),
                          'contact_phone': selectedLead?.mobile ?? customPhoneCtrl.text.trim(),
                          'location': selectedLead != null ? '${selectedLead.area} ${selectedLead.city}'.trim() : customAreaCtrl.text.trim(),
                          'assigned_executive_id': selectedLead?.assignedSalespersonId ?? ref.read(authNotifierProvider).user?.id,
                          'assigned_executive_name': selectedLead?.assignedSalesperson ?? ref.read(authNotifierProvider).user?.name ?? 'Not Assigned',
                          'pos_type': posType,
                          'amount': amountVal,
                        };

                        final success = await ref.read(posSoftwareOrderListProvider.notifier).createPosOrder(payload);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success 
                                ? '✅ POS Client added successfully' 
                                : '❌ Unable to save POS Client\nPlease try again. If the problem continues, check the server connection.'),
                              backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text('Register POS Client', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildPostSaleFollowUpCard(BuildContext context, PosSoftwareOrderModel order, ImplementationModel? match, bool isDark) {
    final isLive = match?.overallStatus == 'COMPLETED' || order.status.toUpperCase() == 'ACTIVE';

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.2,
        ),
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
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 16),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '1-Month Post-Sale Follow-up',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber[300] : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  isLive ? 'Active Follow-up' : 'Scheduled',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isLive ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            isLive
                ? 'Review client satisfaction, resolve kitchen/billing bugs, and capture hardware & license upsell opportunities.'
                : 'Will activate automatically upon completion of Staff Training stage.',
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark ? Colors.white60 : const Color(0xFF78350F).withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFD97706), width: 1.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(vertical: 6.h),
              ),
              onPressed: () => _showPostSaleFeedbackModal(context, order, isDark),
              icon: const Icon(Icons.rate_review_rounded, size: 15),
              label: Text(
                'Log 1-Month Feedback & Upsell',
                style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostSaleFeedbackModal(BuildContext context, PosSoftwareOrderModel order, bool isDark) {
    int rating = 5;
    final feedbackCtrl = TextEditingController(text: 'Restaurant billing operations are running smoothly.');
    final issuesCtrl = TextEditingController(text: 'None reported. Captain app working fast.');
    final improvementCtrl = TextEditingController();
    final upsellCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1-Month Post-Sale Follow-up',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            order.restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Text('Client Satisfaction Rating', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                SizedBox(height: 6.h),
                Row(
                  children: List.generate(5, (idx) {
                    final starNum = idx + 1;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        starNum <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 32.sp,
                      ),
                      onPressed: () => setModalState(() => rating = starNum),
                    );
                  }),
                ),
                SizedBox(height: 12.h),

                Text('Client Feedback / Review', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                SizedBox(height: 6.h),
                TextField(
                  controller: feedbackCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Billing is fast, waiters adapted to Captain App within 2 days...',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.all(10.w),
                  ),
                ),
                SizedBox(height: 12.h),

                Text('Issues / Bugs Reported (if any)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                SizedBox(height: 6.h),
                TextField(
                  controller: issuesCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. None / Thermal printer Bluetooth sync solved',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.all(10.w),
                  ),
                ),
                SizedBox(height: 12.h),

                Text('Additional Hardware / Upsell Requirements', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                SizedBox(height: 6.h),
                TextField(
                  controller: upsellCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Client requested 2 extra Captain Apps + 2nd Kitchen KDS Printer',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.all(10.w),
                  ),
                ),
                SizedBox(height: 18.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      HapticFeedback.mediumImpact();

                      try {
                        final apiClient = getIt<ApiClient>();
                        final payload = {
                          'rating': rating,
                          'client_feedback': feedbackCtrl.text.trim(),
                          'issues_reported': issuesCtrl.text.trim(),
                          'improvement_requests': improvementCtrl.text.trim(),
                          'additional_requirements': upsellCtrl.text.trim(),
                          'status': 'COMPLETED',
                        };

                        final res = await apiClient.post('/api/pos-orders/${order.id}/post-sale-followup', data: payload);
                        if (!mounted) return;

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          Navigator.pop(modalCtx);
                          ref.read(posSoftwareOrderListProvider.notifier).loadOrders();
                          AppToast.show(context, message: '⭐ 1-Month Post-Sale Review & Feedback recorded in database!');
                        } else {
                          AppToast.show(context, message: 'Failed to record feedback.', type: ToastType.error);
                        }
                      } catch (e) {
                        if (mounted) AppToast.show(context, message: 'Error saving feedback: $e', type: ToastType.error);
                      } finally {
                        if (mounted) setModalState(() => isSubmitting = false);
                      }
                    },
                    icon: isSubmitting
                        ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.done_all_rounded, color: Colors.white),
                    label: Text(
                      isSubmitting ? 'Saving to Database...' : 'Save Post-Sale Review',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
