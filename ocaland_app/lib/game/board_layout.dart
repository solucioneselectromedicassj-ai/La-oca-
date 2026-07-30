import 'dart:math';

import 'casilla.dart';

/// Layout aleatorio del tablero (sección 3): 30 casillas, 0 = salida,
/// 29 = meta. De las 28 casillas intermedias, 20 son "trampa":
/// 6 oca, 6 minijuego, 3 trampolín, 3 cárcel, 2 calavera. El resto
/// quedan normales.
///
/// El layout se genera una vez por partida/etapa y después viaja como
/// datos (jsonb) para que todos los jugadores vean el mismo tablero —
/// acá se genera localmente porque el modo Solo no tiene otros jugadores
/// con quien sincronizarlo.
class BoardLayout {
  BoardLayout._(this.casillas, this.trampolines);

  static const int meta = 29;

  final Map<int, TipoCasilla> casillas;
  final Map<int, InfoTrampolin> trampolines;

  TipoCasilla tipoDe(int posicion) {
    if (posicion <= 0) return TipoCasilla.normal;
    if (posicion >= meta) return TipoCasilla.meta;
    return casillas[posicion] ?? TipoCasilla.normal;
  }

  InfoTrampolin? infoTrampolinDe(int posicion) => trampolines[posicion];

  factory BoardLayout.generar({Random? random}) {
    final rng = random ?? Random();
    final posicionesDisponibles = List<int>.generate(28, (i) => i + 1)
      ..shuffle(rng);

    const reparto = <TipoCasilla, int>{
      TipoCasilla.oca: 6,
      TipoCasilla.minijuego: 6,
      TipoCasilla.trampolin: 3,
      TipoCasilla.carcel: 3,
      TipoCasilla.calavera: 2,
    };

    final casillas = <int, TipoCasilla>{};
    final trampolines = <int, InfoTrampolin>{};
    var cursor = 0;

    for (final entry in reparto.entries) {
      for (var i = 0; i < entry.value; i++) {
        final posicion = posicionesDisponibles[cursor++];
        casillas[posicion] = entry.key;
        if (entry.key == TipoCasilla.trampolin) {
          trampolines[posicion] = InfoTrampolin(avance: 2 + rng.nextInt(3)); // 2-4
        }
      }
    }

    return BoardLayout._(casillas, trampolines);
  }
}
