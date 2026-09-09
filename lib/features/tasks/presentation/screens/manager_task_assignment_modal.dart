import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../leads/data/models/lead_model.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../../targets/data/models/implementation_model.dart';
import '../../data/models/assignable_user_model.dart';
import '../providers/task_providers.dart';

class ManagerTaskAssignmentModal extends ConsumerStatefulWidget {
  final VoidCallback? onTaskCreated;
  final String? prefillRestaurantName;
  final String? prefillTaskType;
  final String? prefillLeadId;
  final String? prefillLocation;

  const ManagerTaskAssignmentModal({
    super.key,
    this.onTaskCreated,
    this.prefillRestaurantName,
    this.prefillTaskType,
    this.prefillLeadId,
    this.prefillLocation,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onTaskCreated,
    String? prefillRestaurantName,
    String? prefillTaskType,
    String? prefillLeadId,
    String? prefillLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManagerTaskAssignmentModal(
        onTaskCreated: onTaskCreated,
        prefillRestaurantName: prefillRestaurantName,
        prefillTaskType: prefillTaskType,
        prefillLeadId: prefillLeadId,
        prefillLocation: prefillLocation,
      ),
    );
  }

  @override
  ConsumerState<ManagerTaskAssignmentModal> createState() => _ManagerTaskAssignmentModalState();
}

