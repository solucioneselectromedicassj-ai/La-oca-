import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/board_layout.dart';
import 'package:ocaland/game/game_engine.dart';

void main() {
  group('GameEngine.calcularNuevaPosicion', () {
    final engine = GameEngine(BoardLayout.generar());

    test('avanza directo cuando no pasa la meta', () {
      expect(engine.calcularNuevaPosicion(10, 4), 14);
    });

    test('llega exacto a la meta', () {
      expect(engine.calcularNuevaPosicion(24, 5), 29);
    });

    test('rebota hacia atrás si el dado pasa la meta', () {
      // pos 27 + dado 5 = destino 32, pasa la meta (29) por 3.
      // Regla: nuevaPos = 2*29 - 32 = 26.
      expect(engine.calcularNuevaPosicion(27, 5), 26);
    });

    test('rebote nunca da una posición negativa dentro de rango normal', () {
      expect(engine.calcularNuevaPosicion(29, 6), 23);
    });
  });

  group('GameEngine.secuenciaDePasos', () {
    final engine = GameEngine(BoardLayout.generar());

    test('secuencia simple sin rebote', () {
      expect(engine.secuenciaDePasos(10, 3), [11, 12, 13]);
    });

    test('secuencia con rebote camina hasta la meta y retrocede', () {
      // pos 27 + dado 5 -> pasos hasta 29 y después retrocede hasta 26.
      expect(engine.secuenciaDePasos(27, 5), [28, 29, 28, 27, 26]);
    });
  });
}
