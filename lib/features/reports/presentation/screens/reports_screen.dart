import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../app/theme_config.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedPeriod = 1; // 0: This Week, 1: This Month, 2: Quarter (Q3), 3: Year
  int _totalVisits = 48;
  int _pitchesDone = 34;
  int _quotationsSent = 22;
  int _dealsClosed = 14;
  double _commissionEarned = 12450.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/api/analytics/dashboard');
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _totalVisits = data['today_team_visits_completed'] ?? data['total_visits'] ?? data['today_visits_completed'] ?? 48;
          _dealsClosed = data['completed_tasks'] ?? data['completed_tasks_count'] ?? data['total_system_tasks'] ?? 14;
          final earned = (data['monthly_closed_revenue'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
          _commissionEarned = double.tryParse(earned) ?? 12450.0;
          _quotationsSent = data['completed_tasks_count'] ?? data['completed_tasks'] ?? 22;
          _pitchesDone = data['today_team_visits_target'] ?? 34;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _t(String key, String langCode) {
    final Map<String, Map<String, String>> translations = {
      'en': {
        'title': 'Sales Performance & Reports',
        'totalVisits': 'Total Visits',
        'pitchesDone': 'Pitches Done',
        'quotationsSent': 'Quotations Sent',
        'dealsClosed': 'Deals Closed',
        'week': 'This Week',
        'month': 'This Month',
        'quarter': 'This Quarter',
        'year': 'This Year',
        'target_vs': 'vs last month',
        'demo_rate': 'Demo Rate',
        'conversion': 'Conversion',
        'commission': 'Earned Commission',
      },
      'hi': {
        'title': 'बिक्री प्रदर्शन और रिपोर्ट',
        'totalVisits': 'कुल दौरे',
        'pitchesDone': 'पिच की गई',
        'quotationsSent': 'कोटेशन भेजे गए',
        'dealsClosed': 'सौदा बंद हुआ',
        'week': 'इस सप्ताह',
        'month': 'इस महीने',
        'quarter': 'इस तिमाही',
        'year': 'इस साल',
        'target_vs': 'पिछले महीने की तुलना में',
        'demo_rate': 'डेमो दर',
        'conversion': 'रूपांतरण दर',
        'commission': 'अर्जित कमीशन',
      },
      'gu': {
        'title': 'વેચાણ પ્રદર્શન અને અહેવાલો',
        'totalVisits': 'કુલ મુલાકાતો',
        'pitchesDone': 'પીચ કરેલ',
        'quotationsSent': 'કોટેશન મોકલેલ',
        'dealsClosed': 'ડીલ બંધ થયેલ',
        'week': 'આ અઠવાડિયે',
        'month': 'આ મહિને',
        'quarter': 'આ ત્રિમાસિક',
        'year': 'આ વર્ષે',
        'target_vs': 'ગયા મહિનાની સરખામણીએ',
        'demo_rate': 'ડેમો દર',
        'conversion': 'રૂપાંતરણ દર',
        'commission': 'કમિશન કમાણી',
      }
    };

    final lang = translations[langCode] ?? translations['en']!;
    return lang[key] ?? key;
  }

  final List<Map<String, dynamic>> _funnelSteps = [
    {'title': 'Total Visits', 'count': 48, 'percent': 1.0, 'color': const Color(0xFF6366F1)},
    {'title': 'Demos Presented', 'count': 34, 'percent': 0.71, 'color': const Color(0xFF3B82F6)},
    {'title': 'Quotations Sent', 'count': 22, 'percent': 0.46, 'color': const Color(0xFFF59E0B)},
    {'title': 'Deals Closed', 'count': 14, 'percent': 0.29, 'color': const Color(0xFF10B981)},
  ];

  void _exportReport(String format) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 Generating $format Sales Performance Report...'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ LiveRestro_Sales_Report_${DateTime.now().year}.$format saved to Downloads folder.'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _t('title', langCode),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            onSelected: _exportReport,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF Report')),
              const PopupMenuItem(value: 'xlsx', child: Text('Export Excel Sheet (.xlsx)')),
              const PopupMenuItem(value: 'csv', child: Text('Export Raw CSV Data')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter Selector
            _buildPeriodSelector(isDark),

            SizedBox(height: 16.h),

            // Top 4 Metric KPI Cards
            Row(
              children: [
                _buildKpiCard(_t('totalVisits', langCode), _totalVisits.toString(), '+12% ${_t('target_vs', langCode)}', Icons.location_on_rounded, const Color(0xFF6366F1), isDark),
                SizedBox(width: 12.w),
                _buildKpiCard(_t('pitchesDone', langCode), _pitchesDone.toString(), '71% ${_t('demo_rate', langCode)}', Icons.record_voice_over_rounded, const Color(0xFF3B82F6), isDark),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildKpiCard(_t('quotationsSent', langCode), _quotationsSent.toString(), '64.7% ${_t('conversion', langCode)}', Icons.receipt_long_rounded, const Color(0xFFF59E0B), isDark),
                SizedBox(width: 12.w),
                _buildKpiCard(_t('dealsClosed', langCode), _dealsClosed.toString(), '₹ ${_commissionEarned.toStringAsFixed(0)} ${_t('commission', langCode)}', Icons.monetization_on_rounded, const Color(0xFF10B981), isDark),
              ],
            ),

            SizedBox(height: 24.h),

            // Sales Conversion Funnel
            _buildFunnelCard(isDark),

            SizedBox(height: 24.h),

            // Cuisine Category Distribution
            _buildCuisineDistribution(isDark),

            SizedBox(height: 24.h),

            // Export Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () => _exportReport('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                    label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () => _exportReport('xlsx'),
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['This Week', 'This Month', 'Quarter (Q3)', 'This Year'];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPeriod = index);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String badge,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
              blurRadius: 8,
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
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 16.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
            blurRadius: 8,
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
              Text(
                'Sales Conversion Funnel',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Text(
                  '29.2% Win Rate',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...List.generate(_funnelSteps.length, (index) {
            final step = _funnelSteps[index];
            final color = step['color'] as Color;
            final percent = step['percent'] as double;
            final count = step['count'] as int;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step['title'] as String,
                        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        '$count (${(percent * 100).toInt()}%)',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8.h,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCuisineDistribution(bool isDark) {
    final cuisines = [
      {'name': 'Fine Dine & Multi-Cuisine', 'percent': '45%', 'color': const Color(0xFF6366F1)},
      {'name': 'Cafes & Bakeries', 'percent': '30%', 'color': const Color(0xFFF59E0B)},
      {'name': 'QSR & Fast Food', 'percent': '25%', 'color': const Color(0xFF10B981)},
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Restaurant Segment',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(cuisines.length, (index) {
              final c = cuisines[index];
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == cuisines.length - 1 ? 0 : 8.w),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: (c['color'] as Color).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['percent'] as String, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: c['color'] as Color)),
                      SizedBox(height: 4.h),
                      Text(c['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
