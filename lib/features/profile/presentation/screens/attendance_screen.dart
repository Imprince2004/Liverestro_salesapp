import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../routes/route_names.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/attendance_service.dart';
import 'check_in_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _timer;
  DateTime _selectedDate = DateTime.now();
  String _displayDateStr = '';
  String _checkInTimeStr = '--:-- --';
  String _checkOutTimeStr = '--:-- --';
  String _status = 'Not Checked In';
  String _totalWorkingHoursStr = '--';
  bool _hasRecordForSelectedDate = true;

  DateTime? _checkInDateTime;
  DateTime? _checkOutDateTime;
  List<Map<String, dynamic>> _attendanceHistory = [];

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _loadHistoryLogs();
    _loadDataForSelectedDate(_selectedDate);
    _checkAutomaticCheckOut();

    // Sync any pending offline records when screen loads
    AttendanceService().syncPendingRecords();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _isToday) {
        _calculateWorkingHours();
        _checkAutomaticCheckOut();
        AttendanceService().syncPendingRecords();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadHistoryLogs() {
    final hive = getIt<HiveStorageService>();
    final savedLogs = hive.get<String>('attendance_logs_cache');
    if (savedLogs != null && savedLogs.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedLogs);
        _attendanceHistory = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
  }

  void _loadDataForSelectedDate(DateTime date) {
    _selectedDate = date;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    final hive = getIt<HiveStorageService>();

    if (isToday) {
      _displayDateStr = 'Today, ${DateFormat('dd MMM yyyy').format(now)}';
      final savedStatus = hive.get<String>('attendance_status');
      final savedCheckIn = hive.get<String>('last_check_in_time');
      final savedCheckOut = hive.get<String>('last_check_out_time');

      _hasRecordForSelectedDate = savedCheckIn != null && savedCheckIn.isNotEmpty;

      if (_hasRecordForSelectedDate) {
        try {
          final inDt = DateTime.parse(savedCheckIn!);
          _checkInDateTime = inDt;
          _checkInTimeStr = DateFormat('hh:mm a').format(inDt);
          _status = savedStatus ?? 'Checked In';
        } catch (_) {
          _checkInTimeStr = '--:-- --';
          _status = 'Not Checked In';
        }

        if (savedCheckOut != null && savedCheckOut.isNotEmpty) {
          try {
            final outDt = DateTime.parse(savedCheckOut);
            _checkOutDateTime = outDt;
            _checkOutTimeStr = DateFormat('hh:mm a').format(outDt);
            _status = 'Checked Out';
          } catch (_) {
            _checkOutTimeStr = 'Not Checked Out';
          }
        } else {
          _checkOutDateTime = null;
          _checkOutTimeStr = 'Not Checked Out';
        }

        _calculateWorkingHours();
      } else {
        _checkInDateTime = null;
        _checkOutDateTime = null;
        _checkInTimeStr = '--:-- --';
        _checkOutTimeStr = '--:-- --';
        _status = 'Not Checked In';
        _totalWorkingHoursStr = '--';
      }
    } else {
      // Historical Selected Date
      _displayDateStr = DateFormat('dd MMM yyyy').format(date);
      final targetDateStr = DateFormat('yyyy-MM-dd').format(date);

      Map<String, dynamic>? match;
      for (final item in _attendanceHistory) {
        final ts = item['timestamp'] as String?;
        if (ts != null) {
          try {
            final dt = DateTime.parse(ts);
            if (DateFormat('yyyy-MM-dd').format(dt) == targetDateStr) {
              match = item;
              break;
            }
          } catch (_) {}
        }
      }

      if (match != null) {
        _hasRecordForSelectedDate = true;
        DateTime? dt;
        try {
          dt = DateTime.parse(match['timestamp']);
        } catch (_) {}

        _checkInTimeStr = match['checkIn'] ?? (dt != null ? DateFormat('hh:mm a').format(dt) : '--:-- --');
        _checkOutTimeStr = match['checkOut'] ?? match['checkOutTime'] ?? 'Not Checked Out';
        _totalWorkingHoursStr = match['totalHours'] ?? '--';
        _status = match['status'] ?? (_checkOutTimeStr != 'Not Checked Out' ? 'Checked Out' : 'Present');
      } else {
        _hasRecordForSelectedDate = false;
        _checkInTimeStr = '--:-- --';
        _checkOutTimeStr = '--:-- --';
        _status = 'No Record';
        _totalWorkingHoursStr = '--';
      }
    }

    setState(() {});
  }

  void _calculateWorkingHours() {
    if (!_isToday) return;

    if (_checkInDateTime == null) {
      setState(() {
        _totalWorkingHoursStr = '--';
      });
      return;
    }

    final end = _checkOutDateTime ?? DateTime.now();
    final diff = end.difference(_checkInDateTime!);

    if (diff.isNegative) {
      setState(() {
        _totalWorkingHoursStr = '0h 0m';
      });
      return;
    }

    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final formatted = '${hours}h ${mins}m';

    setState(() {
      _totalWorkingHoursStr = formatted;
    });
  }

  void _checkAutomaticCheckOut() async {
    if (!_isToday) return;

    final hive = getIt<HiveStorageService>();
    final savedStatus = hive.get<String>('attendance_status');
    if (savedStatus == 'Checked In') {
      final savedCheckIn = hive.get<String>('last_check_in_time');
      if (savedCheckIn != null && savedCheckIn.isNotEmpty) {
        try {
          final checkInDateTime = DateTime.parse(savedCheckIn);
          final eightHoursLater = checkInDateTime.add(const Duration(hours: 8));
          if (DateTime.now().isAfter(eightHoursLater)) {
            await _performAutomaticCheckOut(eightHoursLater);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _performAutomaticCheckOut(DateTime checkOutTime) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double lat = 0.0;
    double lng = 0.0;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    final hive = getIt<HiveStorageService>();
    await hive.put('last_check_out_time', checkOutTime.toIso8601String());
    await hive.put('attendance_status', 'Checked Out');

    final attendanceService = AttendanceService();
    await attendanceService.checkOut(lat, lng, checkOutTime, true);
    attendanceService.syncPendingRecords();

    if (!mounted) return;
    setState(() {
      _checkOutDateTime = checkOutTime;
      _checkOutTimeStr = DateFormat('hh:mm a').format(checkOutTime);
      _status = 'Checked Out';
    });
    _calculateWorkingHours();

    if (_attendanceHistory.isNotEmpty) {
      _attendanceHistory[0]['checkOutTime'] = _checkOutTimeStr;
      _attendanceHistory[0]['totalHours'] = _totalWorkingHoursStr;
      _attendanceHistory[0]['status'] = 'Completed';
      await hive.put('attendance_logs_cache', jsonEncode(_attendanceHistory));
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 48.sp),
            SizedBox(height: 8.h),
            const Text('Automatic Check-Out Triggered', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have been automatically checked out 8 hours after shift start.', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Check In', _checkInTimeStr),
                  SizedBox(height: 6.h),
                  _buildSummaryRow('Check Out (Auto)', _checkOutTimeStr),
                  SizedBox(height: 6.h),
                  _buildSummaryRow('Total Working Hours', _totalWorkingHoursStr),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double lat = 0.0;
    double lng = 0.0;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    final now = DateTime.now();
    final hive = getIt<HiveStorageService>();
    await hive.put('last_check_out_time', now.toIso8601String());
    await hive.put('attendance_status', 'Checked Out');

    final attendanceService = AttendanceService();
    await attendanceService.checkOut(lat, lng, now, false);
    attendanceService.syncPendingRecords();

    setState(() {
      _checkOutDateTime = now;
      _checkOutTimeStr = DateFormat('hh:mm a').format(now);
      _status = 'Checked Out';
    });
    _calculateWorkingHours();

    if (_attendanceHistory.isNotEmpty) {
      _attendanceHistory[0]['checkOutTime'] = _checkOutTimeStr;
      _attendanceHistory[0]['totalHours'] = _totalWorkingHoursStr;
      _attendanceHistory[0]['status'] = 'Completed';
      await hive.put('attendance_logs_cache', jsonEncode(_attendanceHistory));
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981), size: 48.sp),
            SizedBox(height: 8.h),
            const Text('Checked Out Successfully!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your shift for today has been concluded.', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Check In', _checkInTimeStr),
                  SizedBox(height: 6.h),
                  _buildSummaryRow('Check Out', _checkOutTimeStr),
                  SizedBox(height: 6.h),
                  _buildSummaryRow('Total Working Hours', _totalWorkingHoursStr),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
        Text(val, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _selectCalendarDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _loadHistoryLogs();
      _loadDataForSelectedDate(picked);
    }
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
          'Attendance',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            tooltip: 'Select Date',
            onPressed: _selectCalendarDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date & Check In/Out Card
            _buildDateAttendanceCard(context, isDark),
            SizedBox(height: 20.h),

            // 2. Total Working Hours Card
            if (_hasRecordForSelectedDate) ...[
              _buildWorkingHoursCard(context, isDark),
              SizedBox(height: 24.h),
            ] else ...[
              _buildNoRecordCard(isDark),
              SizedBox(height: 24.h),
            ],

            // 3. Action Buttons
            if (_isToday && _status == 'Checked In') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                onPressed: _performCheckOut,
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Conclude Shift (Check Out)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              SizedBox(height: 14.h),
            ] else if (_isToday && _status == 'Not Checked In') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInScreen()),
                  ).then((_) {
                    _loadHistoryLogs();
                    _loadDataForSelectedDate(DateTime.now());
                  });
                },
                icon: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Start Day (Check In)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              SizedBox(height: 14.h),
            ],

            PrimaryButton(
              text: 'View Attendance History',
              icon: Icons.history_rounded,
              onPressed: () {
                context.push(RouteNames.attendanceHistory);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAttendanceCard(BuildContext context, bool isDark) {
    Color badgeColor = Colors.grey;
    if (_status == 'Checked In' || _status == 'Present') {
      badgeColor = const Color(0xFF10B981);
    } else if (_status == 'Checked Out' || _status == 'Completed') {
      badgeColor = const Color(0xFF2563EB);
    } else if (_status == 'Not Checked In') {
      badgeColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    _displayDateStr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeColumn('Check In', _checkInTimeStr, isDark),
              Container(
                height: 44.h,
                width: 1,
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
              _buildTimeColumn('Check Out', _checkOutTimeStr, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, bool isDark) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: AppColors.primary, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Total Working Hours',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          Text(
            _totalWorkingHoursStr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 36.sp, color: Colors.grey[400]),
          SizedBox(height: 10.h),
          Text(
            'No attendance record found for this date.',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
