import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../leads/data/models/follow_up_model.dart';
import '../../../leads/presentation/providers/follow_ups_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  int _currentMonthOffset = 0;

  void _showScheduleModal() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
  void _showScheduleModal() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedType = 'Restaurant Visit';
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
                        labelText: 'Restaurant / Outlet Name *',
                        prefixIcon: Icon(Icons.restaurant_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Owner / Contact Person',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone / Mobile',
                        prefixIcon: Icon(Icons.phone_outlined),
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
                        DropdownMenuItem(value: 'Restaurant Visit', child: Text('Restaurant Visit')),
                        DropdownMenuItem(value: 'Software Demo', child: Text('Software Demo')),
                        DropdownMenuItem(value: 'Software Setup/Installation', child: Text('Software Setup/Installation')),
                        DropdownMenuItem(value: 'Staff Training', child: Text('Staff Training')),
                        DropdownMenuItem(value: 'POS Upgrade & Quotation', child: Text('POS Upgrade & Quotation')),
                        DropdownMenuItem(value: 'Contract Signature & KYC', child: Text('Contract Signature & KYC')),
                        DropdownMenuItem(value: 'Phone Call Follow-Up', child: Text('Phone Call Follow-Up')),
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
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter restaurant name')),
                            );
                            return;
                          }

                          final scheduledDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          await ref.read(followUpsProvider.notifier).createFollowUp(
                                restaurantName: nameCtrl.text.trim(),
                                contactPerson: contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : 'Owner / Manager',
                                phone: phoneCtrl.text.trim(),
                                address: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : 'Ahmedabad',
                                type: selectedType,
                                priority: 'Interested',
                                scheduledTime: scheduledDateTime,
                                notes: 'Scheduled via Sales Visit Calendar',
                              );

                          ref.invalidate(followUpsProvider);

                          if (mounted) {
                            Navigator.pop(ctx);
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📅 Visit added to schedule successfully!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
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

  Map<String, List<CalendarEvent>> _buildEventsMap(List<FollowUpModel> followUps) {
    final map = <String, List<CalendarEvent>>{};

    for (final f in followUps) {
      final dateKey = DateFormat('yyyy-MM-dd').format(f.scheduledTime);
      final timeStr = DateFormat('hh:mm a').format(f.scheduledTime);

      Color eventColor;
      String statusStr;
      if (f.status.toUpperCase() == 'COMPLETED') {
        eventColor = const Color(0xFF10B981);
        statusStr = 'Completed';
      } else if (f.computedStatus == FollowUpStatus.overdue) {
        eventColor = const Color(0xFFEF4444);
        statusStr = 'Overdue';
      } else if (f.computedStatus == FollowUpStatus.today) {
        eventColor = const Color(0xFF3B82F6);
        statusStr = 'Today';
      } else {
        eventColor = const Color(0xFF6366F1);
        statusStr = 'Upcoming';
      }

      final event = CalendarEvent(
        id: f.id,
        time: timeStr,
        title: f.restaurantName,
        contactPerson: f.contactPerson,
        phone: f.phone,
        location: f.address.isNotEmpty ? f.address : 'Ahmedabad',
        type: f.followUpType,
        status: statusStr,
        color: eventColor,
        assignedSalesperson: f.assignedSalesperson,
      );

      map.putIfAbsent(dateKey, () => []).add(event);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month + _currentMonthOffset, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final followUpsState = ref.watch(followUpsProvider);
    final eventsMap = _buildEventsMap(followUpsState.allFollowUps);
    final eventsForDay = eventsMap[selectedKey] ?? [];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Calendar',
            onPressed: () => ref.read(followUpsProvider.notifier).loadFollowUps(),
          ),
        ],
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
                final hasEvents = eventsMap.containsKey(dateKey) && eventsMap[dateKey]!.isNotEmpty;

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
                  'Agenda for ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
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
                          'No visits or follow-ups scheduled for this date',
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
                                  if (evt.contactPerson.isNotEmpty && evt.contactPerson != 'Owner') ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Contact: ${evt.contactPerson} ${evt.phone.isNotEmpty ? "(${evt.phone})" : ""}',
                                      style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : Colors.black54),
                                    ),
                                  ],
                                  if (evt.assignedSalesperson != null && evt.assignedSalesperson!.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Sales Rep: ${evt.assignedSalesperson}',
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
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
                                      Expanded(
                                        child: Text(
                                          evt.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                                        ),
                                      ),
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
  final String id;
  final String time;
  final String title;
  final String contactPerson;
  final String phone;
  final String location;
  final String type;
  final String status;
  final Color color;
  final String? assignedSalesperson;

  CalendarEvent({
    required this.id,
    required this.time,
    required this.title,
    this.contactPerson = '',
    this.phone = '',
    required this.location,
    required this.type,
    required this.status,
    required this.color,
    this.assignedSalesperson,
  });
}
