import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/colors.dart';

/// Maps & Location UI Components.

class MiniMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const MiniMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 180.h,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('restaurant'),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: title),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}

class DistanceCardWidget extends StatelessWidget {
  final String distanceText;
  final String estimatedTime;

  const DistanceCardWidget({
    super.key,
    required this.distanceText,
    required this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(distanceText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.primary)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(estimatedTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
