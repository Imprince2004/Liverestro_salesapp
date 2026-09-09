import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';

/// Restaurant Domain Reusable UI Widgets.

class RestaurantHeaderWidget extends StatelessWidget {
  final String name;
  final String category;
  final String rating;
  final String address;

  const RestaurantHeaderWidget({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8.r)),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4.w),
                    Text(rating, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(category, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
              SizedBox(width: 4.w),
              Expanded(child: Text(address, style: TextStyle(color: Colors.white70, fontSize: 12.sp), maxLines: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class ContactCardWidget extends StatelessWidget {
  final String ownerName;
  final String phone;
  final VoidCallback onCallTap;

  const ContactCardWidget({
    super.key,
    required this.ownerName,
    required this.phone,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(ownerName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        subtitle: Text(phone, style: TextStyle(fontSize: 12.sp)),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.success),
          onPressed: onCallTap,
        ),
      ),
    );
  }
}
