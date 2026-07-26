import 'package:flutter/material.dart';

/// Los 4 bloques visuales de la campaña (especificación visual v2,
/// sección 1). Los avatares e íconos de casilla mantienen su forma en
/// todo el juego — lo único que cambia por bloque es el fondo del
/// tablero, la iluminación ambiente (AppBar) y los acentos de color.
enum BloqueEtapas { comienzo, desafio, tension, cima }

BloqueEtapas bloqueDeEtapa(int etapa) {
  if (etapa <= 3) return BloqueEtapas.comienzo;
  if (etapa <= 6) return BloqueEtapas.desafio;
  if (etapa <= 9) return BloqueEtapas.tension;
  return BloqueEtapas.cima;
}

class PaletaBloque {
  const PaletaBloque({
    required this.nombre,
    required this.gradiente,
    required this.colorAppBar,
    required this.colorAcento,
  });

  final String nombre;
  final List<Color> gradiente;
  final Color colorAppBar;
  final Color colorAcento;

  static const Map<BloqueEtapas, PaletaBloque> porBloque = {
    // 1-3 · Comienzo: natural, cálido, amigable — mañana soleada.
    BloqueEtapas.comienzo: PaletaBloque(
      nombre: 'Comienzo',
      gradiente: [Color(0xFFDFF6E0), Color(0xFFFFF6D8), Color(0xFFD9F3FA)],
      colorAppBar: Color(0xFF43D67D),
      colorAcento: Color(0xFFFFC93C),
    ),
    // 4-6 · Desafío: misterioso, aire fresco — atardecer/viento.
    BloqueEtapas.desafio: PaletaBloque(
      nombre: 'Desafío',
      gradiente: [Color(0xFFE3DBFF), Color(0xFFD6E4FF), Color(0xFFCFF3F1)],
      colorAppBar: Color(0xFF7C4DFF),
      colorAcento: Color(0xFF4FD8E0),
    ),
    // 7-9 · Tensión: intenso pero nunca oscuro — peligro controlado.
    BloqueEtapas.tension: PaletaBloque(
      nombre: 'Tensión',
      gradiente: [Color(0xFFFFE0D6), Color(0xFFFFF0E8), Color(0xFFFFF8F5)],
      colorAppBar: Color(0xFFFF6F4D),
      colorAcento: Color(0xFFFF4D8D),
    ),
    // 10 · Cima: épico, celebratorio — dorado + arcoíris sutil.
    BloqueEtapas.cima: PaletaBloque(
      nombre: 'Cima',
      gradiente: [
        Color(0xFFFFF3D0),
        Color(0xFFFFE8B0),
        Color(0xFFFFD966),
      ],
      colorAppBar: Color(0xFFE0A800),
      colorAcento: Color(0xFF7C4DFF),
    ),
  };

  static PaletaBloque deEtapa(int etapa) => porBloque[bloqueDeEtapa(etapa)]!;
}
