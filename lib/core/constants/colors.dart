import 'package:flutter/material.dart';

/// LiveRestro Sales Color Palette & Brand Tokens.
class AppColors {
  AppColors._();

  // Brand Palette
  static const Color primary = Color(0xFF714B67);
  static const Color primaryVariant = Color(0xFF5A364E);
  static const Color primaryLight = Color(0xFFF3E9F0);
  static const Color accent = Color(0xFF8D5E7B);
  static const Color accentSoft = Color(0xFFF8F0F5);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F3F9);

  // Dark Theme Colors (Refined deep slate-plum)
  static const Color backgroundDark = Color(0xFF0F0D1B);
  static const Color surfaceDark = Color(0xFF191629);
  static const Color surfaceVariantDark = Color(0xFF231F36);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E1B2E);
  static const Color textSecondaryLight = Color(0xFF6B6684);
  static const Color textMutedLight = Color(0xFF9E99B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Border & Divider
  static const Color borderLight = Color(0xFFE2E4EC);
  static const Color borderDark = Color(0xFF2E2946);

  // Functional & Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFE6F4EA);
  static const Color successBgDark = Color(0xFF0B2E24);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFCE8E6);
  static const Color errorBgDark = Color(0xFF381414);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF7E0);
  static const Color warningBgDark = Color(0xFF3B240B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFE8F0FE);
  static const Color infoBgDark = Color(0xFF12224A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [surfaceDark, backgroundDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
