import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF00476B);
  static const Color secondaryBlue = Color(0xFF0092C8);
  static const Color textGray = Color(0xFF555555);
  static const Color backgroundLight = Color(0xFFF7F3F8);
  static const Color successGreen = Color(0xFF2EB872);
  static const Color warningYellow = Color(0xFFF4C542);
  static const Color dangerRed = Color(0xFFEA4335);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryBlue,
        secondary: secondaryBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: secondaryBlue, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue),
        bodyMedium: TextStyle(fontSize: 16, color: textGray),
      ),
    );
  }
}
