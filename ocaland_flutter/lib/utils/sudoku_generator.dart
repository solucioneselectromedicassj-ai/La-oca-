/// Generador de sudokus de tamaño variable (4x4, 6x6, 9x9) con solución
/// única garantizada. Usa backtracking con heurística "menos candidatos
/// primero" (MRV) tanto para rellenar la grilla completa como para
/// contar soluciones al ir sacando números — eso lo hace rápido incluso
/// para 9x9 en el navegador, sin necesitar una librería externa.
class SudokuPuzzle {
  final int n;
  final int boxR;
  final int boxC;
  final List<List<int>> solucion; // 1..n, sin ceros
  final List<List<int>> pistas; // 1..n, con 0 = celda vacía para completar
  const SudokuPuzzle({required this.n, required this.boxR, required this.boxC, required this.solucion, required this.pistas});
}

class SudokuGenerator {
  SudokuGenerator._();

  static SudokuPuzzle generar({required int n, required int boxR, required int boxC, required int pistasObjetivo}) {
    final solucion = _generarSolucionCompleta(n, boxR, boxC);
    final puzzle = [for (final fila in solucion) List<int>.from(fila)];

    final celdas = [for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) (r, c)]..shuffle();
    var llenas = n * n;
    for (final (r, c) in celdas) {
      if (llenas <= pistasObjetivo) break;
      final valorAnterior = puzzle[r][c];
      puzzle[r][c] = 0;
      if (_contarSoluciones(puzzle, n, boxR, boxC, limite: 2) == 1) {
        llenas--;
      } else {
        puzzle[r][c] = valorAnterior;
      }
    }
    return SudokuPuzzle(n: n, boxR: boxR, boxC: boxC, solucion: solucion, pistas: puzzle);
  }

  static List<List<int>> _generarSolucionCompleta(int n, int boxR, int boxC) {
    final grid = List.generate(n, (_) => List.filled(n, 0));
    _resolver(grid, n, boxR, boxC, aleatorio: true);
    return grid;
  }

  /// Backtracking que en cada paso elige la celda vacía con menos
  /// candidatos posibles (MRV) — mucho más rápido que ir en orden fijo,
  /// clave para que generar/validar un 9x9 no trabe la UI.
  static bool _resolver(List<List<int>> grid, int n, int boxR, int boxC, {bool aleatorio = false}) {
    final celda = _celdaConMenosCandidatos(grid, n, boxR, boxC);
    if (celda == null) return true; // no quedan vacías: resuelto

    final (r, c) = celda;
    var candidatos = _candidatos(grid, n, boxR, boxC, r, c);
    if (aleatorio) candidatos = candidatos..shuffle();

    for (final v in candidatos) {
      grid[r][c] = v;
      if (_resolver(grid, n, boxR, boxC, aleatorio: aleatorio)) return true;
      grid[r][c] = 0;
    }
    return false;
  }

  static int _contarSoluciones(List<List<int>> grid, int n, int boxR, int boxC, {required int limite}) {
    final copia = [for (final fila in grid) List<int>.from(fila)];
    return _contar(copia, n, boxR, boxC, limite);
  }

  static int _contar(List<List<int>> grid, int n, int boxR, int boxC, int limite) {
    final celda = _celdaConMenosCandidatos(grid, n, boxR, boxC);
    if (celda == null) return 1;
    final (r, c) = celda;
    var total = 0;
    for (final v in _candidatos(grid, n, boxR, boxC, r, c)) {
      grid[r][c] = v;
      total += _contar(grid, n, boxR, boxC, limite - total);
      grid[r][c] = 0;
      if (total >= limite) break;
    }
    return total;
  }

  static (int, int)? _celdaConMenosCandidatos(List<List<int>> grid, int n, int boxR, int boxC) {
    (int, int)? mejor;
    var mejorCantidad = 999;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (grid[r][c] != 0) continue;
        final cantidad = _candidatos(grid, n, boxR, boxC, r, c).length;
        if (cantidad == 0) return (r, c); // sin salida: cortar rápido
        if (cantidad < mejorCantidad) {
          mejorCantidad = cantidad;
          mejor = (r, c);
          if (cantidad == 1) return mejor;
        }
      }
    }
    return mejor;
  }

  static List<int> _candidatos(List<List<int>> grid, int n, int boxR, int boxC, int r, int c) {
    final usados = <int>{};
    for (var i = 0; i < n; i++) {
      usados.add(grid[r][i]);
      usados.add(grid[i][c]);
    }
    final baseR = (r ~/ boxR) * boxR;
    final baseC = (c ~/ boxC) * boxC;
    for (var i = 0; i < boxR; i++) {
      for (var j = 0; j < boxC; j++) {
        usados.add(grid[baseR + i][baseC + j]);
      }
    }
    return [for (var v = 1; v <= n; v++) if (!usados.contains(v)) v];
  }
}
