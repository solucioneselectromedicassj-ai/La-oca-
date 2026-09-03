import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import '../utils/sudoku_generator.dart';
import 'widgets/estadisticas_juego.dart';

const _claveEstado = 'sudoku';

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
  int _segundos = 0;
  bool _mostrarTiempo = true;
  int _statsRefresco = 0;
  Timer? _ticker;

  // El tamaño real de la grilla en pantalla tiene que salir siempre del
  // puzzle efectivamente cargado o generado (que puede venir de una
  // partida guardada con OTRO nivel/dificultad que el actual), nunca de
  // `_config` directamente — si no, un sudoku guardado en un nivel y
  // reabierto luego de cambiar de nivel se ve roto/incompleto.
  int get _n => _puzzle?.n ?? _config.n;
  int get _boxR => _puzzle?.boxR ?? _config.boxR;
  int get _boxC => _puzzle?.boxC ?? _config.boxC;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _cargarEstado() async {
    _mostrarTiempo = await PreferenciasService.obtenerMostrarTiempo();
    final g = await PreferenciasService.obtenerEstadoJuego(_claveEstado);
    if (g != null && g['solucion'] != null) {
      List<List<int>> aInt(dynamic v) => (v as List).map((f) => (f as List).map((x) => x as int).toList()).toList();
      final p = SudokuPuzzle(n: g['n'] as int, boxR: g['boxR'] as int, boxC: g['boxC'] as int, solucion: aInt(g['solucion']), pistas: aInt(g['pistas']));
      _grid = aInt(g['grid']);
      _fijas = [for (final fila in p.pistas) [for (final v in fila) v != 0]];
      _premiado = g['premiado'] as bool? ?? false;
      _segundos = g['segundos'] as int? ?? 0;
      if (mounted) setState(() => _puzzle = p);
      _iniciarTicker();
    } else {
      _generar();
    }
  }

  Future<void> _guardarEstado() {
    final p = _puzzle;
    if (p == null) return Future.value();
    return PreferenciasService.guardarEstadoJuego(_claveEstado, {
      'n': p.n,
      'boxR': p.boxR,
      'boxC': p.boxC,
      'solucion': p.solucion,
      'pistas': p.pistas,
      'grid': _grid,
      'premiado': _premiado,
      'segundos': _segundos,
    });
  }

  void _iniciarTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _puzzle == null || _ganado) return;
      setState(() => _segundos++);
    });
  }

  void _generar() {
    setState(() {
      _puzzle = null;
      _selR = null;
      _selC = null;
      _premiado = false;
      _segundos = 0;
    });
    Future(() {
      final p = SudokuGenerator.generar(n: _config.n, boxR: _config.boxR, boxC: _config.boxC, pistasObjetivo: _config.pistas);
      if (!mounted) return;
      setState(() {
        _puzzle = p;
        _grid = [for (final fila in p.pistas) List<int>.from(fila)];
        _fijas = [for (final fila in p.pistas) [for (final v in fila) v != 0]];
      });
      _guardarEstado();
      _iniciarTicker();
    });
  }

  Future<void> _reiniciarPuzzle() async {
    final p = _puzzle;
    if (p == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reiniciar el sudoku?'),
        content: const Text('Se borran los números que pusiste (las pistas quedan igual).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reiniciar')),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() {
      _grid = [for (final fila in p.pistas) List<int>.from(fila)];
      _selR = null;
      _selC = null;
      _premiado = false;
      _segundos = 0;
    });
    _guardarEstado();
    _iniciarTicker();
  }

  Future<void> _alternarMostrarTiempo() async {
    final nuevo = !_mostrarTiempo;
    await PreferenciasService.guardarMostrarTiempo(nuevo);
    if (mounted) setState(() => _mostrarTiempo = nuevo);
  }

  String _formatearTiempo(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  bool _tieneConflicto(int r, int c) {
    final v = _grid[r][c];
    if (v == 0) return false;
    final n = _n;
    for (var i = 0; i < n; i++) {
      if (i != c && _grid[r][i] == v) return true;
      if (i != r && _grid[i][c] == v) return true;
    }
    final baseR = (r ~/ _boxR) * _boxR;
    final baseC = (c ~/ _boxC) * _boxC;
    for (var i = 0; i < _boxR; i++) {
      for (var j = 0; j < _boxC; j++) {
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
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] != sol[r][c]) return false;
      }
    }
    return true;
  }

  void _elegir(int v) {
    final r = _selR, c = _selC;
    if (r == null || c == null || _fijas[r][c]) return;
    setState(() => _grid[r][c] = v);
    _guardarEstado();
    if (_ganado) _premiar();
  }

  void _borrar() {
    final r = _selR, c = _selC;
    if (r == null || c == null || _fijas[r][c]) return;
    setState(() => _grid[r][c] = 0);
    _guardarEstado();
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    _ticker?.cancel();
    _guardarEstado();
    await PreferenciasService.registrarPartidaJuego(_claveEstado, gano: true, tiempoSegundos: _segundos);
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
    if (mounted) setState(() => _statsRefresco++);
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
                          EstadisticasJuego(juego: _claveEstado, refresco: _statsRefresco),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _alternarMostrarTiempo,
                                child: Text(
                                  _mostrarTiempo ? '⏱️ ${_formatearTiempo(_segundos)}' : '⏱️ oculto',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: _reiniciarPuzzle,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  child: const Text('🔁 Reiniciar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                                crossAxisCount: _n,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (var r = 0; r < _n; r++)
                                    for (var c = 0; c < _n; c++) _celda(r, c),
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
                                for (var v = 1; v <= _n; v++) _teclaNumero(v),
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

    // Líneas gruesas y oscuras entre cajas, apenas visibles adentro de
    // cada caja, y un tinte alternado por caja bien marcado (no solo un
    // matiz sutil) — pedido explícito: "remarcar los cuadraditos para
    // saber cuál es cada uno". Además, un numerito 1..9 (según el
    // tamaño) en la esquina de la primera celda de cada caja, a modo de
    // referencia — como en las guías de sudoku impresas.
    const colorCaja = AppColors.violetDark;
    final colorFina = AppColors.violet.withValues(alpha: 0.18);
    final bordeDerecho = (c + 1) % _boxC == 0;
    final bordeAbajo = (r + 1) % _boxR == 0;
    final boxColsCount = _n ~/ _boxC;
    final numeroCaja = (r ~/ _boxR) * boxColsCount + (c ~/ _boxC) + 1;
    final cajaPar = numeroCaja % 2 == 0;
    final esInicioDeCaja = r % _boxR == 0 && c % _boxC == 0;

    return GestureDetector(
      onTap: fija ? null : () => setState(() { _selR = r; _selC = c; }),
      child: Container(
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.turquoise.withValues(alpha: 0.35) : (cajaPar ? Colors.white : AppColors.violet.withValues(alpha: 0.14)),
          border: Border(
            top: r == 0 ? const BorderSide(color: colorCaja, width: 2.5) : BorderSide.none,
            left: c == 0 ? const BorderSide(color: colorCaja, width: 2.5) : BorderSide.none,
            right: BorderSide(color: bordeDerecho ? colorCaja : colorFina, width: bordeDerecho ? 2.5 : 0.6),
            bottom: BorderSide(color: bordeAbajo ? colorCaja : colorFina, width: bordeAbajo ? 2.5 : 0.6),
          ),
        ),
        child: Stack(
          children: [
            if (esInicioDeCaja)
              Positioned(
                top: 1,
                left: 2,
                child: Text('$numeroCaja', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.violetDark.withValues(alpha: 0.4))),
              ),
            Center(
              child: Text(
                v == 0 ? '' : '$v',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: fija ? FontWeight.bold : FontWeight.w600,
                  color: conflicto ? AppColors.coral : AppColors.violetDark,
                ),
              ),
            ),
          ],
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
