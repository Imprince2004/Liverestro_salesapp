import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';

enum StatusType { active, pending, closed, error, warning, inactive }

/// Status chip (e.g. Active, Pending, Closed, Syncing).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.active,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (type) {
      case StatusType.active:
        bg = AppColors.successBg;
        text = AppColors.success;
        break;
      case StatusType.pending:
        bg = AppColors.warningBg;
        text = AppColors.warning;
        break;
      case StatusType.closed:
      case StatusType.error:
        bg = AppColors.errorBg;
        text = AppColors.error;
        break;
      case StatusType.warning:
        bg = AppColors.warningBg;
        text = AppColors.warning;
        break;
      case StatusType.inactive:
        bg = AppColors.borderLight;
        text = AppColors.textSecondaryLight;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
