import 'dart:ui';

/// Posiciones de las 30 casillas del bloque Tensión (etapas 7-9) sobre
/// las piedras que ya están dibujadas en `fondo_lava.png` — el usuario
/// mandó la imagen con los 30 números ya puestos a mano sobre cada
/// piedra ("te ahorro el trabajo... identifiqué los números de las
/// casillas") para que las casillas del juego coincidan con el arte en
/// vez de flotar sueltas por cualquier lado.
///
/// Los puntos se leyeron directamente de esa imagen numerada (con una
/// grilla superpuesta). El original tenía dos números repetidos y al
/// "12" le faltaba lugar propio — se interpretó la piedra duplicada
/// entre el 11 y el 13 como el 12 (encaja en la secuencia), y el "3"
/// repetido suelto cerca del incio se descartó (una piedra de más,
/// decorativa, no forma parte de las 30).
///
/// El layout es siempre el mismo: son piedras dibujadas a mano en un
/// lugar fijo del arte, no pueden moverse. Lo que sí cambia por etapa
/// es qué trampa cae en cada una (`BoardLayout.generar`).
class TableroLava {
  TableroLava._();

  static const List<Offset> _puntos = [
    Offset(0.391, 0.747), // 1 · INICIO
    Offset(0.397, 0.710), // 2
    Offset(0.449, 0.666), // 3
    Offset(0.378, 0.646), // 4
    Offset(0.540, 0.687), // 5
    Offset(0.462, 0.642), // 6
    Offset(0.404, 0.610), // 7
    Offset(0.423, 0.553), // 8
    Offset(0.358, 0.537), // 9
    Offset(0.475, 0.529), // 10
    Offset(0.365, 0.509), // 11
    Offset(0.547, 0.416), // 12
    Offset(0.443, 0.505), // 13
    Offset(0.488, 0.351), // 14
    Offset(0.527, 0.327), // 15
    Offset(0.605, 0.319), // 16
    Offset(0.319, 0.323), // 17
    Offset(0.632, 0.270), // 18
    Offset(0.378, 0.250), // 19
    Offset(0.521, 0.242), // 20
    Offset(0.560, 0.249), // 21
    Offset(0.632, 0.242), // 22
    Offset(0.586, 0.179), // 23
    Offset(0.638, 0.170), // 24
    Offset(0.658, 0.212), // 25
    Offset(0.560, 0.208), // 26
    Offset(0.723, 0.172), // 27
    Offset(0.762, 0.144), // 28
    Offset(0.697, 0.136), // 29
    Offset(0.508, 0.158), // 30 · META, junto al portal
  ];

  static List<Offset> generar(int cantidad) {
    if (cantidad != _puntos.length) {
      // El tablero siempre pide 30; si algún día cambia la cantidad de
      // casillas, no tiene sentido devolver un layout fijo pensado
      // para 30 piedras puntuales.
      throw ArgumentError('TableroLava solo tiene posiciones para ${_puntos.length} casillas');
    }
    return List.of(_puntos);
  }
}
