import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Palettes (Dark Theme)
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkSecondary = Color(0xFF2DD4BF);
  static const Color darkAccent = Color(0xFFA78BFA);

  // Theme Color Palettes (Light Theme)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF14B8A6);
  static const Color lightAccent = Color(0xFF8B5CF6);

  // Vitals & Metric specific colors
  static const Color heartRate = Color(0xFFFF4D6D);
  static const Color steps = Color(0xFF3B82F6);
  static const Color calories = Color(0xFFF97316);
  static const Color spo2Mint = Color(0xFF06B6D4);
  static const Color tempAmber = Color(0xFFA855F7);
  static const Color batteryGreen = Color(0xFF84CC16);

  // Backward compatibility color aliases
  static const Color secondaryCoral = heartRate;
  static const Color stepsCyan = steps;
  static const Color caloriesOrange = calories;

  // Success / Warning / Error States
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Glassmorphic styling utilities
  static Decoration glassDecoration({
    required bool isDarkMode,
    double radius = 20.0,
    Color? customColor,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: customColor ??
          (isDarkMode
              ? darkSurface.withOpacity(0.65)
              : lightSurface.withOpacity(0.85)),
      border: Border.all(
        color: isDarkMode
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Widget glassBlur({
    required Widget child,
    double blur = 12.0,
    double radius = 20.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightPrimary,
      cardColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBg,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(
          textStyle: const TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.w400),
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: const TextStyle(color: lightTextSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        ),
        bodySmall: GoogleFonts.inter(
          textStyle: const TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w400),
        ),
        titleLarge: GoogleFonts.poppins(
          textStyle: const TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        titleMedium: GoogleFonts.poppins(
          textStyle: const TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        headlineMedium: GoogleFonts.poppins(
          textStyle: const TextStyle(color: lightText, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: lightText),
        centerTitle: true,
        titleTextStyle: TextStyle(color: lightText, fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkPrimary,
      cardColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        background: darkBg,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(
          textStyle: const TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.w400),
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: const TextStyle(color: darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        ),
        bodySmall: GoogleFonts.inter(
          textStyle: const TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w400),
        ),
        titleLarge: GoogleFonts.poppins(
          textStyle: const TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        titleMedium: GoogleFonts.poppins(
          textStyle: const TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        headlineMedium: GoogleFonts.poppins(
          textStyle: const TextStyle(color: darkText, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkText),
        centerTitle: true,
        titleTextStyle: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
