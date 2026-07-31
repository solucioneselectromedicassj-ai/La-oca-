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
    this.fondoAsset,
    this.fondoAspectRatio,
    this.fondoColorPie,
  });

  final String nombre;
  final List<Color> gradiente;
  final Color colorAppBar;
  final Color colorAcento;

  /// Fondo de escena real (arte del usuario) para este bloque: se
  /// muestra UNA sola vez, a su proporción natural, arriba del todo
  /// del tablero (ahí van el cielo/inicio) — si es `null`, se usa el
  /// fondo genérico dibujado en código (colina de color + pasto).
  final String? fondoAsset;

  /// Ancho/alto natural de [fondoAsset], para mostrarlo sin
  /// distorsión (ni estirado ni recortado raro).
  final double? fondoAspectRatio;

  /// Color del borde inferior de [fondoAsset] (muestreado de la
  /// imagen real): el resto del tablero, debajo de la imagen, se
  /// pinta con este color + textura de pasto, para que la transición
  /// sea pareja y no una costura brusca.
  final Color? fondoColorPie;

  static const Map<BloqueEtapas, PaletaBloque> porBloque = {
    // 1-3 · Comienzo: natural, cálido, amigable — mañana soleada.
    BloqueEtapas.comienzo: PaletaBloque(
      nombre: 'Comienzo',
      gradiente: [Color(0xFFDFF6E0), Color(0xFFFFF6D8), Color(0xFFD9F3FA)],
      colorAppBar: Color(0xFF43D67D),
      colorAcento: Color(0xFFFFC93C),
      fondoAsset: 'assets/paisaje/fondos/fondo_bosque.png',
      fondoAspectRatio: 1800 / 188,
      fondoColorPie: Color(0xFF49783B),
    ),
    // 4-6 · Desafío: misterioso, aire fresco — atardecer/viento.
    BloqueEtapas.desafio: PaletaBloque(
      nombre: 'Desafío',
      gradiente: [Color(0xFFE3DBFF), Color(0xFFD6E4FF), Color(0xFFCFF3F1)],
      colorAppBar: Color(0xFF7C4DFF),
      colorAcento: Color(0xFF4FD8E0),
      // El usuario reemplazó el jardín por este valle (montañas, río,
      // monedas y cristales) — a diferencia de bosque/castillo, esta
      // imagen no tiene una franja de relleno plano que recortar: es
      // detallada de punta a punta, así que se usa completa.
      fondoAsset: 'assets/paisaje/fondos/fondo_valle.png',
      fondoAspectRatio: 1024 / 559,
      fondoColorPie: Color(0xFF809D5A),
    ),
    // 7-9 · Tensión: intenso pero nunca oscuro — peligro controlado.
    BloqueEtapas.tension: PaletaBloque(
      nombre: 'Tensión',
      gradiente: [Color(0xFFFFE0D6), Color(0xFFFFF0E8), Color(0xFFFFF8F5)],
      colorAppBar: Color(0xFFFF6F4D),
      colorAcento: Color(0xFFFF4D8D),
      // Sin fondo de escena todavía (el arte que hay de este bloque es
      // roca volcánica suelta, no una escena completa) — usa el
      // genérico. Ver README para el detalle.
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
      // El usuario reemplazó el castillo flotante por esta calle de
      // carnaval (fuegos artificiales, comparsa, confeti) — misma
      // lógica que el valle: imagen detallada de punta a punta, se usa
      // completa en vez de recortar una franja.
      fondoAsset: 'assets/paisaje/fondos/fondo_carnaval.png',
      fondoAspectRatio: 1024 / 559,
      fondoColorPie: Color(0xFF624860),
    ),
  };

  static PaletaBloque deEtapa(int etapa) => porBloque[bloqueDeEtapa(etapa)]!;
}
