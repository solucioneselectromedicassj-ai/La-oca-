import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import 'widgets/estadisticas_juego.dart';

const _claveEstado = 'tateti';

const _lineasGanadoras = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8],
  [0, 4, 8], [2, 4, 6],
];

/// Ta-Te-Ti para los más chicos (queda solo para la franja "menor" de la
/// Zona de juegos, a partir de adolescentes se juega al Solitario) — con
/// dos modos: contra una IA simple (gana si puede, bloquea si hace
/// falta, si no juega el centro/esquina/al azar) o pasándose el celular
/// entre dos jugadores sin ninguna IA de por medio.
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
  bool _cargando = true;
  int _statsRefresco = 0;

  /// Dificultad elegible aparte del nivel por edad — pedido explícito:
  /// antes la oca jugaba siempre perfecto y era imposible ganarle.
  String _dificultad = 'medio'; // 'facil' | 'medio' | 'dificil'

  /// Modo de juego — pedido explícito: para los más chicos, poder elegir
  /// entre jugarle a la oca (con IA) o pasarse el celular entre dos
  /// personas sin ninguna inteligencia artificial de por medio.
  String _modo = 'oca'; // 'oca' | 'dosJugadores'

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final g = await PreferenciasService.obtenerEstadoJuego(_claveEstado);
    if (g != null) {
      _celdas = (g['celdas'] as List).map((v) => v as String?).toList();
      _turnoJugador = g['turnoJugador'] as bool;
      _ganador = g['ganador'] as String?;
      _lineaGanadora = (g['lineaGanadora'] as List?)?.map((v) => v as int).toList();
      _dificultad = g['dificultad'] as String? ?? 'medio';
      _modo = g['modo'] as String? ?? 'oca';
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardarEstado() {
    return PreferenciasService.guardarEstadoJuego(_claveEstado, {
      'celdas': _celdas,
      'turnoJugador': _turnoJugador,
      'ganador': _ganador,
      'lineaGanadora': _lineaGanadora,
      'dificultad': _dificultad,
      'modo': _modo,
    });
  }

  void _reiniciar() {
    setState(() {
      _celdas = List.filled(9, null);
      _turnoJugador = true;
      _ganador = null;
      _lineaGanadora = null;
      _premiado = false;
    });
    _guardarEstado();
  }

  void _elegirModo(String modo) {
    if (modo == _modo) return;
    setState(() => _modo = modo);
    _reiniciar();
  }

  void _tocar(int i) {
    if (_celdas[i] != null || _ganador != null) return;
    if (_modo == 'oca' && !_turnoJugador) return; // esperando a la oca
    setState(() => _celdas[i] = _turnoJugador ? 'X' : 'O');
    _resolverFin();
    if (_ganador != null) return;
    setState(() => _turnoJugador = !_turnoJugador);
    _guardarEstado();
    if (_modo == 'oca' && !_turnoJugador) {
      Timer(const Duration(milliseconds: 500), _jugadaOca);
    }
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
    // Se bajó el nivel de las tres dificultades (pedido explícito: "que
    // se parezca como oportunidad") — ni siquiera la difícil juega
    // perfecto ahora, para que siempre haya una chance real de ganar,
    // pensando sobre todo en que este juego lo van a usar chicos.
    switch (_dificultad) {
      case 'facil':
        // Nunca busca ganar ni bloquea a propósito: juega al azar, para
        // que se le pueda ganar sin problema.
        return libres[Random().nextInt(libres.length)];
      case 'medio':
        // Bloquea y busca ganar poco más de un tercio de las veces.
        if (Random().nextDouble() < 0.4) {
          final ganar = _buscarJugadaGanadora('O');
          if (ganar != null) return ganar;
        }
        if (Random().nextDouble() < 0.35) {
          final bloquear = _buscarJugadaGanadora('X');
          if (bloquear != null) return bloquear;
        }
        return libres[Random().nextInt(libres.length)];
      default: // dificil
        if (Random().nextDouble() < 0.8) {
          final ganar = _buscarJugadaGanadora('O');
          if (ganar != null) return ganar;
        }
        if (Random().nextDouble() < 0.75) {
          final bloquear = _buscarJugadaGanadora('X');
          if (bloquear != null) return bloquear;
        }
        if (_celdas[4] == null) return 4;
        return libres.firstWhere((i) => [0, 2, 6, 8].contains(i), orElse: () => libres[Random().nextInt(libres.length)]);
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
        _guardarEstado();
        _registrarFinDePartida(a);
        if (_modo == 'oca' && a == 'X') _premiar();
        return;
      }
    }
    if (_celdas.every((c) => c != null)) {
      setState(() => _ganador = 'empate');
      _guardarEstado();
      _registrarFinDePartida('empate');
    } else {
      _guardarEstado();
    }
  }

  /// Historial simple del juego — en modo "vs. la oca" una victoria es
  /// clara (ganó el jugador); en "2 jugadores" no hay a quién atribuírsela
  /// desde la app, así que solo se cuenta la partida jugada.
  void _registrarFinDePartida(String resultado) {
    final gano = _modo == 'oca' && resultado == 'X';
    PreferenciasService.registrarPartidaJuego(_claveEstado, gano: gano);
    if (mounted) setState(() => _statsRefresco++);
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  Widget _selectorModo() {
    const opciones = [('oca', '🪿 Vs. la oca'), ('dosJugadores', '👫 2 jugadores')];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(o.$2, style: const TextStyle(fontSize: 12)),
            selected: _modo == o.$1,
            selectedColor: AppColors.turquoise,
            backgroundColor: Colors.white,
            onSelected: (_) => _elegirModo(o.$1),
          ),
      ],
    );
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
            onSelected: (_) {
              setState(() => _dificultad = o.$1);
              _guardarEstado();
            },
          ),
      ],
    );
  }

  String _textoTurno() {
    if (_modo == 'oca') return _turnoJugador ? 'Tu turno (❌)' : 'Piensa la oca... (⭕)';
    return _turnoJugador ? 'Turno: Jugador 1 (❌)' : 'Turno: Jugador 2 (⭕)';
  }

  String _textoResultado() {
    if (_ganador == 'empate') return '🤝 ¡Empate!';
    if (_modo == 'oca') return _ganador == 'X' ? '🎉 ¡Ganaste!' : '😅 Ganó la oca';
    return _ganador == 'X' ? '🎉 ¡Ganó el Jugador 1!' : '🎉 ¡Ganó el Jugador 2!';
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
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _selectorModo(),
                    if (_modo == 'oca') ...[
                      const SizedBox(height: 8),
                      _selectorDificultad(),
                    ],
                    const SizedBox(height: 8),
                    EstadisticasJuego(juego: _claveEstado, refresco: _statsRefresco),
                    Text(
                      _ganador == null ? _textoTurno() : _textoResultado(),
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
