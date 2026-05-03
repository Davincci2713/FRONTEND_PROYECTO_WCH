import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF00341C);
  static const Color primaryContainer = Color(0xFF004D2C);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFFBB0014);
  static const Color secondaryContainer = Color(0xFFE51D24);
  static const Color onSecondary = Colors.white;
  static const Color tertiary = Color(0xFF002A62);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        background: background,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      textTheme: GoogleFonts.workSansTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          fontSize: 57,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.lexend(
          fontSize: 45,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.lexend(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.lexend(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
