import 'package:flutter/material.dart';

/// Animation duration and curve tokens for LiveRestro Sales.
class AppAnimations {
  AppAnimations._();

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveFastOutSlowIn = Curves.fastOutSlowIn;
}
