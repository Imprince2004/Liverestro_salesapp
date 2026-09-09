import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../extensions/context_ext.dart';
import '../theme/app_radius.dart';

/// Draggable Material 3 Bottom Sheet Base container.
class BottomSheetBase extends StatelessWidget {
  final Widget child;
  final String? title;

  const BottomSheetBase({super.key, required this.child, this.title});

  static Future<T?> show<T>(BuildContext context, {required Widget child, String? title}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetBase(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.colors.surface : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        top: 12.h,
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: AppRadius.radiusFull,
            ),
          ),
          if (title != null) ...[
            SizedBox(height: 16.h),
            Text(
              title!,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
          SizedBox(height: 16.h),
          Flexible(child: child),
        ],
      ),
    );
  }
}