class _ManagerTaskAssignmentModalState extends ConsumerState<ManagerTaskAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _locationController = TextEditingController();

  LeadModel? _selectedLead;
  ImplementationModel? _leadImplementation;
  int _selectedTabIndex = 0; // 0 = Sales Manager, 1 = Sales Executive

  String _selectedTaskType = 'DEMO';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  // Selected Assignee IDs
  final Set<String> _selectedManagerIds = {};
  String? _selectedExecutiveId;

  @override
  void initState() {
    super.initState();

    if (widget.prefillRestaurantName != null) {
      _restaurantController.text = widget.prefillRestaurantName!;
    }
    if (widget.prefillLocation != null) {
      _locationController.text = widget.prefillLocation!;
    }
    if (widget.prefillTaskType != null) {
      _selectedTaskType = widget.prefillTaskType!;
    }

    // Fetch implementation progress for prefilled restaurant
    if (widget.prefillLeadId != null || widget.prefillRestaurantName != null) {
      _fetchLeadImplementationStatus(widget.prefillLeadId ?? '', widget.prefillRestaurantName ?? '');
    }

    // Refresh database users and leads on modal open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignableUsersProvider.notifier).fetchAssignableUsers();
      ref.read(leadListProvider.notifier).loadLeads();
    });
  }

  Future<void> _fetchLeadImplementationStatus(String leadId, String restaurantName) async {
    if (leadId.trim().isEmpty && restaurantName.trim().isEmpty) return;

    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.get('/api/implementations/all');
      if (res.statusCode == 200 && res.data != null) {
        final List<dynamic> list = res.data is List ? res.data : (res.data['data'] ?? []);
        final matches = list.map((e) => ImplementationModel.fromJson(e as Map<String, dynamic>)).toList();
        
        final cleanLeadId = leadId.trim();
        final cleanName = restaurantName.toLowerCase().trim();

        final found = matches.firstWhere(
          (i) => (cleanLeadId.isNotEmpty && i.leadId == cleanLeadId) ||
                 (cleanName.isNotEmpty && i.restaurantName.toLowerCase().trim() == cleanName),
          orElse: () => ImplementationModel(
            id: '',
            restaurantName: restaurantName,
            demoStatus: 'PENDING',
            setupStatus: 'NOT_STARTED',
            trainingStatus: 'NOT_STARTED',
          ),
        );

        if (mounted) {
          setState(() {
            _leadImplementation = found;
            _adjustSelectedTaskTypeBasedOnImpl(found);
          });
        }
      }
    } catch (_) {}
  }

  void _adjustSelectedTaskTypeBasedOnImpl(ImplementationModel impl) {
    final demoDone = impl.demoStatus.toUpperCase() == 'COMPLETED';
    final setupDone = impl.setupStatus.toUpperCase() == 'COMPLETED';

    if (!demoDone) {
      _selectedTaskType = 'DEMO';
    } else if (!setupDone) {
      _selectedTaskType = 'SETUP';
    } else {
      _selectedTaskType = 'TRAINING';
    }
  }

  List<DropdownMenuItem<String>> _getAvailableTaskTypeItems() {
    final items = <DropdownMenuItem<String>>[];
    final impl = _leadImplementation;

    final demoDone = impl?.demoStatus.toUpperCase() == 'COMPLETED';
    final setupDone = impl?.setupStatus.toUpperCase() == 'COMPLETED';
    final trainingDone = impl?.trainingStatus.toUpperCase() == 'COMPLETED';

    // Strict Sequential Implementation Tasks from Database
    if (!demoDone) {
      // Demo still pending -> ONLY show Demo
      items.add(const DropdownMenuItem(value: 'DEMO', child: Text('✅ Software Demo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
    } else if (!setupDone) {
      // Demo completed, Setup pending -> ONLY show Setup
      items.add(const DropdownMenuItem(value: 'SETUP', child: Text('✅ Software Setup / Installation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
    } else if (!trainingDone) {
      // Setup completed, Training pending -> ONLY show Staff Training
      items.add(const DropdownMenuItem(value: 'TRAINING', child: Text('✅ Staff Training & Live Launch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
    } else {
      // All 3 completed
      items.add(const DropdownMenuItem(value: 'TRAINING', child: Text('✅ Staff Training (Refresher)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
    }

    // General Sales Activities
    items.addAll(const [
      DropdownMenuItem(value: 'RESTAURANT_VISIT', child: Text('Visit & Pitch', style: TextStyle(fontSize: 12))),
      DropdownMenuItem(value: 'KYC_DOCUMENTATION', child: Text('KYC Collect', style: TextStyle(fontSize: 12))),
      DropdownMenuItem(value: 'FOLLOW_UP', child: Text('Follow-up', style: TextStyle(fontSize: 12))),
    ]);

    return items;
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _openLeadPicker(List<LeadModel> leads, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LeadPickerSheet(
        leads: leads,
        isDark: isDark,
        onSelected: (lead) {
          setState(() {
            _selectedLead = lead;
            _restaurantController.text = '${lead.restaurantName} — ${lead.id}';
            final locParts = [
              if (lead.area.isNotEmpty) lead.area,
              if (lead.city.isNotEmpty) lead.city,
            ];
            _locationController.text = locParts.isNotEmpty ? locParts.join(', ') : lead.address;
          });
          _fetchLeadImplementationStatus(lead.id, lead.restaurantName);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _handleCreateTask() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authUser = ref.read(authNotifierProvider).user;
    final isAdmin = authUser?.role.toUpperCase().contains('ADMIN') == true;

    final List<String> targetAssigneeIds = [];
    if (isAdmin && _selectedTabIndex == 0) {
      targetAssigneeIds.addAll(_selectedManagerIds);
    } else if (_selectedExecutiveId != null) {
      targetAssigneeIds.add(_selectedExecutiveId!);
    }

    if (targetAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin && _selectedTabIndex == 0
              ? 'Please select at least one Sales Manager'
              : 'Please select a Sales Executive to assign'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final restaurantName = _selectedLead != null
        ? _selectedLead!.restaurantName
        : _restaurantController.text.split(' — ').first.trim();

    if (restaurantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a restaurant or lead from the database.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final dueDateStr = _selectedDueDate.toIso8601String().split('T')[0];

      // Schedule conflict check for single selected executive
      if (targetAssigneeIds.length == 1) {
        final conflictCheck = await ref.read(taskListProvider.notifier).checkConflict(
              userId: targetAssigneeIds.first,
              date: dueDateStr,
              restaurantName: restaurantName,
            );

        if (conflictCheck.hasConflict && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8.w),
                  const Text('Schedule Conflict'),
                ],
              ),
              content: Text(
                conflictCheck.conflictMessage ??
                    'The selected user already has an active assignment on this date. Do you want to proceed anyway?',
                style: TextStyle(fontSize: 13.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Proceed & Assign', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() => _isSubmitting = false);
            return;
          }
        }
      }

      final typeLabels = {
        'DEMO': 'Software Demo',
        'SETUP': 'Software Setup',
        'SOFTWARE_SETUP': 'Software Setup',
        'TRAINING': 'Staff Training',
        'RESTAURANT_VISIT': 'Visit & Pitch',
        'KYC_DOCUMENTATION': 'KYC Collect',
        'FOLLOW_UP': 'Follow-up',
      };
      final activityLabel = typeLabels[_selectedTaskType] ?? _selectedTaskType;
      final computedTitle = '$activityLabel at $restaurantName';

      final success = await ref.read(taskListProvider.notifier).createMultiAssigneeTask(
            assignedToIds: targetAssigneeIds,
            title: computedTitle,
            description: '',
            taskType: _selectedTaskType,
            priority: 'HIGH',
            restaurantName: restaurantName,
            location: _locationController.text.trim(),
            dueDate: dueDateStr,
            notes: _selectedLead?.id ?? widget.prefillLeadId ?? '',
          );

      if (!mounted) return;

      // Automatically refresh Assign Team Activity data & tasks
      ref.read(assignableUsersProvider.notifier).fetchAssignableUsers();
      ref.read(taskListProvider.notifier).fetchTasks();
      ref.read(leadListProvider.notifier).loadLeads();

      Navigator.pop(context);
      widget.onTaskCreated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  success
                      ? '✓ Task created and assigned successfully!'
                      : '✓ Task created and synced successfully',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = ref.watch(authNotifierProvider).user;
    final isAdmin = authUser?.role.toUpperCase().contains('ADMIN') == true;
    final assignableState = ref.watch(assignableUsersProvider);
    final leadsAsync = ref.watch(leadListProvider);
    final availableLeads = leadsAsync.value ?? [];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Modal Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.assignment_add, color: const Color(0xFFF97316), size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Admin Task Assignment' : 'Assign Team Activity',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isAdmin
                              ? 'Assign tasks to your team members'
                              : 'Dispatch to dedicated Sales Executives',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.grey[700]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // 1. Role Selection Tabs (Exact 50:50 Ratio, Same Height)
              if (isAdmin) ...[
                _buildRoleTabs(isDark),
                SizedBox(height: 12.h),
                if (_selectedTabIndex == 0) ...[
                  _buildSalesManagersList(assignableState.salesManagers, isDark),
                ] else ...[
                  _buildSalesExecutivesList(assignableState.salesExecutives, isDark),
                ],
              ] else ...[
                Text(
                  'Select Dedicated Sales Executive',
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                _buildSalesExecutivesList(assignableState.salesExecutives, isDark),
              ],

              SizedBox(height: 16.h),

              // 2. Restaurant / Lead Selection (Database Dropdown)
              Text(
                'Restaurant / Lead *',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 6.h),
              InkWell(
                onTap: () => _openLeadPicker(availableLeads, isDark),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF714B67)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _restaurantController.text.isNotEmpty
                              ? _restaurantController.text
                              : '🔍 Search restaurant or Lead ID',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: _restaurantController.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: _restaurantController.text.isNotEmpty
                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 3. Location (Auto-fetched & Read-Only)
              Text(
                'Location (Auto-fetched)',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                decoration: InputDecoration(
                  hintText: '📍 Automatically fetched location',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF714B67), size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 4. Activity Type & Completion Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Type *',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedTaskType,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: _getAvailableTaskTypeItems(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedTaskType = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion Date *',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() => _selectedDueDate = picked);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF714B67)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              // 5. Fixed "Assign a Task" Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isSubmitting ? 'Assigning Task...' : 'Assign a Task',
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _handleCreateTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Custom 50:50 Ratio Role Selector Tabs ---
  Widget _buildRoleTabs(bool isDark) {
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          // Tab 1: Sales Manager
          Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedTabIndex != 0) {
                  setState(() => _selectedTabIndex = 0);
                }
              },
              borderRadius: BorderRadius.circular(9.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? const Color(0xFFF97316) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.r),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Sales Manager',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          // Tab 2: Sales Executive
          Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedTabIndex != 1) {
                  setState(() => _selectedTabIndex = 1);
                }
              },
              borderRadius: BorderRadius.circular(9.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? const Color(0xFFF97316) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.r),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Sales Executive',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Sales Managers Selection Cards ---
  Widget _buildSalesManagersList(List<AssignableUserModel> managers, bool isDark) {
    if (managers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'No Sales Managers registered in database.',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        ),
      );
    }

    return Column(
      children: managers.map((m) {
        final isSelected = _selectedManagerIds.contains(m.id);
        return _buildPersonSelectionCard(
          person: m,
          isSelected: isSelected,
          isDark: isDark,
          isMultiSelect: true,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedManagerIds.remove(m.id);
              } else {
                _selectedManagerIds.add(m.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // --- 3. Sales Executives Selection Cards ---
  Widget _buildSalesExecutivesList(List<AssignableUserModel> executives, bool isDark) {
    if (executives.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'No Sales Executives assigned to you found in database.',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        ),
      );
    }

    if (_selectedExecutiveId == null && executives.isNotEmpty) {
      _selectedExecutiveId = executives.first.id;
    }

    return Column(
      children: executives.map((e) {
        final isSelected = _selectedExecutiveId == e.id;
        return _buildPersonSelectionCard(
          person: e,
          isSelected: isSelected,
          isDark: isDark,
          isMultiSelect: false,
          onTap: () => setState(() => _selectedExecutiveId = e.id),
        );
      }).toList(),
    );
  }

  // --- 4. Individual Clean Person Selection Card ---
  Widget _buildPersonSelectionCard({
    required AssignableUserModel person,
    required bool isSelected,
    required bool isDark,
    required bool isMultiSelect,
    required VoidCallback onTap,
  }) {
    final avatarLetter = person.name.trim().isNotEmpty ? person.name.trim()[0].toUpperCase() : 'U';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF97316).withValues(alpha: isDark ? 0.15 : 0.06)
              : (isDark ? AppColors.surfaceVariantDark : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF97316)
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with clean initial
            CircleAvatar(
              radius: 18.r,
              backgroundColor: isSelected ? const Color(0xFFF97316) : const Color(0xFF714B67),
              child: Text(
                avatarLetter,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Person Details (Full Name, Designation • Employee ID, & Status)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name (Prominent on single line)
                  Text(
                    person.name,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),

                  // Designation • Employee ID
                  Text(
                    '${person.designation} • ${person.employeeId}',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),

                  // Assignment / Availability Status Badge
                  _buildAssignmentStatusBadge(person, isDark),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // Selection Indicator / Checkbox
            if (isMultiSelect)
              Checkbox(
                value: isSelected,
                activeColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                onChanged: (_) => onTap(),
              )
            else
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? const Color(0xFFF97316) : Colors.grey.withValues(alpha: 0.5),
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }

  // --- 5. Compact Assignment Status Badge ---
  Widget _buildAssignmentStatusBadge(AssignableUserModel user, bool isDark) {
    final isAvailable = user.isAvailable;
    final badgeBg = isAvailable
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : const Color(0xFFF59E0B).withValues(alpha: 0.14);
    final badgeBorder = isAvailable
        ? const Color(0xFF10B981).withValues(alpha: 0.3)
        : const Color(0xFFF59E0B).withValues(alpha: 0.35);
    final dotColor = isAvailable ? const Color(0xFF10B981) : const Color(0xFFD97706);
    final textColor = isAvailable
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E));

    String statusText;
    if (isAvailable) {
      statusText = 'Available';
    } else {
      final act = user.currentActivity ?? '';
      statusText = act.isNotEmpty ? 'Assigned · $act' : (user.badgeText.contains(':') ? user.badgeText.replaceAll(':', ' ·') : 'Assigned');
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: badgeBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5.w,
            height: 5.5.w,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable Database Lead / Restaurant Picker Bottom Sheet
class _LeadPickerSheet extends StatefulWidget {
  final List<LeadModel> leads;
  final bool isDark;
  final ValueChanged<LeadModel> onSelected;

  const _LeadPickerSheet({
    required this.leads,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<_LeadPickerSheet> createState() => _LeadPickerSheetState();
}

class _LeadPickerSheetState extends State<_LeadPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final filteredLeads = widget.leads.where((l) {
      if (query.isEmpty) return true;
      return l.restaurantName.toLowerCase().contains(query) ||
          l.id.toLowerCase().contains(query) ||
          l.area.toLowerCase().contains(query) ||
          l.city.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Restaurant / Lead',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '🔍 Search restaurant name or Lead ID...',
              hintStyle: TextStyle(fontSize: 12.5.sp, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF714B67)),
              filled: true,
              fillColor: widget.isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: filteredLeads.isEmpty
                ? Center(
                    child: Text(
                      'No matching restaurants found in database.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredLeads.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: widget.isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (ctx, index) {
                      final lead = filteredLeads[index];
                      final locParts = [
                        if (lead.area.isNotEmpty) lead.area,
                        if (lead.city.isNotEmpty) lead.city,
                      ];
                      final locationStr = locParts.isNotEmpty ? locParts.join(', ') : lead.address;

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF714B67).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF714B67), size: 20),
                        ),
                        title: Text(
                          '${lead.restaurantName} — ${lead.id}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: locationStr.isNotEmpty
                            ? Text(
                                '📍 $locationStr',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: widget.isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                ),
                              )
                            : null,
                        onTap: () => widget.onSelected(lead),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

