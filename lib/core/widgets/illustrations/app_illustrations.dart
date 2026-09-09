import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';

/// Enterprise Placeholder Illustration Components.

class EmptyLeadsIllustration extends StatelessWidget {
  const EmptyLeadsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.leaderboard_outlined, size: 80.sp, color: AppColors.primary.withValues(alpha: 0.3)),
        SizedBox(height: 16.h),
        Text('No Leads Assigned', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Text('You currently have no sales leads assigned in your route.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
      ],
    );
  }
}

class GpsDisabledIllustration extends StatelessWidget {
  final VoidCallback onEnableGps;

  const GpsDisabledIllustration({super.key, required this.onEnableGps});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off_rounded, size: 80.sp, color: AppColors.warning),
        SizedBox(height: 16.h),
        Text('Location Required', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Text('Please enable GPS location to log restaurant visits.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
        SizedBox(height: 20.h),
        ElevatedButton.icon(
          onPressed: onEnableGps,
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Enable Location Services'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
