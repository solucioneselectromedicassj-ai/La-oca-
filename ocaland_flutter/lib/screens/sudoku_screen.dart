import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../theme/app_colors.dart';
import '../utils/sudoku_generator.dart';

class _Config {
  final int n;
  final int boxR;
  final int boxC;
  final int pistas;
  const _Config({required this.n, required this.boxR, required this.boxC, required this.pistas});
}

/// Config por nivel: se pidió explícitamente escalar la dificultad —
/// 4x4 para menores, 6x6 para adolescentes, 9x9 completo para adultos.
const _configPorNivel = <String, _Config>{
  'menor': _Config(n: 4, boxR: 2, boxC: 2, pistas: 10),
  'adolescente': _Config(n: 6, boxR: 2, boxC: 3, pistas: 20),
  'adulto': _Config(n: 9, boxR: 3, boxC: 3, pistas: 38),
};

/// Sudoku de tamaño según el nivel elegido en la Zona de juegos. El
/// tablero se genera al entrar (con solución única garantizada) y se
/// juega tocando una celda vacía y después un número del teclado de
/// abajo.
class SudokuScreen extends StatefulWidget {
  final String usuarioId;
  final String nivel; // 'menor' | 'adolescente' | 'adulto'
  const SudokuScreen({super.key, required this.usuarioId, required this.nivel});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late final _Config _config = _configPorNivel[widget.nivel] ?? _configPorNivel['adulto']!;
  SudokuPuzzle? _puzzle;
  List<List<int>> _grid = const [];
  late List<List<bool>> _fijas;
  int? _selR;
  int? _selC;
  bool _premiado = false;

  @override
  void initState() {
    super.initState();
    _generar();
  }

  void _generar() {
    setState(() {
      _puzzle = null;
      _selR = null;
      _selC = null;
      _premiado = false;
    });
    Future(() {
      final p = SudokuGenerator.generar(n: _config.n, boxR: _config.boxR, boxC: _config.boxC, pistasObjetivo: _config.pistas);
      if (!mounted) return;
      setState(() {
        _puzzle = p;
        _grid = [for (final fila in p.pistas) List<int>.from(fila)];
        _fijas = [for (final fila in p.pistas) [for (final v in fila) v != 0]];
      });
    });
  }

  bool _tieneConflicto(int r, int c) {
    final v = _grid[r][c];
    if (v == 0) return false;
    final n = _config.n;
    for (var i = 0; i < n; i++) {
      if (i != c && _grid[r][i] == v) return true;
      if (i != r && _grid[i][c] == v) return true;
    }
    final baseR = (r ~/ _config.boxR) * _config.boxR;
    final baseC = (c ~/ _config.boxC) * _config.boxC;
    for (var i = 0; i < _config.boxR; i++) {
      for (var j = 0; j < _config.boxC; j++) {
        final rr = baseR + i, cc = baseC + j;
        if ((rr != r || cc != c) && _grid[rr][cc] == v) return true;
      }
    }
    return false;
  }

  bool get _completo => _grid.every((fila) => fila.every((v) => v != 0));

  bool get _ganado {
    final sol = _puzzle?.solucion;
    if (sol == null || !_completo) return false;
    for (var r = 0; r < _config.n; r++) {
      for (var c = 0; c < _config.n; c++) {
        if (_grid[r][c] != sol[r][c]) return false;
      }
    }
    return true;
  }

  void _elegir(int v) {
    final r = _selR, c = _selC;
    if (r == null || c == null || _fijas[r][c]) return;
    setState(() => _grid[r][c] = v);
    if (_ganado) _premiar();
  }

  void _borrar() {
    final r = _selR, c = _selC;
    if (r == null || c == null || _fijas[r][c]) return;
    setState(() => _grid[r][c] = 0);
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🔢 Sudoku')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: _puzzle == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (_ganado)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text('🎉 ¡Lo resolviste!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                              child: GridView.count(
                                crossAxisCount: _config.n,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (var r = 0; r < _config.n; r++)
                                    for (var c = 0; c < _config.n; c++) _celda(r, c),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (!_ganado)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var v = 1; v <= _config.n; v++) _teclaNumero(v),
                                _teclaBorrar(),
                              ],
                            )
                          else
                            ElevatedButton(onPressed: _generar, child: const Text('🔁 Otro sudoku')),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _celda(int r, int c) {
    final v = _grid[r][c];
    final seleccionada = _selR == r && _selC == c;
    final fija = _fijas[r][c];
    final conflicto = v != 0 && _tieneConflicto(r, c);
    return GestureDetector(
      onTap: fija ? null : () => setState(() { _selR = r; _selC = c; }),
      child: Container(
        margin: EdgeInsets.only(
          right: (c + 1) % _config.boxC == 0 && c != _config.n - 1 ? 2 : 0.4,
          bottom: (r + 1) % _config.boxR == 0 && r != _config.n - 1 ? 2 : 0.4,
        ),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.turquoise.withValues(alpha: 0.35) : (fija ? AppColors.parchmentDark : Colors.white),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Text(
          v == 0 ? '' : '$v',
          style: TextStyle(
            fontSize: 18,
            fontWeight: fija ? FontWeight.bold : FontWeight.w600,
            color: conflicto ? AppColors.coral : AppColors.violetDark,
          ),
        ),
      ),
    );
  }

  Widget _teclaNumero(int v) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.violet,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _elegir(v),
          child: Center(child: Text('$v', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17))),
        ),
      ),
    );
  }

  Widget _teclaBorrar() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _borrar,
          child: const Center(child: Icon(Icons.backspace_outlined, color: Colors.white, size: 18)),
        ),
      ),
    );
  }
}
