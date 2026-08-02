import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/tablero_lava.dart';

void main() {
  test('genera 30 puntos fijos sobre las piedras del arte, dentro de rango', () {
    final puntos = TableroLava.generar(30);
    expect(puntos.length, 30);
    for (final p in puntos) {
      expect(p.dx, inInclusiveRange(0.0, 1.0));
      expect(p.dy, inInclusiveRange(0.0, 1.0));
    }
    expect(puntos.first.dy, greaterThan(puntos.last.dy));
  });

  test('siempre da el mismo layout (piedras dibujadas a mano, no cambian)', () {
    expect(TableroLava.generar(30), TableroLava.generar(30));
  });

  test('tira error si le piden una cantidad distinta de 30', () {
    expect(() => TableroLava.generar(28), throwsArgumentError);
  });
}
