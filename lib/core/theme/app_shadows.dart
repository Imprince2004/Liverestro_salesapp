import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shadow tokens for Light and Dark themes.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft({bool isDark = false}) => [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> medium({bool isDark = false}) => [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> heavy({bool isDark = false}) => [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}
