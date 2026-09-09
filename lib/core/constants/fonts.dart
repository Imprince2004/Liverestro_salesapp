import 'package:google_fonts/google_fonts.dart';

/// Typography font family constants for LiveRestro Sales.
class AppFonts {
  AppFonts._();

  static String get fontFamily => GoogleFonts.plusJakartaSans().fontFamily ?? 'PlusJakartaSans';
  static String get secondaryFontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';
}
