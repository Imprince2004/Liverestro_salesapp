import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';

/// Enterprise Skeleton & Shimmer Loading Component Library.

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width.w,
        height: height.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
      ),
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  final int count;

  const SkeletonListLoader({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 180, height: 14),
                SizedBox(height: 6.h),
                const ShimmerBox(width: 120, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PageLoaderWidget extends StatelessWidget {
  final String? message;

  const PageLoaderWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(message!, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
