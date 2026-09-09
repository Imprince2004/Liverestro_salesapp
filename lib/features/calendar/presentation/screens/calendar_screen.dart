import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  int _currentMonthOffset = 0;

  final Map<String, List<CalendarEvent>> _eventsMap = {
    DateFormat('yyyy-MM-dd').format(DateTime.now()): [
      CalendarEvent(
        time: '10:00 AM',
        title: 'The Yellow Chili Fine Dine',
        location: 'Maninagar, Ahmedabad',
        type: 'Pitch & Demo',
        status: 'Completed',
        color: const Color(0xFF10B981),
      ),
      CalendarEvent(
        time: '11:30 AM',
        title: 'Cafe Coffee Lounge',
        location: 'Navrangpura, Ahmedabad',
        type: 'KDS Setup Discussion',
        status: 'In Progress',
        color: const Color(0xFF3B82F6),
      ),
      CalendarEvent(
        time: '02:15 PM',
        title: 'Saffron Multi Cuisine',
        location: 'Bodakdev, Ahmedabad',
        type: 'Pricing & Negotiation',
        status: 'Upcoming',
        color: const Color(0xFFF59E0B),
      ),
      CalendarEvent(
        time: '04:30 PM',
        title: 'The Royal Spice Dine',
        location: 'SG Highway, Ahmedabad',
        type: 'Contract Signing Visit',
        status: 'Upcoming',
        color: const Color(0xFF6366F1),
      ),
    ],
    DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))): [
      CalendarEvent(
        time: '11:00 AM',
        title: 'Radhe Restaurant & Banquet',
        location: 'Vesu, Surat',
        type: 'Contract Signature & KYC',
        status: 'Upcoming',
        color: const Color(0xFF6366F1),
      ),
      CalendarEvent(
        time: '03:30 PM',
        title: 'Swad Kathiyawadi',
        location: 'Chandkheda, Ahmedabad',
        type: 'Product Presentation',
        status: 'Upcoming',
        color: const Color(0xFFF59E0B),
      ),
    ],
  };

  void _showScheduleModal() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String selectedType = 'Pitch & Demo';
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h,
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
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Schedule Visit for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name *',
                        prefixIcon: Icon(Icons.restaurant_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location / Area *',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Objective',
                        prefixIcon: Icon(Icons.assignment_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pitch & Demo', child: Text('Pitch & Demo')),
                        DropdownMenuItem(value: 'KDS Setup Discussion', child: Text('KDS Setup Discussion')),
                        DropdownMenuItem(value: 'Pricing & Negotiation', child: Text('Pricing & Negotiation')),
                        DropdownMenuItem(value: 'Contract Signature & KYC', child: Text('Contract Signature & KYC')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    SizedBox(height: 14.h),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                      ),
                      leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                      title: Text(
                        'Time Slot: ${selectedTime.format(context)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: selectedTime);
                        if (t != null) setModalState(() => selectedTime = t);
                      },
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
                          final newEvt = CalendarEvent(
                            time: selectedTime.format(context),
                            title: nameCtrl.text.trim(),
                            location: locationCtrl.text.trim().isEmpty ? 'Ahmedabad' : locationCtrl.text.trim(),
                            type: selectedType,
                            status: 'Upcoming',
                            color: const Color(0xFF6366F1),
                          );
                          setState(() {
                            _eventsMap.putIfAbsent(dateKey, () => []).add(newEvt);
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📅 Visit added to schedule successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text('Confirm Schedule', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month + _currentMonthOffset, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final eventsForDay = _eventsMap[selectedKey] ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Sales Visit Calendar',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Schedule Visit', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
        onPressed: _showScheduleModal,
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() => _currentMonthOffset--),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _currentMonthOffset++),
                ),
              ],
            ),
          ),

          // Horizontal Date Selector Strip
          Container(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            height: 84.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(currentMonth.year, currentMonth.month, day);
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final hasEvents = _eventsMap.containsKey(dateKey) && _eventsMap[dateKey]!.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = date);
                  },
                  child: Container(
                    width: 50.w,
                    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 2),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (hasEvents) ...[
                          SizedBox(height: 3.h),
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Day Agenda Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agenda for ${DateFormat('dd MMMM').format(_selectedDate)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${eventsForDay.length} Scheduled',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: eventsForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 50.sp, color: Colors.grey[300]),
                        SizedBox(height: 10.h),
                        Text(
                          'No visits scheduled for this date',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13.5.sp, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 12.h),
                        OutlinedButton.icon(
                          onPressed: _showScheduleModal,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Visit'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 80.h),
                    itemCount: eventsForDay.length,
                    itemBuilder: (context, index) {
                      final evt = eventsForDay[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: evt.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 16.sp, color: evt.color),
                                  SizedBox(height: 4.h),
                                  Text(
                                    evt.time,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: evt.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          evt.title,
                                          style: TextStyle(
                                            fontSize: 14.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: evt.color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          evt.status,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: evt.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    evt.type,
                                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 12.sp, color: Colors.grey),
                                      SizedBox(width: 4.w),
                                      Text(evt.location, style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CalendarEvent {
  final String time;
  final String title;
  final String location;
  final String type;
  final String status;
  final Color color;

  CalendarEvent({
    required this.time,
    required this.title,
    required this.location,
    required this.type,
    required this.status,
    required this.color,
  });
}
