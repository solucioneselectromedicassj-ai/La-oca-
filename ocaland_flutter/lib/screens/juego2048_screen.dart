import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../theme/app_colors.dart';

const _n = 4;

/// Metas del nivel según la franja de edad — se pidió explícitamente
/// "niveles" para el 2048; acá cada meta alcanzada se festeja sin
/// reiniciar el tablero (como en el 2048 de siempre, que te deja seguir
/// jugando después de llegar a la ficha objetivo).
const _metasPorNivel = <String, List<int>>{
  'menor': [64, 128, 256],
  'adolescente': [128, 256, 512, 1024],
  'adulto': [256, 512, 1024, 2048],
};

const _coloresFicha = <int, Color>{
  2: Color(0xFFFFF3E0),
  4: Color(0xFFFFE0B2),
  8: AppColors.amber,
  16: AppColors.coral,
  32: Color(0xFFFF5252),
  64: AppColors.magenta,
  128: AppColors.indigo,
  256: AppColors.sky,
  512: AppColors.turquoise,
  1024: AppColors.green,
  2048: AppColors.gold,
};

class Juego2048Screen extends StatefulWidget {
  final String usuarioId;
  final String nivel;
  const Juego2048Screen({super.key, required this.usuarioId, required this.nivel});

  @override
  State<Juego2048Screen> createState() => _Juego2048ScreenState();
}

class _Juego2048ScreenState extends State<Juego2048Screen> {
  late final List<int> _metas = _metasPorNivel[widget.nivel] ?? _metasPorNivel['adulto']!;
  late List<List<int>> _grid;
  final _rnd = Random();
  final Set<int> _metasCelebradas = {};
  bool _premiado = false;
  bool _perdiste = false;

  @override
  void initState() {
    super.initState();
    _nuevaPartida();
  }

  void _nuevaPartida() {
    _grid = List.generate(_n, (_) => List.filled(_n, 0));
    _metasCelebradas.clear();
    _premiado = false;
    _perdiste = false;
    _agregarFicha();
    _agregarFicha();
    setState(() {});
  }

  void _agregarFicha() {
    final vacias = [for (var r = 0; r < _n; r++) for (var c = 0; c < _n; c++) if (_grid[r][c] == 0) (r, c)];
    if (vacias.isEmpty) return;
    final (r, c) = vacias[_rnd.nextInt(vacias.length)];
    _grid[r][c] = _rnd.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _colapsarFila(List<int> fila) {
    final valores = fila.where((v) => v != 0).toList();
    final resultado = <int>[];
    var i = 0;
    while (i < valores.length) {
      if (i + 1 < valores.length && valores[i] == valores[i + 1]) {
        resultado.add(valores[i] * 2);
        i += 2;
      } else {
        resultado.add(valores[i]);
        i++;
      }
    }
    while (resultado.length < _n) {
      resultado.add(0);
    }
    return resultado;
  }

  bool _mover(String direccion) {
    final antes = [for (final fila in _grid) List<int>.from(fila)];
    List<List<int>> nueva;

    switch (direccion) {
      case 'izquierda':
        nueva = [for (final fila in _grid) _colapsarFila(fila)];
        break;
      case 'derecha':
        nueva = [for (final fila in _grid) _colapsarFila(fila.reversed.toList()).reversed.toList()];
        break;
      case 'arriba':
        final t = _transponer(_grid);
        nueva = _transponer([for (final fila in t) _colapsarFila(fila)]);
        break;
      default: // abajo
        final t = _transponer(_grid);
        nueva = _transponer([for (final fila in t) _colapsarFila(fila.reversed.toList()).reversed.toList()]);
    }

    final cambio = _tableroDistinto(antes, nueva);
    if (cambio) {
      _grid = nueva;
      _agregarFicha();
      _revisarMetas();
      if (_sinMovimientos()) _perdiste = true;
      setState(() {});
    }
    return cambio;
  }

  List<List<int>> _transponer(List<List<int>> g) {
    return [for (var c = 0; c < _n; c++) [for (var r = 0; r < _n; r++) g[r][c]]];
  }

  bool _tableroDistinto(List<List<int>> a, List<List<int>> b) {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (a[r][c] != b[r][c]) return true;
      }
    }
    return false;
  }

  bool _sinMovimientos() {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] == 0) return false;
        if (c < _n - 1 && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r < _n - 1 && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  int get _maximaFicha => _grid.expand((f) => f).fold(0, max);

  void _revisarMetas() {
    final maxima = _maximaFicha;
    for (final meta in _metas) {
      if (maxima >= meta && !_metasCelebradas.contains(meta)) {
        _metasCelebradas.add(meta);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 ¡Llegaste a $meta!'), duration: const Duration(seconds: 2)));
        });
        if (!_premiado) _premiar();
      }
    }
  }

  Future<void> _premiar() async {
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  @override
  Widget build(BuildContext context) {
    final metaFinal = _metas.last;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🎯 2048')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Meta final del nivel: $metaFinal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Mejor ficha: $_maximaFicha', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                    const SizedBox(height: 10),
                    if (_perdiste)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('😅 No quedan movimientos.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    GestureDetector(
                      onHorizontalDragEnd: (d) {
                        final v = d.primaryVelocity ?? 0;
                        if (v.abs() < 80) return;
                        _mover(v > 0 ? 'derecha' : 'izquierda');
                      },
                      onVerticalDragEnd: (d) {
                        final v = d.primaryVelocity ?? 0;
                        if (v.abs() < 80) return;
                        _mover(v > 0 ? 'abajo' : 'arriba');
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.violetDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: GridView.count(
                            crossAxisCount: _n,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            children: [for (var r = 0; r < _n; r++) for (var c = 0; c < _n; c++) _celda(_grid[r][c])],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Deslizá el dedo sobre el tablero, o usá las flechas 👇', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    _controlesFlechas(),
                    const SizedBox(height: 14),
                    if (_perdiste) ElevatedButton(onPressed: _nuevaPartida, child: const Text('🔁 Jugar de nuevo')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _celda(int v) {
    return Container(
      decoration: BoxDecoration(color: v == 0 ? Colors.white.withValues(alpha: 0.5) : (_coloresFicha[v] ?? AppColors.violetDark), borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: v == 0
          ? null
          : Text(
              '$v',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: v >= 1000 ? 16 : 20, color: v <= 4 ? AppColors.violetDark : Colors.white),
            ),
    );
  }

  Widget _controlesFlechas() {
    Widget boton(IconData icono, String direccion) => SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => _mover(direccion), child: Icon(icono, color: Colors.white)),
          ),
        );
    return Column(
      children: [
        boton(Icons.keyboard_arrow_up, 'arriba'),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            boton(Icons.keyboard_arrow_left, 'izquierda'),
            const SizedBox(width: 6),
            boton(Icons.keyboard_arrow_down, 'abajo'),
            const SizedBox(width: 6),
            boton(Icons.keyboard_arrow_right, 'derecha'),
          ],
        ),
      ],
    );
  }
}
