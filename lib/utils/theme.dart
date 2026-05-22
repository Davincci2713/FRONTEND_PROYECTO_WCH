import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool isLightMode = false;

  // Brand Neo-Brutalist (Constants)
  static const Color primary       = Color(0xFFCCFF00); // Neon Lime
  static const Color primaryDark   = Color(0xFF99CC00);
  static const Color primaryLight  = Color(0xFFE6FF80);
  static const Color secondary     = Color(0xFF00341C); // Original Green

  // Dynamic Neutral & Semantic Colors
  static Color get error         => isLightMode ? const Color(0xFFCC0000) : const Color(0xFFFF3333); // WCAG AA compliant red
  
  static Color get background    => isLightMode ? const Color(0xFFF4F4F0) : const Color(0xFF0B0E0C);
  static Color get surface       => isLightMode ? Colors.white : const Color(0xFF121614);
  static Color get surfaceVariant=> isLightMode ? const Color(0xFFEAEAEA) : const Color(0xFF1A1F1C);
  
  static Color get text          => isLightMode ? Colors.black : Colors.white;
  static Color get textMuted     => isLightMode ? const Color(0xFF4A4A4A) : Colors.white54; // #4A4A4A passes 4.5:1 on light bg
  
  static Color get border        => isLightMode ? Colors.black : Colors.white24;
  static Color get borderLight   => isLightMode ? Colors.black12 : Colors.white12;
  
  // Specific use cases
  static Color get inverseSurface=> isLightMode ? Colors.white : Colors.black;
  static Color get onPrimary     => Colors.black; // Text on Neon is always black

  // Accent text: lime on dark backgrounds, dark-green on light (WCAG AA)
  static Color get accentText    => isLightMode ? secondary : primary;
  // Accent icon/decorative: same logic — ensures 3:1 on light, full lime on dark
  static Color get accentIcon    => isLightMode ? secondary : primary;

  // Toggle inactive colors
  static Color get toggleInactiveTrack => isLightMode ? const Color(0xFFCCCCCC) : Colors.white12;
  static Color get toggleInactiveThumb => isLightMode ? const Color(0xFF888888) : Colors.white54;
}

class AppRadius {
  // Brutalism uses sharp edges
  static const double xs  = 0;
  static const double sm  = 0;
  static const double md  = 0;
  static const double lg  = 0;
  static const double xl  = 0;
  static const double pill = 0;
}

class AppTheme {
  static ThemeData get currentTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: AppColors.isLightMode ? Brightness.light : Brightness.dark,
      colorScheme: AppColors.isLightMode 
        ? ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.secondary,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
            error: AppColors.error,
          )
        : ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.secondary,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
            error: AppColors.error,
          ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w900, letterSpacing: -2, color: AppColors.text),
        displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: AppColors.text),
        displaySmall:  GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.text),
        headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text),
        headlineMedium:GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text),
        headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text),
        titleLarge:    GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
        titleMedium:   GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
        titleSmall:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
        bodyLarge:     GoogleFonts.dmSans(fontSize: 16, height: 1.6, color: AppColors.text),
        bodyMedium:    GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: AppColors.textMuted),
        bodySmall:     GoogleFonts.dmSans(fontSize: 12, height: 1.5, color: AppColors.textMuted),
        labelLarge:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.text),
        labelMedium:   GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.text),
        labelSmall:    GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: AppColors.primary, width: 2),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.text, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 16),
        labelStyle: GoogleFonts.dmSans(color: AppColors.accentText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? AppColors.onPrimary : AppColors.textMuted,
            letterSpacing: 1,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.onPrimary : AppColors.textMuted,
            size: 22,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 2,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
