import 'package:flutter/material.dart';

/// Paleta "Candy Crush" del prototipo, con más variedad de color
/// (pedido explícito: "un poco más de colores") para que el tablero,
/// las casillas y las pantallas se sientan más vivas que el prototipo HTML.
class AppColors {
  AppColors._();

  static const parchment = Color(0xFFFFF3FA);
  static const parchmentDark = Color(0xFFFFE1F0);
  static const ink = Color(0xFF3A2E4D);

  static const violet = Color(0xFF7C4DFF);
  static const violetDark = Color(0xFF5E35B1);
  static const fuchsia = Color(0xFFFF4D8D);
  static const gold = Color(0xFFFFC93C);
  static const turquoise = Color(0xFF4FD8E0);
  static const sky = Color(0xFF29B6F6);
  static const green = Color(0xFF43D67D);

  // Acentos extra para darle más variedad cromática a botones, tabs y estados.
  static const indigo = Color(0xFF5C7CFA);
  static const coral = Color(0xFFFF7043);
  static const lemon = Color(0xFFFFD93D);
  static const magenta = Color(0xFFB24DFF);
  static const amber = Color(0xFFFFB020);

  static const tokenColors = <Color>[
    violet, fuchsia, Color(0xFF3D8BFD), amber, magenta, green,
  ];

  static const cellColors = <String, Color>{
    'meta': fuchsia,
    'oca': lemon,
    'puente': turquoise,
    'carcel': indigo,
    'calavera': coral,
    'minijuego': sky,
  };

  static const cellIcons = <String, String>{
    'oca': '🪿',
    'puente': '🌉',
    'carcel': '⛓️',
    'calavera': '💀',
    'meta': '🏆',
    'minijuego': '🎮',
  };

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: parchment,
      colorScheme: ColorScheme.fromSeed(
        seedColor: violet,
        primary: violetDark,
        secondary: fuchsia,
        tertiary: gold,
      ),
      fontFamily: 'Georgia',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violetDark,
          foregroundColor: parchment,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: violetDark,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
