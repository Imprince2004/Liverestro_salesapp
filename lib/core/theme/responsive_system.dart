import 'package:flutter/material.dart';

/// Responsive device break-points and utility system.
class ResponsiveSystem {
  ResponsiveSystem._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  static Orientation getOrientation(BuildContext context) =>
      MediaQuery.of(context).orientation;

  static bool isPortrait(BuildContext context) =>
      getOrientation(context) == Orientation.portrait;
}
