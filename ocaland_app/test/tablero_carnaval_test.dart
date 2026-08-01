import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/tablero_carnaval.dart';

void main() {
  test('genera 30 puntos siguiendo el mosaico, dentro de rango razonable', () {
    final puntos = TableroCarnaval.generar(30);
    expect(puntos.length, 30);
    for (final p in puntos) {
      expect(p.dx, inInclusiveRange(0.0, 1.0));
      expect(p.dy, inInclusiveRange(0.0, 1.0));
    }
  });

  test('siempre genera el mismo recorrido (sigue un camino fijo de la imagen)', () {
    final a = TableroCarnaval.generar(30);
    final b = TableroCarnaval.generar(30);
    expect(a, b);
  });
}
