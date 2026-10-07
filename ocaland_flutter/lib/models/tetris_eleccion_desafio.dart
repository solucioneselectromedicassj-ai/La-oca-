import 'dart:math';

/// Mini-desafío "¿en qué columna encaja?" — versión de un solo toque del
/// Tetris para los juegos de espera: una fila de celdas con un único
/// hueco, hay que tocar el número de esa columna antes de que se acabe
/// el tiempo. Pedido explícito del usuario: variar los juegos de espera
/// (no siempre lo mismo) — una versión completa de Tetris (piezas
/// cayendo en tiempo real) no entra en una posta de pocos segundos, así
/// que esta es la versión "chica" pensada para ese hueco.
class TetrisEleccionDesafio {
  static const ancho = 5;
  final int columnaHueco;

  const TetrisEleccionDesafio({required this.columnaHueco});

  factory TetrisEleccionDesafio.aleatoria([Random? random]) {
    return TetrisEleccionDesafio(columnaHueco: (random ?? Random()).nextInt(ancho));
  }
}
