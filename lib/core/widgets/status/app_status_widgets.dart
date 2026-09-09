import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';

/// Enterprise Badges, Labels & Status Components.

class PriorityLabelWidget extends StatelessWidget {
  final String priority;

  const PriorityLabelWidget({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
      case 'hot':
        color = AppColors.error;
        break;
      case 'medium':
      case 'warm':
        color = AppColors.warning;
        break;
      case 'low':
      case 'cold':
      default:
        color = AppColors.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class AttendanceLabelWidget extends StatelessWidget {
  final bool isPresent;

  const AttendanceLabelWidget({super.key, required this.isPresent});

  @override
  Widget build(BuildContext context) {
    final color = isPresent ? AppColors.success : AppColors.error;
    final text = isPresent ? 'PRESENT' : 'ABSENT';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3.r, backgroundColor: color),
          SizedBox(width: 6.w),
          Text(text, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
