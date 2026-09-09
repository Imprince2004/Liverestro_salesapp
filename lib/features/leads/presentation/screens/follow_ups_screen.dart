import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../data/models/follow_up_model.dart';
import '../providers/follow_ups_provider.dart';

class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(followUpsProvider.notifier).selectTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📞 Calling $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📞 Calling $phoneNumber...')),
        );
      }
    }
  }

  void _markAsCompleted(FollowUpModel item) async {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(followUpsProvider.notifier);
    final success = await notifier.markAsCompleted(item);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Follow-up for "${item.restaurantName}" marked as Completed!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _rescheduleFollowUp(FollowUpModel item) async {
    final initialDate = item.scheduledTime.isAfter(DateTime.now())
        ? item.scheduledTime
        : DateTime.now().add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(item.scheduledTime),
      );

      if (pickedTime != null && mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final notifier = ref.read(followUpsProvider.notifier);
        final success = await notifier.rescheduleFollowUp(item, newDateTime);

        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗓️ Rescheduled "${item.restaurantName}" to ${DateFormat('dd MMM yyyy, hh:mm a').format(newDateTime)}'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAddFollowUpDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedType = 'POS Upgrade & Quotation';
    String selectedPriority = 'High';
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 3));

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Schedule New Follow-Up',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant / Outlet Name *',
                        hintText: 'e.g. The Royal Spice',
                        prefixIcon: Icon(Icons.restaurant_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: contactCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person *',
                              hintText: 'e.g. Rajesh Shah',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '98250 12345',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Area / Location *',
                        hintText: 'e.g. Navrangpura, Ahmedabad',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Follow-Up Purpose',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'POS Upgrade & Quotation', child: Text('POS Upgrade & Quotation')),
                        DropdownMenuItem(value: 'Pricing Negotiation', child: Text('Pricing Negotiation')),
                        DropdownMenuItem(value: 'QR Menu Demo Follow-up', child: Text('QR Menu Demo Follow-up')),
                        DropdownMenuItem(value: 'Contract Signing', child: Text('Contract Signing')),
                        DropdownMenuItem(value: 'Payment Collection', child: Text('Payment Collection')),
                        DropdownMenuItem(value: 'Hardware Review', child: Text('Hardware Review')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              prefixIcon: Icon(Icons.flag_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'High', child: Text('High Priority', style: TextStyle(color: Colors.red))),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium Priority', style: TextStyle(color: Colors.orange))),
                              DropdownMenuItem(value: 'Low', child: Text('Low Priority', style: TextStyle(color: Colors.green))),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedPriority = val);
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (pickedDate != null && context.mounted) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                                );
                                if (pickedTime != null) {
                                  setModalState(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Schedule Time',
                                prefixIcon: Icon(Icons.calendar_month_rounded),
                              ),
                              child: Text(
                                DateFormat('dd MMM, hh:mm a').format(selectedDate),
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Discussion Notes / Objective',
                        hintText: 'Add specific details discussed with the client...',
                        prefixIcon: Icon(Icons.note_alt_rounded),
                      ),
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
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter restaurant name')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          final notifier = ref.read(followUpsProvider.notifier);
                          final success = await notifier.createFollowUp(
                            restaurantName: nameCtrl.text.trim(),
                            contactPerson: contactCtrl.text.trim().isEmpty ? 'Owner' : contactCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? '+91 98765 00000' : phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim().isEmpty ? 'Ahmedabad, Gujarat' : addressCtrl.text.trim(),
                            type: selectedType,
                            priority: selectedPriority,
                            scheduledTime: selectedDate,
                            notes: notesCtrl.text.trim(),
                          );

                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('✅ New follow-up scheduled and saved to database!'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text('Save & Schedule Follow-Up', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(followUpsProvider);
    final notifier = ref.read(followUpsProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Follow-Up Center',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Live CRM Database',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              notifier.loadFollowUps();
            },
          ),
          SizedBox(width: 4.w),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Today (${state.todayCount})'),
            Tab(text: 'Upcoming (${state.upcomingCount})'),
            Tab(text: 'Overdue (${state.overdueCount})'),
            Tab(text: 'Completed (${state.completedCount})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Follow-Up', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
        onPressed: _showAddFollowUpDialog,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearchQuery(val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13.5.sp),
              decoration: InputDecoration(
                hintText: 'Search restaurants, owners or areas...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
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
              ),
            ),
          ),

          // Main View: Loading / Error / Tab Views
          Expanded(
            child: state.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 14.h),
                        Text(
                          'Loading follow-ups from database...',
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : state.errorMessage != null && state.allFollowUps.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 48.sp, color: Colors.redAccent),
                              SizedBox(height: 12.h),
                              Text(
                                'Unable to Load Follow-Ups',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                ),
                                onPressed: () => notifier.loadFollowUps(),
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(state.getItemsForStatus(FollowUpStatus.today), isDark, 'today', notifier),
                          _buildList(state.getItemsForStatus(FollowUpStatus.upcoming), isDark, 'upcoming', notifier),
                          _buildList(state.getItemsForStatus(FollowUpStatus.overdue), isDark, 'overdue', notifier),
                          _buildList(state.getItemsForStatus(FollowUpStatus.completed), isDark, 'completed', notifier),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FollowUpModel> items, bool isDark, String tabKey, FollowUpsNotifier notifier) {
    if (items.isEmpty) {
      String emptyMessage = 'No follow-ups scheduled for today';
      if (tabKey == 'upcoming') emptyMessage = 'No upcoming follow-ups found';
      if (tabKey == 'overdue') emptyMessage = 'Great job! No overdue follow-ups';
      if (tabKey == 'completed') emptyMessage = 'No completed follow-ups recorded yet';

      return RefreshIndicator(
        onRefresh: () => notifier.loadFollowUps(showLoading: false),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            SizedBox(height: 100.h),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tabKey == 'overdue' ? Icons.check_circle_outline_rounded : Icons.event_note_rounded,
                    size: 54.sp,
                    color: tabKey == 'overdue' ? const Color(0xFF10B981) : Colors.grey[300],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pull to refresh or schedule a new follow-up below',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11.5.sp),
                  ),
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    onPressed: _showAddFollowUpDialog,
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Schedule Follow-Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadFollowUps(showLoading: false),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 80.h),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isCompleted = item.status.toUpperCase() == 'COMPLETED';

          Color priorityColor = const Color(0xFF10B981);
          if (item.priority == 'High') priorityColor = const Color(0xFFEF4444);
          if (item.priority == 'Medium') priorityColor = const Color(0xFFF59E0B);

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
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
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
                    Expanded(
                      child: Text(
                        item.restaurantName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey.withValues(alpha: 0.15) : priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : item.priority,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey[600] : priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${item.contactPerson} • ${item.followUpType}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 13.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        item.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                if (item.notes.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '📝 ${item.notes}',
                      style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(item.scheduledTime),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted)
                      Row(
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFF10B981),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _makePhoneCall(item.phone);
                            },
                          ),
                          SizedBox(width: 6.w),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFF3B82F6),
                            ),
                            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                            onPressed: () => _rescheduleFollowUp(item),
                          ),
                          SizedBox(width: 6.w),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            onPressed: () => _markAsCompleted(item),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text('Done', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }
}
