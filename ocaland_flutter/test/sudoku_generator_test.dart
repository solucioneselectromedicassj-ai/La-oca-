import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/utils/sudoku_generator.dart';

bool _esGrillaValida(List<List<int>> grid, int n, int boxR, int boxC) {
  for (var i = 0; i < n; i++) {
    final fila = <int>{};
    final col = <int>{};
    for (var j = 0; j < n; j++) {
      if (!fila.add(grid[i][j])) return false;
      if (!col.add(grid[j][i])) return false;
    }
    if (fila.length != n || col.length != n) return false;
  }
  for (var br = 0; br < n; br += boxR) {
    for (var bc = 0; bc < n; bc += boxC) {
      final caja = <int>{};
      for (var i = 0; i < boxR; i++) {
        for (var j = 0; j < boxC; j++) {
          if (!caja.add(grid[br + i][bc + j])) return false;
        }
      }
      if (caja.length != n) return false;
    }
  }
  return true;
}

void main() {
  group('SudokuGenerator', () {
    final tamanos = [(4, 2, 2, 10), (6, 2, 3, 20), (9, 3, 3, 38)];

    for (final (n, boxR, boxC, pistas) in tamanos) {
      test('genera un $n' 'x$n con solución completa y válida (filas/columnas/cajas sin repetidos)', () {
        final puzzle = SudokuGenerator.generar(n: n, boxR: boxR, boxC: boxC, pistasObjetivo: pistas);
        expect(puzzle.solucion.length, n);
        expect(puzzle.solucion.every((f) => f.length == n), isTrue);
        expect(_esGrillaValida(puzzle.solucion, n, boxR, boxC), isTrue);
      });

      test('el tablero de pistas ($n' 'x$n) coincide con la solución en las celdas ya reveladas', () {
        final puzzle = SudokuGenerator.generar(n: n, boxR: boxR, boxC: boxC, pistasObjetivo: pistas);
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < n; c++) {
            if (puzzle.pistas[r][c] != 0) {
              expect(puzzle.pistas[r][c], puzzle.solucion[r][c]);
            }
          }
        }
      });
    }
  });
}
