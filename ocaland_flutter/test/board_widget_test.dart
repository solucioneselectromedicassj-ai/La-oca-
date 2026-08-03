import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/board_layout.dart';
import 'package:ocaland_flutter/screens/widgets/board_widget.dart';

void main() {
  group('boardShapeForEtapa', () {
    test('agrupa de a 3 etapas y varía la forma (no monótono)', () {
      expect(boardShapeForEtapa(1), boardShapeForEtapa(2));
      expect(boardShapeForEtapa(2), boardShapeForEtapa(3));
      expect(boardShapeForEtapa(3), isNot(boardShapeForEtapa(4)));
      expect(boardShapeForEtapa(4), boardShapeForEtapa(5));
      expect(boardShapeForEtapa(6), isNot(boardShapeForEtapa(7)));
    });
  });

  group('buildBoardFractions', () {
    for (final shape in BoardShape.values) {
      test('$shape: genera 30 casillas únicas, dentro de la grilla, formando un sendero continuo', () {
        final fractions = buildBoardFractions(shape);
        expect(fractions.length, BoardEngine.totalCells);

        // únicas (sin superposición entre casillas)
        expect(fractions.toSet().length, fractions.length);

        // dentro de la grilla visual de 8x8
        for (final f in fractions) {
          expect(f.dx, greaterThanOrEqualTo(0));
          expect(f.dy, greaterThanOrEqualTo(0));
          expect(f.dx, lessThan(1));
          expect(f.dy, lessThan(1));
        }

        // sendero continuo: cada casilla es adyacente (no diagonal) a la siguiente
        const cellFrac = 1 / 8;
        for (var i = 1; i < fractions.length; i++) {
          final dx = ((fractions[i].dx - fractions[i - 1].dx) / cellFrac).round().abs();
          final dy = ((fractions[i].dy - fractions[i - 1].dy) / cellFrac).round().abs();
          expect(dx + dy, 1, reason: 'casilla $i no es adyacente a la anterior');
        }
      });
    }
  });
}
