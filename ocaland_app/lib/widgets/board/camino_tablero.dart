import 'dart:math';
import 'dart:ui';

/// Genera las posiciones (normalizadas 0..1) de las 30 casillas en un
/// camino serpenteante tipo "mapa de Candy Crush", en vez de una grilla
/// recta. Es una curva paramétrica (no calca ningún mapa puntual) para
/// que cualquier cantidad de casillas quede prolija automáticamente.
class CaminoTablero {
  CaminoTablero._();

  static List<Offset> generar(int cantidad) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];
    return List.generate(cantidad, (i) {
      final t = i / (cantidad - 1);
      final x = 0.5 + 0.36 * sin(t * 2.6 * pi);
      final y = 0.06 + 0.88 * t;
      return Offset(x, y);
    });
  }
}
