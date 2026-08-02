import 'package:flutter/material.dart';

/// Paleta "Candy Crush" de Ocaland (sección 13 de la especificación).
class OcalandColors {
  OcalandColors._();

  static const Color violeta = Color(0xFF7C4DFF);
  static const Color fucsia = Color(0xFFFF4D8D);
  static const Color amarillo = Color(0xFFFFC93C);
  static const Color turquesa = Color(0xFF4FD8E0);
  static const Color celeste = Color(0xFF29B6F6);
  static const Color verde = Color(0xFF43D67D);

  static const Color fondo = Color(0xFFFFF3FA);
}

class OcalandTheme {
  OcalandTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OcalandColors.violeta,
      primary: OcalandColors.violeta,
      secondary: OcalandColors.fucsia,
      tertiary: OcalandColors.turquesa,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OcalandColors.fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: OcalandColors.violeta,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OcalandColors.violeta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
