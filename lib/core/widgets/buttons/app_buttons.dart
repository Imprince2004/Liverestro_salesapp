import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_tokens.dart';

/// Production SaaS Button Component Library.

class PrimaryButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;

  const PrimaryButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading || onPressed == null;
    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLg,
          gradient: disabled ? null : AppColors.primaryGradient,
          color: disabled ? AppColors.borderLight : null,
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppTokens.iconSm, color: Colors.white),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      text,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class DangerButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        ),
        child: isLoading
            ? SizedBox(width: 24.r, height: 24.r, child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20.sp), SizedBox(width: 8.w)],
                  Text(text, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class SuccessButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SuccessButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        ),
        child: isLoading
            ? SizedBox(width: 24.r, height: 24.r, child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20.sp), SizedBox(width: 8.w)],
                  Text(text, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class GhostButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GhostButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18.sp), SizedBox(width: 6.w)],
          Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class SplitButtonWidget extends StatelessWidget {
  final String primaryText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onDropdownPressed;

  const SplitButtonWidget({
    super.key,
    required this.primaryText,
    required this.onPrimaryPressed,
    required this.onDropdownPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onPrimaryPressed,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.r12)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(primaryText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ),
          ),
          VerticalDivider(color: Colors.white38, width: 1, indent: 8.h, endIndent: 8.h),
          InkWell(
            onTap: onDropdownPressed,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.r12)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
              child: const Icon(Icons.arrow_drop_down, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
