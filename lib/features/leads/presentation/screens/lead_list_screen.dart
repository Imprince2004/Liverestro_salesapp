import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/lead_model.dart';
import '../providers/lead_providers.dart';
import 'create_lead_screen.dart';
import 'lead_detail_screen.dart';
import '../../../visits/presentation/screens/start_visit_screen.dart';

class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'New',
    'Qualified',
    'Proposal',
    'Negotiation',
    'Won',
    'High Priority',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(leadListProvider.notifier).loadLeads();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    ref.read(leadListProvider.notifier).filterLeads(
          _searchController.text,
          filter,
        );
  }

  Future<void> _makeCall(String phone) async {
    if (phone.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer for $phone'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $phone'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  String _formatTimeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        if (diff.inMinutes <= 1) return 'Just now';
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return '1 day ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else {
        final months = (diff.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
    } catch (_) {
      return 'Recent';
    }
  }

  ({Color bg, Color text, Color dot}) _getStatusColors(String status, bool isDark) {
    final s = status.toLowerCase();
    if (s.contains('won') || s.contains('convert') || s.contains('close')) {
      return (
        bg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        text: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
        dot: const Color(0xFF10B981),
      );
    } else if (s.contains('proposal') || s.contains('demo')) {
      return (
        bg: isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF),
        text: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
        dot: const Color(0xFF9333EA),
      );
    } else if (s.contains('qualified') || s.contains('interest')) {
      return (
        bg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
        text: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        dot: const Color(0xFFF59E0B),
      );
    } else if (s.contains('negotiat') || s.contains('discussion')) {
      return (
        bg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
        text: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        dot: const Color(0xFF3B82F6),
      );
    } else if (s.contains('lost') || s.contains('reject')) {
      return (
        bg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
        text: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        dot: const Color(0xFFEF4444),
      );
    } else {
      // New / Default
      return (
        bg: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
        text: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        dot: const Color(0xFFE11D48),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF714B67),
          onRefresh: () async {
            await ref.read(leadListProvider.notifier).loadLeads();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Top Header inspired by the clean reference mockup
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title & Mauve Circular Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Leads',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  size: 22.sp,
                                ),
                                tooltip: 'Refresh Leads',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(leadListProvider.notifier).loadLeads();
                                },
                              ),
                              SizedBox(width: 4.w),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateLeadScreen()),
                                  );
                                },
                                child: Container(
                                  width: 42.w,
                                  height: 42.w,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF714B67), Color(0xFF5A3451)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF714B67).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Search Input Bar
                      Container(
                        height: 46.h,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (val) => _applyFilter(_selectedFilter),
                                decoration: InputDecoration(
                                  hintText: 'Search restaurants, contacts, Lead ID...',
                                  hintStyle: TextStyle(
                                    fontSize: 13.sp,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _applyFilter(_selectedFilter);
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18.sp,
                                  color: isDark ? Colors.white60 : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Horizontal Filter Chips
                      SizedBox(
                        height: 34.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _applyFilter(filter);
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF714B67)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF714B67)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Lead Count / Subtitle Row
                      Consumer(
                        builder: (context, ref, _) {
                          final leadsAsync = ref.watch(leadListProvider);
                          final count = leadsAsync.value?.length ?? 0;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$count ${count == 1 ? "restaurant" : "restaurants"}',
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              if (_selectedFilter != 'All' || _searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _applyFilter('All');
                                  },
                                  child: Text(
                                    'Clear filters',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF714B67),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Leads List Slivers
              _buildLeadSliverList(isDark),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 80.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadSliverList(bool isDark) {
    final leadsAsync = ref.watch(leadListProvider);

    return leadsAsync.when(
      data: (leads) {
        if (leads.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 36.sp,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No Leads Found',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Try searching by Lead ID, Restaurant Name, or Contact details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lead = leads[index];
                return _buildCompactLeadCard(lead, index, isDark);
              },
              childCount: leads.length,
            ),
          ),
        );
      },
      loading: () => _buildLeadSkeletonList(isDark),
      error: (e, s) => SliverFillRemaining(
        child: Center(
          child: Text(
            'Failed to load leads: $e',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadSkeletonList(bool isDark) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              child: Container(
                height: 104.h,
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  // --- Clean & Compact Reference-Style Lead Card with Swipe Gestures ---
  Widget _buildCompactLeadCard(LeadModel lead, int index, bool isDark) {
    final statusTheme = _getStatusColors(lead.status, isDark);
    final contactName = lead.contactPersonName.isNotEmpty ? lead.contactPersonName : lead.ownerName;
    final dealValueStr = _formatCurrency(lead.estimatedDealValue);
    final timeAgoStr = _formatTimeAgo(lead.createdAt);

    return Dismissible(
      key: ValueKey('lead_dismiss_${lead.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Quick Call
          HapticFeedback.mediumImpact();
          final phone = lead.mobile.isNotEmpty ? lead.mobile : lead.whatsapp;
          if (phone.isNotEmpty) {
            _makeCall(phone);
          } else {
            AppToast.show(context, message: 'No phone number on record for this lead.', type: ToastType.warning);
          }
          return false;
        } else {
          // Swipe Left: Start Pitch Visit
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StartVisitScreen(
                restaurantName: lead.restaurantName,
                address: lead.address.isNotEmpty ? lead.address : '${lead.area}, ${lead.city}',
              ),
            ),
          );
          return false;
        }
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Text('Quick Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7),
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Pitch Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
            SizedBox(width: 8.w),
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeadDetailScreen(lead: lead),
            ),
          );
        },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Cutlery Icon Container (matching reference image)
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D1F2D) : const Color(0xFFF7F2F6),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: const Color(0xFF714B67),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Main Lead Information Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Restaurant / Cafe Name with Colored Dot
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lead.restaurantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                width: 7.w,
                                height: 7.w,
                                decoration: BoxDecoration(
                                  color: statusTheme.dot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Side Deal Value & Chevron
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dealValueStr,
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18.sp,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Lead ID row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Lead ID: ${lead.id}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        if (lead.cuisine.isNotEmpty)
                          Expanded(
                            child: Text(
                              '${lead.cuisine} • ${lead.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Contact Person Name
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            contactName.isNotEmpty ? contactName : 'Contact Person N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Tappable Contact Number (Direct Calling Link)
                    InkWell(
                      onTap: () => _makeCall(lead.mobile),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13.sp,
                              color: const Color(0xFF714B67),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              lead.mobile.isNotEmpty ? lead.mobile : 'No Phone Number',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF714B67),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF714B67).withValues(alpha: 0.4),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.call_made_rounded,
                              size: 11.sp,
                              color: const Color(0xFF714B67),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Bottom Row: Status Pill & Time Ago & Quick WhatsApp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Status Pill
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: statusTheme.bg,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                lead.status,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: statusTheme.text,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Time Ago
                            Text(
                              timeAgoStr,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Quick Action Buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _sendWhatsApp(lead.mobile, contactName, lead.restaurantName),
                              child: Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14.sp,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            GestureDetector(
                              onTap: () => _makeCall(lead.mobile),
                              child: Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF714B67).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  size: 14.sp,
                                  color: const Color(0xFF714B67),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )).animate().fadeIn(duration: 250.ms, delay: (index * 20).ms).slideY(begin: 0.04, end: 0);
  }
}
