import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/dimensions.dart';

/// Spacing tokens and EdgeInsets utility helpers.
class AppSpacing {
  AppSpacing._();

  static double get xs => AppDimensions.p4.w;
  static double get sm => AppDimensions.p8.w;
  static double get md => AppDimensions.p12.w;
  static double get lg => AppDimensions.p16.w;
  static double get xl => AppDimensions.p20.w;
  static double get xxl => AppDimensions.p24.w;
  static double get xxxl => AppDimensions.p32.w;

  static EdgeInsets get paddingAllSm => EdgeInsets.all(sm);
  static EdgeInsets get paddingAllMd => EdgeInsets.all(md);
  static EdgeInsets get paddingAllLg => EdgeInsets.all(lg);
  static EdgeInsets get paddingAllXl => EdgeInsets.all(xl);

  static EdgeInsets get paddingSymmetricH => EdgeInsets.symmetric(horizontal: lg);
  static EdgeInsets get paddingSymmetricV => EdgeInsets.symmetric(vertical: md);
  static EdgeInsets get paddingScreen => EdgeInsets.symmetric(horizontal: lg, vertical: lg);

  static SizedBox get vGapXs => SizedBox(height: xs);
  static SizedBox get vGapSm => SizedBox(height: sm);
  static SizedBox get vGapMd => SizedBox(height: md);
  static SizedBox get vGapLg => SizedBox(height: lg);
  static SizedBox get vGapXl => SizedBox(height: xl);
  static SizedBox get vGapXxl => SizedBox(height: xxl);

  static SizedBox get hGapXs => SizedBox(width: xs);
  static SizedBox get hGapSm => SizedBox(width: sm);
  static SizedBox get hGapMd => SizedBox(width: md);
  static SizedBox get hGapLg => SizedBox(width: lg);
  static SizedBox get hGapXl => SizedBox(width: xl);
}
