import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../theme/app_colors.dart';

/// Tamaño de grilla por franja de edad — 8-puzzle (3x3) para menores,
/// el clásico 15-puzzle (4x4) para adolescentes, y una vuelta más
/// grande (5x5) para adultos.
const _tamanoPorNivel = <String, int>{
  'menor': 3,
  'adolescente': 4,
  'adulto': 5,
};

/// Rompecabezas deslizante clásico: tocá una ficha pegada al espacio
/// vacío para moverla ahí. El mezclado parte siempre del estado
/// resuelto y hace muchos movimientos válidos al azar, así que el
/// tablero es siempre resoluble (sin tener que calcular paridad).
class RompecabezasScreen extends StatefulWidget {
  final String usuarioId;
  final String nivel;
  const RompecabezasScreen({super.key, required this.usuarioId, required this.nivel});

  @override
  State<RompecabezasScreen> createState() => _RompecabezasScreenState();
}

class _RompecabezasScreenState extends State<RompecabezasScreen> {
  late final int _n = _tamanoPorNivel[widget.nivel] ?? 4;
  late List<int> _fichas; // 0 = espacio vacío, fila por fila
  int _movimientos = 0;
  bool _premiado = false;

  List<int> get _resuelto => [for (var i = 1; i < _n * _n; i++) i, 0];

  @override
  void initState() {
    super.initState();
    _mezclar();
  }

  void _mezclar() {
    _fichas = List<int>.from(_resuelto);
    final rnd = Random();
    var vacio = _fichas.indexOf(0);
    var anterior = -1;
    final pasos = _n * _n * 25;
    for (var i = 0; i < pasos; i++) {
      final vecinos = _vecinos(vacio).where((v) => v != anterior).toList();
      final destino = vecinos[rnd.nextInt(vecinos.length)];
      _fichas[vacio] = _fichas[destino];
      _fichas[destino] = 0;
      anterior = vacio;
      vacio = destino;
    }
    _movimientos = 0;
    _premiado = false;
    setState(() {});
  }

  List<int> _vecinos(int i) {
    final r = i ~/ _n, c = i % _n;
    final res = <int>[];
    if (r > 0) res.add(i - _n);
    if (r < _n - 1) res.add(i + _n);
    if (c > 0) res.add(i - 1);
    if (c < _n - 1) res.add(i + 1);
    return res;
  }

  bool get _gano => const ListEquality().equals(_fichas, _resuelto);

  void _tocar(int i) {
    if (_gano || _fichas[i] == 0) return;
    final vacio = _fichas.indexOf(0);
    if (!_vecinos(i).contains(vacio)) return;
    setState(() {
      _fichas[vacio] = _fichas[i];
      _fichas[i] = 0;
      _movimientos++;
    });
    if (_gano) _premiar();
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🧩 Rompecabezas')),
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
                    Text('Movimientos: $_movimientos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (_gano)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('🎉 ¡Lo armaste!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: GridView.count(
                          crossAxisCount: _n,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          children: [for (var i = 0; i < _n * _n; i++) _ficha(i)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(onPressed: _mezclar, child: Text(_gano ? '🔁 Jugar de nuevo' : '🔀 Mezclar de nuevo')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ficha(int i) {
    final v = _fichas[i];
    if (v == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _tocar(i),
      child: Container(
        decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('$v', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
    );
  }
}

/// Comparación simple de listas por valor — evita sumar el paquete
/// `collection` solo para esto.
class ListEquality {
  const ListEquality();
  bool equals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
