import 'dart:math';

import 'board_layout.dart';

/// Reglas puras de movimiento del tablero (sección 3 de la especificación).
class GameEngine {
  GameEngine(this.layout, {Random? random}) : _rng = random ?? Random();

  final BoardLayout layout;
  final Random _rng;

  int tirarDado() => 1 + _rng.nextInt(6);

  /// Calcula la posición final aplicando la regla de rebote real: si el
  /// dado te pasa de la meta, rebotás hacia atrás la diferencia.
  int calcularNuevaPosicion(int posActual, int dado) {
    final destino = posActual + dado;
    if (destino <= BoardLayout.meta) return destino;
    return 2 * BoardLayout.meta - destino;
  }

  /// Devuelve la secuencia completa de posiciones por las que pasa la
  /// ficha, casilla por casilla (para la animación de caminata), incluida
  /// la posición final. Contempla el rebote: la ficha camina hacia
  /// adelante hasta la meta y después retrocede el resto.
  List<int> secuenciaDePasos(int posActual, int dado) {
    final destino = posActual + dado;
    if (destino <= BoardLayout.meta) {
      return [for (var p = posActual + 1; p <= destino; p++) p];
    }
    final pasos = [
      for (var p = posActual + 1; p <= BoardLayout.meta; p++) p,
    ];
    final rebote = 2 * BoardLayout.meta - destino;
    pasos.addAll([for (var p = BoardLayout.meta - 1; p >= rebote; p--) p]);
    return pasos;
  }
}
