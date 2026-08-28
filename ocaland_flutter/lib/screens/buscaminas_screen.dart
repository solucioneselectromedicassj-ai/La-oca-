import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';

class _NivelConfig {
  final int filas;
  final int columnas;
  final int minas;
  const _NivelConfig(this.filas, this.columnas, this.minas);
}

/// Niveles por franja de edad — el tamaño de grilla queda fijo dentro de
/// cada franja (para que las celdas se sigan pudiendo tocar bien en el
/// celular) y lo que escala con cada victoria es la cantidad de minas.
/// Pedido explícito: sencillo para menores, y niveles que van subiendo
/// para los demás.
const _nivelesPorTier = <String, List<_NivelConfig>>{
  'menor': [_NivelConfig(6, 6, 5)],
  'adolescente': [_NivelConfig(7, 7, 6), _NivelConfig(7, 7, 9), _NivelConfig(7, 7, 12)],
  'adulto': [
    _NivelConfig(9, 9, 10),
    _NivelConfig(9, 9, 14),
    _NivelConfig(9, 9, 18),
    _NivelConfig(9, 9, 22),
    _NivelConfig(9, 9, 26),
  ],
};

enum _Estado { jugando, ganaste, perdiste }

/// Buscaminas clásico: el primer toque siempre es seguro (las minas se
/// reparten recién después, evitando esa celda y sus vecinas), toque
/// largo para marcar bandera. Ganar un nivel desbloquea el siguiente
/// dentro de la franja de edad.
class BuscaminasScreen extends StatefulWidget {
  final String usuarioId;
  final String nivel; // 'menor' | 'adolescente' | 'adulto'
  const BuscaminasScreen({super.key, required this.usuarioId, required this.nivel});

  @override
  State<BuscaminasScreen> createState() => _BuscaminasScreenState();
}

class _BuscaminasScreenState extends State<BuscaminasScreen> {
  late final List<_NivelConfig> _niveles = _nivelesPorTier[widget.nivel] ?? _nivelesPorTier['adulto']!;
  int _nivelActual = 0;

  List<List<bool>> _minas = [];
  List<List<bool>> _reveladas = [];
  List<List<bool>> _banderas = [];
  List<List<int>> _adyacentes = [];
  bool _minasColocadas = false;
  _Estado _estado = _Estado.jugando;
  bool _premiado = false;
  bool _cargando = true;

  _NivelConfig get _config => _niveles[_nivelActual];

