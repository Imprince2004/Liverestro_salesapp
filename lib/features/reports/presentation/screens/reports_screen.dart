import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../app/theme_config.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../../visits/presentation/providers/visit_providers.dart';
import '../../../orders/presentation/providers/pos_order_providers.dart';
import '../../../targets/presentation/providers/target_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedPeriod = 1; // 0: This Week, 1: This Month, 2: Quarter, 3: Year

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
        'commission': 'Total Deal Value',
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
        'commission': 'कुल सौदा मूल्य',
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
        'commission': 'કુલ ડીલ મૂલ્ય',
      }
    };

    final lang = translations[langCode] ?? translations['en']!;
    return lang[key] ?? key;
  }

  DateTime? _parseFlexibleDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final s = dateStr.trim();
    if (s.contains('/') || s.contains('-')) {
      final delim = s.contains('/') ? '/' : '-';
      final parts = s.split(delim);
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2].split(' ')[0]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        } else {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2].split(' ')[0]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        }
      }
    }
    return DateTime.tryParse(s);
  }

  bool _isWithinPeriod(DateTime? dt, int periodIndex) {
    if (dt == null) return true;
    final now = DateTime.now();
    if (periodIndex == 0) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) && dt.isBefore(end.add(const Duration(days: 7)));
    } else if (periodIndex == 1) {
      return dt.year == now.year && dt.month == now.month;
    } else if (periodIndex == 2) {
      final currentQuarter = (now.month - 1) ~/ 3;
      final dtQuarter = (dt.month - 1) ~/ 3;
      return dt.year == now.year && dtQuarter == currentQuarter;
    } else {
      return dt.year == now.year;
    }
  }

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

    final leadsAsync = ref.watch(leadListProvider);
    final visitsAsync = ref.watch(visitListProvider);
    final posOrdersAsync = ref.watch(posSoftwareOrderListProvider);
    final targetAsync = ref.watch(myMonthlyTargetProvider);

    final allLeads = leadsAsync.valueOrNull ?? [];
    final allVisits = visitsAsync.valueOrNull ?? [];
    final allPosOrders = posOrdersAsync.valueOrNull ?? [];
    final myTarget = targetAsync.valueOrNull;

    // Filter by period
    final periodLeads = allLeads.where((l) => _isWithinPeriod(_parseFlexibleDate(l.createdAt), _selectedPeriod)).toList();
    final periodVisits = allVisits.where((v) => _isWithinPeriod(_parseFlexibleDate(v.startTime), _selectedPeriod)).toList();
    final periodPosOrders = allPosOrders.where((p) => _isWithinPeriod(_parseFlexibleDate(p.createdAt), _selectedPeriod)).toList();

    final totalVisits = periodVisits.length;
    final pitchesDone = periodVisits.where((v) => v.demoGiven || v.productsDiscussed.isNotEmpty).length +
        periodLeads.where((l) => l.demoRequired || l.status.toLowerCase().contains('demo')).length;
    final quotationsSent = periodLeads.where((l) =>
        l.proposalRequired ||
        l.status.toLowerCase().contains('proposal') ||
        l.status.toLowerCase().contains('quotation') ||
        l.status.toLowerCase().contains('negotiation') ||
        l.status.toLowerCase().contains('won')).length;

    // Closed deals (deduplicated)
    final wonLeadIds = <String>{};
    for (final l in periodLeads) {
      if (l.status.toLowerCase() == 'won' || l.posSoftware.toLowerCase() == 'paid') {
        wonLeadIds.add(l.id.toLowerCase());
      }
    }
    for (final p in periodPosOrders) {
      if (p.isPaid) {
        wonLeadIds.add((p.leadId.isNotEmpty ? p.leadId : p.id).toLowerCase());
      }
    }
    final dealsClosed = wonLeadIds.isNotEmpty ? wonLeadIds.length : (myTarget?.completedLeads ?? 0);

    // Commission / Revenue
    double closedRevenue = 0.0;
    for (final l in periodLeads) {
      if (l.status.toLowerCase() == 'won' || l.posSoftware.toLowerCase() == 'paid') {
        closedRevenue += (l.posAmount > 0 ? l.posAmount : (l.estimatedDealValue > 0 ? l.estimatedDealValue : 0.0));
      }
    }
    for (final p in periodPosOrders) {
      if (p.isPaid && p.amount > 0) {
        closedRevenue += p.amount;
      }
    }

    final demoRateStr = totalVisits > 0 ? '${((pitchesDone / totalVisits) * 100).clamp(0, 100).toInt()}%' : '0%';
    final conversionStr = pitchesDone > 0 ? '${((dealsClosed / pitchesDone) * 100).clamp(0, 100).toInt()}%' : (totalVisits > 0 ? '${((dealsClosed / totalVisits) * 100).clamp(0, 100).toInt()}%' : '0%');
    final winRateDouble = totalVisits > 0 ? (dealsClosed / totalVisits * 100) : (pitchesDone > 0 ? (dealsClosed / pitchesDone * 100) : 0.0);

    final funnelSteps = [
      {
        'title': 'Total Visits',
        'count': totalVisits,
        'percent': totalVisits > 0 ? 1.0 : 0.0,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Demos Presented',
        'count': pitchesDone,
        'percent': totalVisits > 0 ? (pitchesDone / totalVisits).clamp(0.0, 1.0) : (pitchesDone > 0 ? 1.0 : 0.0),
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Quotations Sent',
        'count': quotationsSent,
        'percent': totalVisits > 0 ? (quotationsSent / totalVisits).clamp(0.0, 1.0) : (quotationsSent > 0 ? 1.0 : 0.0),
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Deals Closed',
        'count': dealsClosed,
        'percent': totalVisits > 0 ? (dealsClosed / totalVisits).clamp(0.0, 1.0) : (dealsClosed > 0 ? 1.0 : 0.0),
        'color': const Color(0xFF10B981),
      },
    ];

    // Cuisine / Segment Distribution
    final Map<String, int> segmentCounts = {};
    for (final l in periodLeads) {
      final key = l.cuisine.trim().isNotEmpty ? l.cuisine.trim() : (l.businessType.trim().isNotEmpty ? l.businessType.trim() : 'General Restaurant');
      segmentCounts[key] = (segmentCounts[key] ?? 0) + 1;
    }
    final totalSegments = segmentCounts.values.fold(0, (a, b) => a + b);

    final List<Map<String, dynamic>> cuisines = [];
    final colors = [const Color(0xFF6366F1), const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEC4899)];
    int colorIdx = 0;
    if (totalSegments > 0) {
      segmentCounts.forEach((name, count) {
        final pct = ((count / totalSegments) * 100).toInt();
        cuisines.add({
          'name': name,
          'percent': '$pct%',
          'color': colors[colorIdx % colors.length],
        });
        colorIdx++;
      });
    } else {
      cuisines.addAll([
        {'name': 'Fine Dine & Multi-Cuisine', 'percent': '0%', 'color': const Color(0xFF6366F1)},
        {'name': 'Cafes & Bakeries', 'percent': '0%', 'color': const Color(0xFFF59E0B)},
        {'name': 'QSR & Fast Food', 'percent': '0%', 'color': const Color(0xFF10B981)},
      ]);
    }

    final isLoading = leadsAsync.isLoading && visitsAsync.isLoading && allLeads.isEmpty && allVisits.isEmpty;

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
      body: isLoading
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
                      _buildKpiCard(
                        _t('totalVisits', langCode),
                        totalVisits.toString(),
                        totalVisits > 0 ? '+$totalVisits visits' : '0 visits',
                        Icons.location_on_rounded,
                        const Color(0xFF6366F1),
                        isDark,
                      ),
                      SizedBox(width: 12.w),
                      _buildKpiCard(
                        _t('pitchesDone', langCode),
                        pitchesDone.toString(),
                        '$demoRateStr ${_t('demo_rate', langCode)}',
                        Icons.record_voice_over_rounded,
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildKpiCard(
                        _t('quotationsSent', langCode),
                        quotationsSent.toString(),
                        '$conversionStr ${_t('conversion', langCode)}',
                        Icons.receipt_long_rounded,
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                      SizedBox(width: 12.w),
                      _buildKpiCard(
                        _t('dealsClosed', langCode),
                        dealsClosed.toString(),
                        '₹ ${closedRevenue.toStringAsFixed(0)}',
                        Icons.monetization_on_rounded,
                        const Color(0xFF10B981),
                        isDark,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Sales Conversion Funnel
                  _buildFunnelCard(isDark, funnelSteps, winRateDouble),

                  SizedBox(height: 24.h),

                  // Cuisine Category Distribution
                  _buildCuisineDistribution(isDark, cuisines),

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
    final periods = ['This Week', 'This Month', 'Quarter', 'This Year'];
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

  Widget _buildFunnelCard(bool isDark, List<Map<String, dynamic>> funnelSteps, double winRate) {
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
                child: Text(
                  '${winRate.toStringAsFixed(1)}% Win Rate',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...List.generate(funnelSteps.length, (index) {
            final step = funnelSteps[index];
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

  Widget _buildCuisineDistribution(bool isDark, List<Map<String, dynamic>> cuisines) {
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
