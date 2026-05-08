import 'package:flutter/material.dart';

class AppColors {
  // ---- LIGHT MODE PASTELS ----
  static const Color pastelBlue = Color(0xFFB8D8F8);
  static const Color powderBlue = Color(0xFFD4E8FF);
  static const Color lavender = Color(0xFFDDD5F3);
  static const Color mint = Color(0xFFB8EAD8);
  static const Color blush = Color(0xFFF8D7DA);
  static const Color peach = Color(0xFFFFDBC9);
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color softGray = Color(0xFFF0EEF8);

  // ---- LIGHT MODE PRIMARIES ----
  static const Color primaryBlue = Color(0xFF4A90D9);
  static const Color primaryPurple = Color(0xFF7B68EE);
  static const Color primaryMint = Color(0xFF3DBFA0);
  static const Color primaryPeach = Color(0xFFFF8C69);

  // ---- DARK MODE SPACE THEME ----
  static const Color spaceNavy = Color(0xFF0D1B3E);
  static const Color spaceMidnight = Color(0xFF1A2744);
  static const Color spaceIndigo = Color(0xFF2D3A6E);
  static const Color spacePurple = Color(0xFF3D2F6E);
  static const Color dustyBlue = Color(0xFF4A5F8C);
  static const Color starWhite = Color(0xFFE8ECFF);
  static const Color nebulaPink = Color(0xFF8B5CF6);

  // ---- NEUTRAL ----
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9FAFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMed = Color(0xFF4A4A6A);
  static const Color textLight = Color(0xFF8A8AA0);
  static const Color divider = Color(0xFFE0E0F0);

  // ---- STATUS COLORS ----
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFE53935);
  static const Color batteryGreen = Color(0xFF66BB6A);
  static const Color batteryYellow = Color(0xFFFFEE58);
  static const Color batteryRed = Color(0xFFEF5350);

  // ---- GRADIENTS ----
  static const LinearGradient lightBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEF4FF), Color(0xFFF5F0FF), Color(0xFFFFEFF9)],
  );

  static const LinearGradient darkBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B3E), Color(0xFF1A2744), Color(0xFF2D1F4E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8D8F8), Color(0xFFDDD5F3)],
  );

  static const LinearGradient batteryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8EAD8), Color(0xFFB8D8F8)],
  );
}
