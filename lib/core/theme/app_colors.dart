import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Color Schemes for Material 3 Light and Dark themes.
class AppThemeColors {
  AppThemeColors._();

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryVariant,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: AppColors.primary,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.borderLight,
    shadow: Color(0x0F000000),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9E678F),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF42263B),
    onPrimaryContainer: Color(0xFFFDE8F5),
    secondary: Color(0xFF818CF8),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF2E2D6B),
    onSecondaryContainer: Colors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.borderDark,
    shadow: Color(0x55000000),
  );
}
