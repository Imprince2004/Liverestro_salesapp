import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/dimensions.dart';

/// Border radius design system tokens.
class AppRadius {
  AppRadius._();

  static double get r4 => AppDimensions.r4.r;
  static double get r8 => AppDimensions.r8.r;
  static double get r12 => AppDimensions.r12.r;
  static double get r16 => AppDimensions.r16.r;
  static double get r24 => AppDimensions.r24.r;
  static double get r32 => AppDimensions.r32.r;
  static double get rFull => AppDimensions.rFull.r;

  static BorderRadius get radiusSm => BorderRadius.circular(r4);
  static BorderRadius get radiusMd => BorderRadius.circular(r8);
  static BorderRadius get radiusLg => BorderRadius.circular(r12);
  static BorderRadius get radiusXl => BorderRadius.circular(r16);
  static BorderRadius get radiusXxl => BorderRadius.circular(r24);
  static BorderRadius get radiusFull => BorderRadius.circular(rFull);
}
