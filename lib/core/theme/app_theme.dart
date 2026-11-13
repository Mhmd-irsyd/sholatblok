// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palette Nuansa Merah Muda Elegan (Aesthetic Velvet Rose & Dusty Pink) ──
  // Didesain lembut, anggun, tidak norak, dan sangat ramah di mata (OLED Dark Mode)
  static const Color primaryRose = Color(0xFFC74B6A);    // Velvet Rose utama
  static const Color lightRose = Color(0xFFE87A90);      // Soft Dusty Pink (aksen terang)
  static const Color softBlush = Color(0xFFF4A8B8);      // Pastel Blush lembut
  static const Color roseGold = Color(0xFFE5B0BA);       // Rose Gold untuk tanggal/jam
  static const Color darkBg = Color(0xFF160D14);         // Deep Midnight Plum (background utama)
  static const Color cardBg = Color(0xFF261521);         // Muted Velvet Plum (kartu)
  static const Color cardBgElevated = Color(0xFF331D2D); // Kartu aktif / elevated

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRose,
        brightness: Brightness.dark,
        surface: darkBg,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: cardBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
