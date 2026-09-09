import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final hive = getIt<HiveStorageService>();
    final savedLogs = hive.get<String>('attendance_logs_cache');
    final List<Map<String, dynamic>> list = [];

    // Also check today's current check-in / check-out
    final todayCheckIn = hive.get<String>('last_check_in_time');
    final todayCheckOut = hive.get<String>('last_check_out_time');
    final todayStatus = hive.get<String>('attendance_status') ?? 'Not Checked In';

    if (savedLogs != null && savedLogs.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedLogs);
        list.addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }

    // If today's active attendance is present but not logged yet in history list, include it
    if (todayCheckIn != null && todayCheckIn.isNotEmpty) {
      try {
        final todayDt = DateTime.parse(todayCheckIn);
        final todayDateStr = DateFormat('yyyy-MM-dd').format(todayDt);

        final alreadyPresent = list.any((item) {
          final ts = item['timestamp'] as String?;
          if (ts == null) return false;
          try {
            return DateFormat('yyyy-MM-dd').format(DateTime.parse(ts)) == todayDateStr;
          } catch (_) {
            return false;
          }
        });

        if (!alreadyPresent) {
          String? outStr;
          String totalHours = '--';
          if (todayCheckOut != null && todayCheckOut.isNotEmpty) {
            final outDt = DateTime.parse(todayCheckOut);
            outStr = DateFormat('hh:mm a').format(outDt);
            final diff = outDt.difference(todayDt);
            totalHours = '${diff.inHours}h ${diff.inMinutes % 60}m';
          } else {
            final diff = DateTime.now().difference(todayDt);
            totalHours = '${diff.inHours}h ${diff.inMinutes % 60}m';
          }

          list.insert(0, {
            'timestamp': todayCheckIn,
            'status': todayStatus,
            'checkIn': DateFormat('hh:mm a').format(todayDt),
            'checkOut': outStr ?? 'Not Checked Out',
            'totalHours': totalHours,
          });
        }
      } catch (_) {}
    }

    setState(() {
      _attendanceHistory = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Attendance History',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 56.sp, color: Colors.grey[400]),
                        SizedBox(height: 12.h),
                        Text(
                          'No Attendance Records',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Your completed and ongoing shifts will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  itemCount: _attendanceHistory.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = _attendanceHistory[index];
                    DateTime? dt;
                    try {
                      final ts = item['timestamp'] as String?;
                      if (ts != null) dt = DateTime.parse(ts);
                    } catch (_) {}

                    final dateFormatted = dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'Recorded Shift';
                    final inTime = item['checkIn'] ?? (dt != null ? DateFormat('hh:mm a').format(dt) : '--:-- --');
                    final outTime = item['checkOut'] ?? item['checkOutTime'] ?? 'Not Checked Out';
                    final total = item['totalHours'] ?? '--';
                    final isCompleted = outTime != 'Not Checked Out' && outTime != '--:-- --';

                    return Container(
                      padding: EdgeInsets.all(16.w),
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
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14.sp, color: AppColors.primary),
                                  SizedBox(width: 6.w),
                                  Text(
                                    dateFormatted,
                                    style: TextStyle(
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: (isCompleted ? const Color(0xFF10B981) : Colors.orange).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  isCompleted ? 'Present' : 'On-Duty',
                                  style: TextStyle(
                                    color: isCompleted ? const Color(0xFF10B981) : Colors.orange,
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          const Divider(height: 1),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniColumn('Check In', inTime, isDark),
                              _buildMiniColumn('Check Out', outTime, isDark),
                              _buildMiniColumn('Total Hours', total, isDark, isHighlight: true),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMiniColumn(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? AppColors.primary
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
