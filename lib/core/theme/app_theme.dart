import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GetTaller design system — from YAML design specs.
///
/// Colors:
///   Primary: #4C1D95 (deep purple)
///   Secondary: #7C3AED (vivid purple)
///   Tertiary: #8B5CF6
///   Background: #F8FAFC (slate 50)
///   Text: #0F172A (slate 900)
///
/// Typography:
///   Display/Headlines: Plus Jakarta Sans (w800 display, w700 headlines)
///   Body/Labels: Inter (w400 body, w600 labels)
class AppTheme {
  AppTheme._();

  // ── Color Palette (from YAML color-scheme) ──
  static const Color primary = Color(0xFF4C1D95);
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF2D0A5E);

  // Backward-compatible aliases (same as above)
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color accentDark = primaryDark;

  static const Color secondary = Color(0xFF7C3AED);
  static const Color tertiary = Color(0xFF8B5CF6);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Dark mode
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Extended accents (from YAML)
  static const Color accent1 = Color(0xFF4B39EF);
  static const Color accent2 = Color(0xFF39D2C0);
  static const Color energyOrange = Color(0xFFFF9800);
  static const Color sleepIndigo = Color(0xFF3F51B5);
  static const Color calmPurple = Color(0xFF7C4DFF);

  // ── Shadows (from YAML) ──
  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : const Color(0x1A0F172A), // 10% slate 900
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.15)
            : const Color(0x0D0F172A), // 5% slate 900
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? primaryLight.withOpacity(0.15)
        : primary.withOpacity(0.08);
    return [
      BoxShadow(
        color: color,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  // ── Typography Helpers ──
  // Display/headlines: Plus Jakarta Sans; Body/labels: Inter

  static TextStyle _plusJakartaSans({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // ── Light Theme ──
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surfaceLight,
      error: error,
    ),
    textTheme: TextTheme(
      // YAML typography: Plus Jakarta Sans for display/headlines
      displayLarge: _plusJakartaSans(fontSize: 58, fontWeight: FontWeight.w800, height: 1.1),
      displayMedium: _plusJakartaSans(fontSize: 46, fontWeight: FontWeight.w700, height: 1.15),
      displaySmall: _plusJakartaSans(fontSize: 38, fontWeight: FontWeight.w700, height: 1.2),
      headlineLarge: _plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25),
      headlineMedium: _plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, height: 1.3),
      headlineSmall: _plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, height: 1.35),
      titleLarge: _plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
      titleMedium: _plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, height: 1.45),
      titleSmall: _plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
      // Inter for body/labels
      bodyLarge: _inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
      bodyMedium: _inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
      bodySmall: _inter(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary, height: 1.4),
      labelLarge: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary, height: 1.4),
      labelMedium: _inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, height: 1.3),
      labelSmall: _inter(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary, height: 1.2),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: surfaceLight,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Inter'),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, fontFamily: 'Inter'),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      selectedColor: primary.withOpacity(0.15),
      labelStyle: const TextStyle(fontSize: 14, color: textPrimary, fontFamily: 'Inter'),
      side: BorderSide.none,
    ),
  );

  // ── Dark Theme ──
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: secondary,
      tertiary: tertiary,
      surface: surfaceDark,
      error: error,
    ),
    textTheme: TextTheme(
      displayLarge: _plusJakartaSans(fontSize: 58, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
      displayMedium: _plusJakartaSans(fontSize: 46, fontWeight: FontWeight.w700, color: Colors.white, height: 1.15),
      displaySmall: _plusJakartaSans(fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
      headlineLarge: _plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25),
      headlineMedium: _plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
      headlineSmall: _plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.35),
      titleLarge: _plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
      titleMedium: _plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.45),
      titleSmall: _plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.5),
      bodyLarge: _inter(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFFE2E8F0), height: 1.6),
      bodyMedium: _inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8), height: 1.5),
      bodySmall: _inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF64748B), height: 1.4),
      labelLarge: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), height: 1.4),
      labelMedium: _inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), height: 1.3),
      labelSmall: _inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), height: 1.2),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: surfaceDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryLight,
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
