import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors — Deep Dark Blue / Navy
  static const Color primary = Color(0xFF004D8F); // Deep Dark Navy
  static const Color primaryDark = Color(0xFF061626); // Midnight Navy
  static const Color primaryLight = Color(0xFF1D4ED8); // Vibrant Royal Dark Blue
  static const Color primarySubtle = Color(0xFFF0F6FF); // Very light blue tint

  // Clean White Backgrounds & Surfaces
  static const Color bg = Color(0xFFF8FAFC); // Clean crisp off-white canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white surface
  static const Color card = Color(0xFFFFFFFF); // Pure white cards
  static const Color border = Color(0xFFE2E8F0); // Subtle slate border

  // Compatibility aliases for existing screen references
  static const Color bgDark = bg;
  static const Color surfaceDark = surface;
  static const Color cardDark = card;
  static const Color borderDark = border;

  // Accents
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accentEmerald = Color(0xFF059669);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentRose = Color(0xFFE11D48);

  // High contrast text typography
  static const Color textMain = Color(0xFF0F172A); // Dark navy slate text
  static const Color textMuted = Color(0xFF475569); // Slate secondary text
  static const Color textDim = Color(0xFF94A3B8); // Muted slate text

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: accentRose,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textMain,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textMain,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textDim,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textDim, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textMain),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textMain),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textMain),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textMain),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textMain),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textMain),
        bodyLarge: GoogleFonts.plusJakartaSans(color: textMain),
        bodyMedium: GoogleFonts.plusJakartaSans(color: textMuted),
      ),
    );
  }

  // Alias darkTheme to lightTheme for consistent white & dark blue appearance
  static ThemeData get darkTheme => lightTheme;
}
