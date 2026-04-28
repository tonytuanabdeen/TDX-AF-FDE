import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  static const Color brandRed = Color(0xFFC0001E);

  // iOS-style surface colours used directly in widgets
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSeparator = Color(0xFFE5E5EA);
  static const Color darkBg = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkSeparator = Color(0xFF38383A);
  static const Color secondaryLabel = Color(0xFF8E8E93);

  static ThemeData light() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandRed,
          brightness: Brightness.light,
          surface: lightCard,
        ),
        scaffoldBg: lightBg,
        statusStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData dark() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandRed,
          brightness: Brightness.dark,
          surface: darkCard,
        ),
        scaffoldBg: darkBg,
        statusStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required SystemUiOverlayStyle statusStyle,
  }) {
    final tt = GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: colorScheme.brightness).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: tt,
      scaffoldBackgroundColor: scaffoldBg,
      // Flat app bar — no shadow, no elevation
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: statusStyle,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      // No splash / ripple so taps feel iOS-native
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: const ListTileThemeData(
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: const DividerThemeData(space: 0, thickness: 0.5),
    );
  }
}
