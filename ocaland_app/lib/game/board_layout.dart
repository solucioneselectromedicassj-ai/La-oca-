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

  static const reparto = <TipoCasilla, int>{
    TipoCasilla.oca: 6,
    TipoCasilla.minijuego: 6,
    TipoCasilla.trampolin: 3,
    TipoCasilla.carcel: 3,
    TipoCasilla.calavera: 2,
  };

  /// El trampolín adelanta 2-4 casillas de entrada: si dos quedaran a
  /// menos de 5 casillas de distancia, caer en uno podría mandarte
  /// directo a otro (encadenados), lo cual no tiene lógica de juego —
  /// el usuario lo marcó explícitamente. Se exige esta separación
  /// mínima entre cualquier par de trampolines del layout.
  static const int _separacionMinimaTrampolines = 5;

  factory BoardLayout.generar({Random? random}) {
    final rng = random ?? Random();

    var casillas = <int, TipoCasilla>{};
    var trampolines = <int, InfoTrampolin>{};

    for (var intento = 0; intento < 300; intento++) {
      final posicionesDisponibles = List<int>.generate(28, (i) => i + 1)
        ..shuffle(rng);

      casillas = {};
      trampolines = {};
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

      if (_trampolinesBienEspaciados(trampolines.keys)) break;
    }

    return BoardLayout._(casillas, trampolines);
  }

  static bool _trampolinesBienEspaciados(Iterable<int> posiciones) {
    final lista = posiciones.toList();
    for (var i = 0; i < lista.length; i++) {
      for (var j = i + 1; j < lista.length; j++) {
        if ((lista[i] - lista[j]).abs() < _separacionMinimaTrampolines) return false;
      }
    }
    return true;
  }
}
