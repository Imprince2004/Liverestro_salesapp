import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';
import '../../extensions/context_ext.dart';

/// Enterprise Cards Component Library.

class RestaurantCardWidget extends StatelessWidget {
  final String name;
  final String category;
  final String address;
  final String distance;
  final VoidCallback? onTap;
  final VoidCallback? onCheckinTap;

  const RestaurantCardWidget({
    super.key,
    required this.name,
    required this.category,
    required this.address,
    required this.distance,
    this.onTap,
    this.onCheckinTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8.r)),
                    child: Text(distance, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(category, style: TextStyle(fontSize: 12.sp, color: AppColors.accent)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Expanded(child: Text(address, style: TextStyle(fontSize: 12.sp, color: Colors.grey), maxLines: 1)),
                ],
              ),
              if (onCheckinTap != null) ...[
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onCheckinTap,
                    icon: const Icon(Icons.pin_drop, size: 16),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(110.w, 36.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LeadCardWidget extends StatelessWidget {
  final String leadName;
  final String ownerName;
  final String status;
  final String value;

  const LeadCardWidget({
    super.key,
    required this.leadName,
    required this.ownerName,
    required this.status,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leadName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.success)),
            ],
          ),
          SizedBox(height: 4.h),
          Text('Owner: $ownerName', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8.r)),
            child: Text(status, style: TextStyle(fontSize: 11.sp, color: AppColors.warning, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class StatisticCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const StatisticCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
              Icon(icon, color: color, size: 22.sp),
            ],
          ),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4.h),
          Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
