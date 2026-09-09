import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../visits/presentation/screens/start_visit_screen.dart';
import '../../data/models/task_model.dart';
import '../providers/task_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import 'manager_task_assignment_modal.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TaskModel> _getFilteredTasks(List<TaskModel> allTasks, int tabIndex) {
    var list = allTasks;
    if (tabIndex == 1) list = list.where((t) => t.status.toUpperCase() == 'PENDING').toList();
    if (tabIndex == 2) list = list.where((t) => t.status.toUpperCase() == 'IN_PROGRESS' || t.status.toUpperCase() == 'ACTIVE').toList();
    if (tabIndex == 3) list = list.where((t) => t.status.toUpperCase() == 'COMPLETED').toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.taskType.toLowerCase().contains(q) ||
          t.restaurantName.toLowerCase().contains(q) ||
          t.managerName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    HapticFeedback.lightImpact();
    final newStatus = task.status.toUpperCase() == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
    final success = await ref.read(taskListProvider.notifier).updateStatus(task.id, newStatus);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'COMPLETED' ? '✓ Task marked as Completed!' : 'Task status updated to Pending.'),
          backgroundColor: newStatus == 'COMPLETED' ? const Color(0xFF10B981) : AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value ?? [];
    final authState = ref.watch(authNotifierProvider);
    final isExecutive = authState.user?.role == 'SALES_EXECUTIVE';

    final pendingCount = tasks.where((t) => t.status.toUpperCase() == 'PENDING').length;
    final inProgressCount = tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS' || t.status.toUpperCase() == 'ACTIVE').length;
    final completedCount = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tasks & Action Items',
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(taskListProvider.notifier).fetchTasks(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'All (${tasks.length})'),
            Tab(text: 'Pending ($pendingCount)'),
            Tab(text: 'Active ($inProgressCount)'),
            Tab(text: 'Done ($completedCount)'),
          ],
        ),
      ),
      floatingActionButton: isExecutive
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: Text('Assign Task', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
              onPressed: () => ManagerTaskAssignmentModal.show(context, onTaskCreated: () {
                ref.read(taskListProvider.notifier).fetchTasks();
              }),
            ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13.5.sp),
              decoration: InputDecoration(
                hintText: 'Search tasks, restaurants, or managers...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                ),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(_getFilteredTasks(tasks, 0), isDark),
                _buildTaskList(_getFilteredTasks(tasks, 1), isDark),
                _buildTaskList(_getFilteredTasks(tasks, 2), isDark),
                _buildTaskList(_getFilteredTasks(tasks, 3), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> taskList, bool isDark) {
    if (taskList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 50.sp, color: Colors.grey[300]),
            SizedBox(height: 12.h),
            Text(
              'No tasks in this category',
              style: TextStyle(color: Colors.grey[500], fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 80.h),
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];
        final isDone = task.status.toUpperCase() == 'COMPLETED';

        Color priorityColor = const Color(0xFF10B981);
        if (task.priority.toUpperCase() == 'HIGH' || task.priority.toUpperCase() == 'URGENT') {
          priorityColor = const Color(0xFFEF4444);
        } else if (task.priority.toUpperCase() == 'MEDIUM') {
          priorityColor = const Color(0xFFF59E0B);
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
            ),
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
              // Top Bar: Category & Priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      task.taskType.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${task.priority} Priority',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Title & Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: isDone,
                      onChanged: (_) => _toggleTaskStatus(task),
                      activeColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? Colors.grey
                                : (isDark ? Colors.white : AppColors.textPrimaryLight),
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Restaurant & Manager Pills
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (task.restaurantName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'Restaurant: ${task.restaurantName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
                    Row(
                      children: [
                        Icon(Icons.supervisor_account_rounded, size: 14.sp, color: const Color(0xFF10B981)),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Assigned by: ${task.managerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Text(
                          '📅 Due: ${task.dueDate}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (task.restaurantName.isNotEmpty && !isDone) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StartVisitScreen(
                            restaurantName: task.restaurantName,
                            address: task.location.isNotEmpty ? task.location : 'Assigned Beat Location',
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.rocket_launch_rounded, size: 14.sp),
                    label: Text(
                      'Start Visit at ${task.restaurantName}',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}
