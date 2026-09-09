import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/profile/data/models/notification_model.dart';
import '../../features/profile/presentation/providers/notification_providers.dart';
import '../../features/visits/presentation/screens/start_visit_screen.dart';

class InAppNotificationBannerListener extends ConsumerStatefulWidget {
  final Widget child;
  const InAppNotificationBannerListener({super.key, required this.child});

  @override
  ConsumerState<InAppNotificationBannerListener> createState() => _InAppNotificationBannerListenerState();
}

class _InAppNotificationBannerListenerState extends ConsumerState<InAppNotificationBannerListener> {
  StreamSubscription<NotificationModel>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = realtimeNotificationStreamController.stream.listen((notif) {
      if (mounted) {
        _showTopDrawerNotification(notif);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showTopDrawerNotification(NotificationModel notif) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: notif.type.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(notif.type.icon, color: notif.type.color, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.senderName,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            ref.read(notificationListProvider.notifier).markAsRead(notif.id);
            if (notif.restaurantName != null && notif.restaurantName!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartVisitScreen(
                    restaurantName: notif.restaurantName!,
                    address: notif.location ?? 'Assigned Beat Location',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
