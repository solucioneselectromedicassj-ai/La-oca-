import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../theme/app_colors.dart';

const _lineasGanadoras = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8],
  [0, 4, 8], [2, 4, 6],
];

/// Ta-Te-Ti contra una IA simple (gana si puede, bloquea si hace falta,
/// si no juega el centro/esquina/al azar) — parte de la Zona de juegos
/// nueva que reemplaza a los minijuegos de reflejos/memoria en "Jugar
/// con ella" (esos siguen existiendo en el tablero y en Bonus).
class TatetiScreen extends StatefulWidget {
  final String usuarioId;
  const TatetiScreen({super.key, required this.usuarioId});

  @override
  State<TatetiScreen> createState() => _TatetiScreenState();
}

class _TatetiScreenState extends State<TatetiScreen> {
  List<String?> _celdas = List.filled(9, null);
  bool _turnoJugador = true;
  String? _ganador; // 'X' | 'O' | 'empate' | null
  List<int>? _lineaGanadora;
  bool _premiado = false;

  /// Dificultad elegible aparte del nivel por edad — pedido explícito:
  /// antes la oca jugaba siempre perfecto y era imposible ganarle.
  String _dificultad = 'medio'; // 'facil' | 'medio' | 'dificil'

  void _reiniciar() {
    setState(() {
      _celdas = List.filled(9, null);
      _turnoJugador = true;
      _ganador = null;
      _lineaGanadora = null;
      _premiado = false;
    });
  }

  void _tocar(int i) {
    if (!_turnoJugador || _celdas[i] != null || _ganador != null) return;
    setState(() => _celdas[i] = 'X');
    _resolverFin();
    if (_ganador != null) return;
    setState(() => _turnoJugador = false);
    Timer(const Duration(milliseconds: 500), _jugadaOca);
  }

  void _jugadaOca() {
    if (!mounted || _ganador != null) return;
    final libres = [for (var i = 0; i < 9; i++) if (_celdas[i] == null) i];
    if (libres.isEmpty) return;

    final elegido = _elegirJugada(libres);

    setState(() {
      _celdas[elegido] = 'O';
      _turnoJugador = true;
    });
    _resolverFin();
  }

  int _elegirJugada(List<int> libres) {
    switch (_dificultad) {
      case 'facil':
        // Nunca busca ganar ni bloquea a propósito: juega al azar, para
        // que se le pueda ganar sin problema.
        return libres[Random().nextInt(libres.length)];
      case 'medio':
        // Gana si puede, pero solo bloquea la mitad de las veces — se
        // puede ganar, pero hay que jugar con algo de cabeza.
        final ganar = _buscarJugadaGanadora('O');
        if (ganar != null) return ganar;
        if (Random().nextBool()) {
          final bloquear = _buscarJugadaGanadora('X');
          if (bloquear != null) return bloquear;
        }
        return libres[Random().nextInt(libres.length)];
      default: // dificil
        int? elegido = _buscarJugadaGanadora('O') ?? _buscarJugadaGanadora('X');
        elegido ??= _celdas[4] == null ? 4 : null;
        elegido ??= libres.firstWhere((i) => [0, 2, 6, 8].contains(i), orElse: () => libres[Random().nextInt(libres.length)]);
        return elegido;
    }
  }

  int? _buscarJugadaGanadora(String simbolo) {
    for (final linea in _lineasGanadoras) {
      final valores = linea.map((i) => _celdas[i]).toList();
      if (valores.where((v) => v == simbolo).length == 2 && valores.contains(null)) {
        return linea[valores.indexOf(null)];
      }
    }
    return null;
  }

  void _resolverFin() {
    for (final linea in _lineasGanadoras) {
      final a = _celdas[linea[0]], b = _celdas[linea[1]], c = _celdas[linea[2]];
      if (a != null && a == b && b == c) {
        setState(() {
          _ganador = a;
          _lineaGanadora = linea;
        });
        if (a == 'X') _premiar();
        return;
      }
    }
    if (_celdas.every((c) => c != null)) {
      setState(() => _ganador = 'empate');
    }
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  Widget _selectorDificultad() {
    const opciones = [('facil', '😌 Fácil'), ('medio', '🙂 Medio'), ('dificil', '😤 Difícil')];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(o.$2, style: const TextStyle(fontSize: 12)),
            selected: _dificultad == o.$1,
            selectedColor: AppColors.gold,
            backgroundColor: Colors.white,
            onSelected: (_) => setState(() => _dificultad = o.$1),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('❌⭕ Ta-Te-Ti')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _selectorDificultad(),
                    const SizedBox(height: 10),
                    Text(
                      _ganador == null
                          ? (_turnoJugador ? 'Tu turno (❌)' : 'Piensa la oca... (⭕)')
                          : _ganador == 'empate'
                              ? '🤝 ¡Empate!'
                              : _ganador == 'X'
                                  ? '🎉 ¡Ganaste!'
                                  : '😅 Ganó la oca',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          children: [
                            for (var i = 0; i < 9; i++)
                              GestureDetector(
                                onTap: () => _tocar(i),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (_lineaGanadora?.contains(i) ?? false) ? AppColors.gold.withValues(alpha: 0.4) : AppColors.parchmentDark,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _celdas[i] ?? '',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _celdas[i] == 'X' ? AppColors.violetDark : AppColors.coral),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_ganador != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: _reiniciar, child: const Text('🔁 Jugar de nuevo')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
