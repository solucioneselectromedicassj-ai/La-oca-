import 'dart:math';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
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

  late List<List<bool>> _minas;
  late List<List<bool>> _reveladas;
  late List<List<bool>> _banderas;
  late List<List<int>> _adyacentes;
  bool _minasColocadas = false;
  _Estado _estado = _Estado.jugando;
  bool _premiado = false;

  _NivelConfig get _config => _niveles[_nivelActual];

  @override
  void initState() {
    super.initState();
    _reiniciar();
  }

  void _reiniciar() {
    final f = _config.filas, c = _config.columnas;
    _minas = List.generate(f, (_) => List.filled(c, false));
    _reveladas = List.generate(f, (_) => List.filled(c, false));
    _banderas = List.generate(f, (_) => List.filled(c, false));
    _adyacentes = List.generate(f, (_) => List.filled(c, 0));
    _minasColocadas = false;
    _estado = _Estado.jugando;
    _premiado = false;
    setState(() {});
  }

  void _colocarMinas(int rSeguro, int cSeguro) {
    final f = _config.filas, c = _config.columnas;
    final prohibidas = <String>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        prohibidas.add('${rSeguro + dr},${cSeguro + dc}');
      }
    }
    final rnd = Random();
    var colocadas = 0;
    while (colocadas < _config.minas) {
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
        for (var i = 0; i < _config.filas; i++) {
          for (var j = 0; j < _config.columnas; j++) {
            if (_minas[i][j]) _reveladas[i][j] = true;
          }
        }
      });
      return;
    }

    setState(() {
      _revelarDesde(r, c);
      if (_gano()) {
        _estado = _Estado.ganaste;
        _premiar();
      }
    });
  }

  void _revelarDesde(int r, int c) {
    if (r < 0 || r >= _config.filas || c < 0 || c >= _config.columnas) return;
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
    for (var r = 0; r < _config.filas; r++) {
      for (var c = 0; c < _config.columnas; c++) {
        if (!_minas[r][c] && !_reveladas[r][c]) return false;
      }
    }
    return true;
  }

  void _marcar(int r, int c) {
    if (_estado != _Estado.jugando || _reveladas[r][c]) return;
    setState(() => _banderas[r][c] = !_banderas[r][c]);
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  void _siguienteNivel() {
    setState(() => _nivelActual = (_nivelActual + 1).clamp(0, _niveles.length - 1));
    _reiniciar();
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
          child: Center(
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
                      '💣 ${_config.minas - _banderasPuestas} por marcar',
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
                      aspectRatio: _config.columnas / _config.filas,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: GridView.count(
                          crossAxisCount: _config.columnas,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          children: [
                            for (var r = 0; r < _config.filas; r++)
                              for (var c = 0; c < _config.columnas; c++) _celda(r, c),
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
