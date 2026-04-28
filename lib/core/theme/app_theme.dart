import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand accent colors (theme-independent)
  static const Color brandNeonGreen = Color(0xFF00E676);
  static const Color brandElectricBlue = Color(0xFF2979FF);

  // Dark theme palette
  static const Color _darkBg = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF252525);

  // Light theme palette
  static const Color _lightBg = Color(0xFFF5F5F5);
  static const Color _lightSurface = Colors.white;
  static const Color _lightOnSurface = Color(0xFF1A1A1A);
  static const Color _lightOnSurfaceVariant = Color(0xFF757575);
  static const Color _lightOutline = Color(0xFFE0E0E0);
  static const Color _lightPrimary = Color(0xFF00C853); // muted neonGreen for contrast on white

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: brandNeonGreen,
          secondary: brandElectricBlue,
          surface: _darkSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBg: _darkBg,
        cardColor: _darkCard,
        inputFill: _darkSurface,
        bottomNavBg: _darkSurface,
        primaryButtonFg: Colors.black,
        cardBorder: null,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: _lightPrimary,
          secondary: brandElectricBlue,
          surface: _lightSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _lightOnSurface,
          onSurfaceVariant: _lightOnSurfaceVariant,
          outline: _lightOutline,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBg: _lightBg,
        cardColor: _lightSurface,
        inputFill: _lightSurface,
        bottomNavBg: _lightSurface,
        primaryButtonFg: Colors.white,
        cardBorder: _lightOutline,
      );

  // Backwards compatibility alias — main.dart currently calls AppTheme.darkTheme.
  // Remove once main.dart is updated in Task 3.
  static ThemeData get darkTheme => dark;

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color inputFill,
    required Color bottomNavBg,
    required Color primaryButtonFg,
    required Color? cardBorder,
  }) {
    final isLight = brightness == Brightness.light;
    final secondaryTextColor =
        isLight ? _lightOnSurfaceVariant : Colors.white70;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
      colorScheme: scheme,
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: cardBorder == null
              ? BorderSide.none
              : BorderSide(color: cardBorder, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: scheme.onSurface,
        iconColor: secondaryTextColor,
      ),
      dividerTheme: DividerThemeData(
        color: isLight
            ? _lightOutline
            : Colors.white.withValues(alpha: 0.12),
        thickness: 1,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          headlineMedium:
              TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
          titleLarge:
              TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
          bodyLarge: TextStyle(color: scheme.onSurface),
          bodyMedium: TextStyle(color: secondaryTextColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? Colors.white : Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
          letterSpacing: 2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBg,
        selectedItemColor: scheme.primary,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: primaryButtonFg,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isLight
              ? const BorderSide(color: _lightOutline)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isLight
              ? const BorderSide(color: _lightOutline)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
      ),
    );
  }
}
