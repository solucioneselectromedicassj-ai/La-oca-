import 'dart:math';
import 'dart:ui';

/// Genera las posiciones (normalizadas 0..1) de las 30 casillas en un
/// camino serpenteante tipo "mapa de Candy Crush", en vez de una grilla
/// recta. Es una curva paramétrica (no calca ningún mapa puntual) para
/// que cualquier cantidad de casillas quede prolija automáticamente.
///
/// La forma exacta (amplitud, cantidad de curvas, hacia qué lado arranca)
/// varía cada vez que se genera, para que el camino no se vea siempre
/// igual entre partidas/etapas — igual que el layout de trampas.
class CaminoTablero {
  CaminoTablero._();

  static List<Offset> generar(int cantidad, {Random? random}) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];
    final rng = random ?? Random();

    final amplitud = 0.26 + rng.nextDouble() * 0.14; // 0.26 - 0.40
    final frecuencia = 2.0 + rng.nextDouble() * 1.6; // 2.0 - 3.6 curvas
    final direccion = rng.nextBool() ? 1 : -1;
    final faseInicial = rng.nextDouble() * 0.3;

    return List.generate(cantidad, (i) {
      final t = i / (cantidad - 1);
      final x = 0.5 +
          direccion * amplitud * sin((t + faseInicial) * frecuencia * pi);
      final y = 0.06 + 0.88 * t;
      return Offset(x, y);
    });
  }
}
