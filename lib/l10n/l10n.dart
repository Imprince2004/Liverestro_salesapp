import 'package:flutter/material.dart';

/// Centralized localization config and helper class for LiveRestro Sales.
class L10n {
  static final all = [
    const Locale('en'), // English
    const Locale('hi'), // Hindi
    const Locale('gu'), // Gujarati
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'en':
      default:
        return 'English';
    }
  }
}
