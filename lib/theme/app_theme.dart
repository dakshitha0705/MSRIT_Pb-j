import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  void toggle() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class AppTheme {
  // ── Light ────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFF4F4F5),
        cardColor: Colors.white,
        // Force ALL default text to dark
        textTheme: _lightText,
        primaryTextTheme: _lightText,
        iconTheme: const IconThemeData(color: Color(0xFF18181B)),
        appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFFF4F4F5),
            foregroundColor: Color(0xFF09090B),
            iconTheme: IconThemeData(color: Color(0xFF09090B)),
            titleTextStyle: TextStyle(
                color: Color(0xFF09090B),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        listTileTheme: const ListTileThemeData(
            textColor: Color(0xFF09090B), iconColor: Color(0xFF09090B)),
        dividerColor: const Color(0xFFE4E4E7),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF71717A)),
          labelStyle: const TextStyle(color: Color(0xFF71717A)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white)),
        chipTheme: const ChipThemeData(
            backgroundColor: Color(0xFFE4E4E7),
            labelStyle: TextStyle(color: Color(0xFF09090B))),
      );

  // ── Dark ─────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF09090B),
        cardColor: const Color(0xFF18181B),
        textTheme: _darkText,
        primaryTextTheme: _darkText,
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        listTileTheme: const ListTileThemeData(
            textColor: Colors.white, iconColor: Colors.white),
        dividerColor: Colors.white12,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          hintStyle: TextStyle(color: Colors.white38),
          labelStyle: TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white)),
      );

  static const _lightText = TextTheme(
    displayLarge: TextStyle(color: Color(0xFF09090B)),
    displayMedium: TextStyle(color: Color(0xFF09090B)),
    displaySmall: TextStyle(color: Color(0xFF09090B)),
    headlineLarge:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w800),
    headlineMedium:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w700),
    headlineSmall:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w700),
    titleLarge:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w700),
    titleMedium:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
    titleSmall:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Color(0xFF09090B)),
    bodyMedium: TextStyle(color: Color(0xFF18181B)),
    bodySmall: TextStyle(color: Color(0xFF52525B)),
    labelLarge:
        TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF52525B)),
    labelSmall: TextStyle(color: Color(0xFF71717A)),
  );

  static const _darkText = TextTheme(
    displayLarge: TextStyle(color: Colors.white),
    displayMedium: TextStyle(color: Colors.white),
    displaySmall: TextStyle(color: Colors.white),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Color(0xFFA1A1AA)),
    labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFFA1A1AA)),
    labelSmall: TextStyle(color: Color(0xFFA1A1AA)),
  );
}
