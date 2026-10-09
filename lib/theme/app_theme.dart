// THEME LOCK: light — source: domain signal (consumer lifestyle/relationship app)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette
  static const Color primary = Color(0xFFFF407A);
  static const Color primaryContainer = Color(0xFFFFD6E0);
  static const Color secondary = Color(0xFF3D7A5E);
  static const Color secondaryContainer = Color(0xFFB8E0CE);

  // Semantic colors
  static const Color success = Color(0xFF2D7A4F);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFB91C1C);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFFFF5F7);
  static const Color backgroundLight = Color(0xFFFFF6F3);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1E1A1B);
  static const Color backgroundDark = Color(0xFF141012);

  // Custom semantic
  static const Color moodHappy = Color(0xFFFFB347);
  static const Color moodSad = Color(0xFF6B9EC7);
  static const Color moodFought = Color(0xFFE05C5C);
  static const Color moodIntimate = Color(0xFFE8547A);
  static const Color moodNeutral = Color(0xFF9E9E9E);
  static const Color moodSaw = Color(0xFF3D7A5E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF294737), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4, insetPadding: const EdgeInsets.all(16)),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFFFF8F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()}),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : const Color(0xFFFBE9E9)),
      foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : const Color(0xFF6B6066)),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    )),
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF3D0017),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF00210F),
      surface: surfaceLight,
      onSurface: Color(0xFF1A1A1A),
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: Color(0xFF5A5A5A),
      error: error,
      onError: Colors.white,
      outline: Color(0xFFE0C8CC),
      outlineVariant: Color(0xFFF0E4E7),
      inverseSurface: Color(0xFF1A1A1A),
      onInverseSurface: Colors.white,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundLight,
      elevation: 0,
      shadowColor: const Color(0x22C77685),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 1,
      shadowColor: const Color(0x22C77685),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: error, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: primary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primary,
      labelStyle: WidgetStateTextStyle.resolveWith((states) => GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: states.contains(WidgetState.selected) ? Colors.white : const Color(0xFF605865))),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 8,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF6B1733),
      onPrimaryContainer: Color(0xFFFFD6E0),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1A4A35),
      onSecondaryContainer: secondaryContainer,
      surface: surfaceDark,
      onSurface: Color(0xFFE6E6E6),
      surfaceContainerHighest: Color(0xFF2A2426),
      onSurfaceVariant: Color(0xFFBBBBBB),
      error: Color(0xFFCF6679),
      onError: Colors.white,
      outline: Color(0xFF5A4A4D),
      outlineVariant: Color(0xFF3A2E30),
      inverseSurface: Color(0xFFE6E6E6),
      onInverseSurface: Color(0xFF1A1A1A),
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE6E6E6),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE6E6E6),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E6E6),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E6E6),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE6E6E6),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFFCCCCCC),
        ),
      ),
    ),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
