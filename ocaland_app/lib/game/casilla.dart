/// Tipos de casilla del tablero (sección 3 de la especificación).
enum TipoCasilla {
  normal,
  oca,
  puente,
  carcel,
  calavera,
  minijuego,
  meta,
}

extension TipoCasillaEmoji on TipoCasilla {
  String get emoji {
    switch (this) {
      case TipoCasilla.oca:
        return '🪿';
      case TipoCasilla.puente:
        return '🌉';
      case TipoCasilla.carcel:
        return '⛓️';
      case TipoCasilla.calavera:
        return '💀';
      case TipoCasilla.minijuego:
        return '🎮';
      case TipoCasilla.meta:
        return '🏆';
      case TipoCasilla.normal:
        return '';
    }
  }

  /// Si la casilla dispara Cuestionados (trivia) al caer en ella.
  bool get esCuestionados =>
      this == TipoCasilla.oca ||
      this == TipoCasilla.carcel ||
      this == TipoCasilla.calavera;

  /// Casillas de trampa: se ven más grandes que las normales y tienen
  /// animación de reposo en loop (spec visual v2, sección 4).
  bool get esCasillaFlotante =>
      this == TipoCasilla.oca ||
      this == TipoCasilla.puente ||
      this == TipoCasilla.carcel ||
      this == TipoCasilla.calavera ||
      this == TipoCasilla.minijuego;
}

class InfoPuente {
  const InfoPuente({required this.avance});

  /// Avance directo garantizado: entre +2 y +4 casillas (sección 3).
  final int avance;
}
