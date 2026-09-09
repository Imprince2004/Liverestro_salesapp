import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../routes/route_names.dart';
import '../../../visits/presentation/screens/start_visit_screen.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationHubScreen extends ConsumerStatefulWidget {
  const NotificationHubScreen({super.key});

  @override
  ConsumerState<NotificationHubScreen> createState() => _NotificationHubScreenState();
}

class _NotificationHubScreenState extends ConsumerState<NotificationHubScreen> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> list) {
    if (_selectedCategoryIndex == 1) {
      // Unread
      return list.where((n) => !n.isRead).toList();
    } else if (_selectedCategoryIndex == 2) {
      // Messages & Manager Tasks
      return list
          .where((n) => n.type == NotificationType.message || n.type == NotificationType.taskAssigned)
          .toList();
    } else if (_selectedCategoryIndex == 3) {
      // Visits & Leads
      return list
          .where((n) => n.type == NotificationType.visitReminder || n.type == NotificationType.leadAssigned)
          .toList();
    } else if (_selectedCategoryIndex == 4) {
      // Incentives & System
      return list
          .where((n) => n.type == NotificationType.incentive || n.type == NotificationType.system)
          .toList();
    }
    return list;
  }

  void _handleNotificationTap(NotificationModel item) {
    HapticFeedback.lightImpact();
    ref.read(notificationListProvider.notifier).markAsRead(item.id);

    // If there is an associated visit or restaurant
    if (item.restaurantName != null && item.restaurantName!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StartVisitScreen(
            restaurantName: item.restaurantName!,
            address: item.location ?? 'Assigned Beat Location',
          ),
        ),
      );
      return;
    }

    // Route to action route if specified
    if (item.actionRoute != null && item.actionRoute!.isNotEmpty) {
      context.push(item.actionRoute!);
      return;
    }

    if (item.type == NotificationType.leadAssigned) {
      context.push(RouteNames.leadList);
    } else if (item.type == NotificationType.visitReminder) {
      context.push(RouteNames.visitManagement);
    } else if (item.type == NotificationType.incentive) {
      context.push(RouteNames.leaderboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationListProvider);
    final allNotifications = notificationsAsync.value ?? [];
    final filtered = _filterNotifications(allNotifications);
    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    final categories = [
      'All (${allNotifications.length})',
      'Unread ($unreadCount)',
      'Messages & Tasks',
      'Visits & Leads',
      'Incentives',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notification Center',
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
            tooltip: 'Sync Notifications',
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(notificationListProvider.notifier).fetchNotifications();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
            onSelected: (val) {
              if (val == 'read') {
                HapticFeedback.mediumImpact();
                ref.read(notificationListProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ All notifications marked as read!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'read', child: Text('Mark all as read')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: unreadCount > 0
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(notificationListProvider.notifier).markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  'Mark All $unreadCount Unread as Read',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5.sp),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationListProvider.notifier).fetchNotifications(),
        color: AppColors.primary,
        child: Column(
          children: [
            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: List.generate(categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategoryIndex = index);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Notification List Feed
            Expanded(
              child: notificationsAsync.isLoading && allNotifications.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 64.sp, color: Colors.grey[400]),
                                SizedBox(height: 14.h),
                                Text(
                                  _selectedCategoryIndex == 1
                                      ? 'No Unread Notifications'
                                      : 'No Notifications Found',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'New messages from your manager and system alerts will arrive here in real time.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildNotificationCard(item, isDark, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item, bool isDark, int index) {
    return InkWell(
      onTap: () => _handleNotificationTap(item),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: !item.isRead
                ? AppColors.primary.withValues(alpha: 0.35)
                : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
            width: !item.isRead ? 1.5 : 1,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: item.type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(item.type.icon, color: item.type.color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.senderName.isNotEmpty && item.senderName != 'LiveRestro'
                                  ? '${item.senderName}: ${item.title}'
                                  : item.title,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              margin: EdgeInsets.only(left: 6.w),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 11.sp, color: Colors.grey[500]),
                          SizedBox(width: 4.w),
                          Text(
                            item.timeAgo,
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[500]),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: item.type.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              item.type.categoryLabel,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: item.type.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.restaurantName != null && item.restaurantName!.isNotEmpty) ...[
              SizedBox(height: 10.h),
              const Divider(height: 1),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  onPressed: () => _handleNotificationTap(item),
                  icon: Icon(Icons.rocket_launch_rounded, size: 14.sp),
                  label: Text(
                    'Start Visit at ${item.restaurantName}',
                    style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
  }
}