  // El tamaño real del tablero en pantalla tiene que salir siempre de la
  // grilla efectivamente cargada (que puede venir de una partida
  // guardada en OTRA franja de edad que la actual), nunca de `_config`
  // directamente — si no, un buscaminas guardado y reabierto luego de
  // cambiar de nivel queda con dimensiones que no coinciden con los
  // arreglos guardados.
  int get _filas => _minas.isNotEmpty ? _minas.length : _config.filas;
  int get _columnas => _minas.isNotEmpty ? _minas.first.length : _config.columnas;
  int get _totalMinas => _minasColocadas ? _minas.expand((f) => f).where((m) => m).length : _config.minas;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final g = await PreferenciasService.obtenerEstadoJuego('buscaminas');
    if (g != null && g['minas'] != null) {
      _nivelActual = (g['nivelActual'] as int).clamp(0, _niveles.length - 1);
      List<List<bool>> aBool(dynamic v) => (v as List).map((f) => (f as List).map((x) => x as bool).toList()).toList();
      _minas = aBool(g['minas']);
      _reveladas = aBool(g['reveladas']);
      _banderas = aBool(g['banderas']);
      _adyacentes = (g['adyacentes'] as List).map((f) => (f as List).map((x) => x as int).toList()).toList();
      _minasColocadas = g['minasColocadas'] as bool;
      _estado = _Estado.values[g['estado'] as int];
      _premiado = g['premiado'] as bool? ?? false;
    } else {
      _generarNueva();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardarEstado() {
    return PreferenciasService.guardarEstadoJuego('buscaminas', {
      'nivelActual': _nivelActual,
      'minas': _minas,
      'reveladas': _reveladas,
      'banderas': _banderas,
      'adyacentes': _adyacentes,
      'minasColocadas': _minasColocadas,
      'estado': _estado.index,
      'premiado': _premiado,
    });
  }

  void _generarNueva() {
    final f = _config.filas, c = _config.columnas;
    _minas = List.generate(f, (_) => List.filled(c, false));
    _reveladas = List.generate(f, (_) => List.filled(c, false));
    _banderas = List.generate(f, (_) => List.filled(c, false));
    _adyacentes = List.generate(f, (_) => List.filled(c, 0));
    _minasColocadas = false;
    _estado = _Estado.jugando;
    _premiado = false;
  }

  void _reiniciar() {
    setState(_generarNueva);
    _guardarEstado();
  }

  void _colocarMinas(int rSeguro, int cSeguro) {
    final f = _filas, c = _columnas;
    final prohibidas = <String>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        prohibidas.add('${rSeguro + dr},${cSeguro + dc}');
      }
    }
    final rnd = Random();
    var colocadas = 0;
    final minasObjetivo = _config.minas.clamp(0, f * c - prohibidas.length);
    while (colocadas < minasObjetivo) {
      final r = rnd.nextInt(f);
      final cc = rnd.nextInt(c);
      if (_minas[r][cc] || prohibidas.contains('$r,$cc')) continue;
      _minas[r][cc] = true;
      colocadas++;
    }
    for (var r = 0; r < f; r++) {
      for (var cc = 0; cc < c; cc++) {
        if (_minas[r][cc]) continue;
        var n = 0;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final rr = r + dr, ccc = cc + dc;
            if (rr < 0 || rr >= f || ccc < 0 || ccc >= c) continue;
            if (_minas[rr][ccc]) n++;
          }
        }
        _adyacentes[r][cc] = n;
      }
    }
    _minasColocadas = true;
  }

  void _tocar(int r, int c) {
    if (_estado != _Estado.jugando || _banderas[r][c] || _reveladas[r][c]) return;
    if (!_minasColocadas) _colocarMinas(r, c);

    if (_minas[r][c]) {
      setState(() {
        _reveladas[r][c] = true;
        _estado = _Estado.perdiste;
        for (var i = 0; i < _filas; i++) {
          for (var j = 0; j < _columnas; j++) {
            if (_minas[i][j]) _reveladas[i][j] = true;
          }
        }
      });
      _guardarEstado();
      return;
    }

    setState(() {
      _revelarDesde(r, c);
      if (_gano()) {
        _estado = _Estado.ganaste;
        _premiar();
      }
    });
    _guardarEstado();
  }

  void _revelarDesde(int r, int c) {
    if (r < 0 || r >= _filas || c < 0 || c >= _columnas) return;
    if (_reveladas[r][c] || _banderas[r][c]) return;
    _reveladas[r][c] = true;
    if (_adyacentes[r][c] == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _revelarDesde(r + dr, c + dc);
        }
      }
    }
  }

  bool _gano() {
    for (var r = 0; r < _filas; r++) {
      for (var c = 0; c < _columnas; c++) {
        if (!_minas[r][c] && !_reveladas[r][c]) return false;
      }
    }
    return true;
  }

  void _marcar(int r, int c) {
    if (_estado != _Estado.jugando || _reveladas[r][c]) return;
    setState(() => _banderas[r][c] = !_banderas[r][c]);
    _guardarEstado();
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  void _siguienteNivel() {
    setState(() {
      _nivelActual = (_nivelActual + 1).clamp(0, _niveles.length - 1);
      _generarNueva();
    });
    _guardarEstado();
  }

  int get _banderasPuestas => _banderas.expand((f) => f).where((b) => b).length;

  @override
  Widget build(BuildContext context) {
    final hayMasNiveles = _nivelActual < _niveles.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('💣 Buscaminas')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _niveles.length > 1 ? 'Nivel ${_nivelActual + 1} de ${_niveles.length}' : 'Buscaminas',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '💣 ${_totalMinas - _banderasPuestas} por marcar',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    if (_estado == _Estado.ganaste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(hayMasNiveles ? '🎉 ¡Ganaste! Vamos al siguiente nivel.' : '🎉 ¡Ganaste el último nivel!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    if (_estado == _Estado.perdiste)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('💥 ¡Pisaste una mina!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    AspectRatio(
                      aspectRatio: _columnas / _filas,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: GridView.count(
                          crossAxisCount: _columnas,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          children: [
                            for (var r = 0; r < _filas; r++)
                              for (var c = 0; c < _columnas; c++) _celda(r, c),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_estado == _Estado.ganaste)
                      ElevatedButton(onPressed: hayMasNiveles ? _siguienteNivel : _reiniciar, child: Text(hayMasNiveles ? '➡️ Siguiente nivel' : '🔁 Jugar de nuevo'))
                    else if (_estado == _Estado.perdiste)
                      ElevatedButton(onPressed: _reiniciar, child: const Text('🔁 Reintentar')),
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
    final revelada = _reveladas[r][c];
    final bandera = _banderas[r][c];
    final mina = _minas[r][c];
    final n = _adyacentes[r][c];

    return GestureDetector(
      onTap: () => _tocar(r, c),
      onLongPress: () => _marcar(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: revelada ? (mina ? AppColors.coral : Colors.white) : AppColors.parchmentDark,
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: mina && revelada
            ? const Text('💣', style: TextStyle(fontSize: 14))
            : bandera && !revelada
                ? const Text('🚩', style: TextStyle(fontSize: 13))
                : (revelada && n > 0)
                    ? Text('$n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _colorNumero(n)))
                    : const SizedBox.shrink(),
      ),
    );
  }

  Color _colorNumero(int n) {
    const colores = [
      AppColors.violetDark, // no se usa (n=0 no muestra número)
      AppColors.sky,
      AppColors.green,
      AppColors.coral,
      AppColors.indigo,
      AppColors.magenta,
      AppColors.turquoise,
      AppColors.violetDark,
      Colors.black,
    ];
    return colores[n.clamp(0, colores.length - 1)];
  }
}
