import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta Mundial 2026 - basada en el estilo de la imagen
  static const Color primary = Color(0xFF00341C);       // Verde oscuro FIFA
  static const Color primaryDark = Color(0xFF001A0E);   // Verde casi negro
  static const Color accentRed = Color(0xFFCC0000);     // Rojo brillante
  static const Color accentBlue = Color(0xFF0033A0);    // Azul FIFA
  static const Color accentYellow = Color(0xFFFFCC00);  // Amarillo dorado
  static const Color accentGreen = Color(0xFF009900);   // Verde vivo
  static const Color surface = Color(0xFF0A0A0A);       // Fondo casi negro
  static const Color surfaceCard = Color(0xFF141414);   // Tarjeta oscura
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color onSurface = Color(0xFFF5F5F5);
  static const Color onSurfaceMuted = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF2A2A2A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accentRed,
        onSecondary: Colors.white,
        tertiary: accentBlue,
        surface: surfaceCard,
        onSurface: onSurface,
        error: accentRed,
        outline: divider,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme().copyWith(
        displayLarge: GoogleFonts.barlow(
          fontSize: 57, fontWeight: FontWeight.w900,
          color: onSurface, letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.barlow(
          fontSize: 45, fontWeight: FontWeight.w900,
          color: onSurface, letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.barlow(
          fontSize: 36, fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.barlow(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.barlow(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.barlow(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.barlow(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.rajdhani(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: onSurface, letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 16, color: onSurface,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 14, color: onSurfaceMuted,
        ),
        labelLarge: GoogleFonts.barlow(
          fontSize: 14, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.barlow(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.barlow(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        hintStyle: GoogleFonts.rajdhani(color: onSurfaceMuted),
        prefixIconColor: onSurfaceMuted,
        suffixIconColor: onSurfaceMuted,
        labelStyle: GoogleFonts.rajdhani(color: onSurfaceMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: accentRed,
        unselectedItemColor: Color(0xFF666666),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }
}