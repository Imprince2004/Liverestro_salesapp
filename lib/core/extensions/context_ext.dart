import 'package:flutter/material.dart';

/// Extension on BuildContext for quick theme, screen dimensions & localization access.
extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  bool get isDarkMode => theme.brightness == Brightness.dark;
}
