import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import '../utils/spider_engine.dart';
import 'widgets/estadisticas_juego.dart';

const _claveEstado = 'spider';
const _anchoCarta = 30.0;
const _altoCarta = 44.0;
const _solape = 15.0;
const _rojoCarta = Color(0xFFD32F2F);

/// Spider Solitaire clásico (2 mazos, 104 cartas siempre) — reemplaza al
/// Ta-Te-Ti para adolescentes y adultos, pedido explícito porque "el
/// tateti... no pierde nunca" ya no aplicaba pero igual se prefirió un
/// juego de cartas más largo para esas edades. La dificultad la da la
/// cantidad de palos en juego (1/2/4), que es la variante más común —
/// no la cantidad de mazos.
class SpiderScreen extends StatefulWidget {
  final String usuarioId;
  const SpiderScreen({super.key, required this.usuarioId});

  @override
  State<SpiderScreen> createState() => _SpiderScreenState();
}

class _SpiderScreenState extends State<SpiderScreen> {
  SpiderGame? _juego;
  (int, int)? _seleccion; // (columna, índice) del grupo tomado
  int? _pistaDestino;
  int _segundos = 0;
  bool _premiado = false;
  bool _cargando = true;
  bool _mostrarTiempo = true;
  bool _huboMovimiento = false;
  int _statsRefresco = 0;
  Timer? _ticker;
  Timer? _pistaTimer;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pistaTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarEstado() async {
    _mostrarTiempo = await PreferenciasService.obtenerMostrarTiempo();
    final g = await PreferenciasService.obtenerEstadoJuego(_claveEstado);
    if (g != null && g['juego'] != null) {
      _juego = SpiderGame.desdeJson(g['juego'] as Map<String, dynamic>);
      _segundos = g['segundos'] as int? ?? 0;
      _premiado = g['premiado'] as bool? ?? false;
      _huboMovimiento = true;
    } else {
      _juego = SpiderGame.nuevo(2);
    }
    if (mounted) setState(() => _cargando = false);
    _iniciarTicker();
  }

  Future<void> _guardarEstado() {
    final j = _juego;
    if (j == null) return Future.value();
    return PreferenciasService.guardarEstadoJuego(_claveEstado, {
      'juego': j.aJson(),
      'segundos': _segundos,
      'premiado': _premiado,
    });
  }

  void _iniciarTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _juego == null || _juego!.gano) return;
      setState(() => _segundos++);
    });
  }

  void _iniciarNuevaPartida(int nPalos) {
    setState(() {
      _juego = SpiderGame.nuevo(nPalos);
      _seleccion = null;
      _pistaDestino = null;
      _segundos = 0;
      _premiado = false;
      _huboMovimiento = false;
    });
    _guardarEstado();
    _iniciarTicker();
  }

  Future<bool> _confirmarSiHayProgreso() async {
    if (!_huboMovimiento) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Empezar de nuevo?'),
        content: const Text('Se pierde el progreso de la partida actual.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reiniciar')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _elegirDificultad(int nPalos) async {
    if (_juego != null && _juego!.nPalos == nPalos) return;
    if (!await _confirmarSiHayProgreso()) return;
    _iniciarNuevaPartida(nPalos);
  }

  Future<void> _reiniciar() async {
    final nPalos = _juego?.nPalos ?? 2;
    if (!await _confirmarSiHayProgreso()) return;
    _iniciarNuevaPartida(nPalos);
  }

  void _repartir() {
    final j = _juego;
    if (j == null) return;
    if (!j.puedeRepartir) {
      final motivo = j.stock.isEmpty ? 'No quedan cartas en el mazo.' : 'Solo se puede repartir si ninguna columna está vacía.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(motivo)));
      return;
    }
    setState(() {
      j.repartir();
      _seleccion = null;
      _huboMovimiento = true;
    });
    _guardarEstado();
    if (j.gano) _ganar();
  }

  void _ayuda() {
    final j = _juego;
    if (j == null) return;
    final pista = j.buscarPista();
    _pistaTimer?.cancel();
    if (pista == null) {
      final msg = j.puedeRepartir ? 'No veo un movimiento ahora — probá repartir del mazo. 🂠' : 'No hay movimientos posibles ahora mismo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    final (origen, indice, destino) = pista;
    setState(() {
      _seleccion = (origen, indice);
      _pistaDestino = destino;
    });
    _pistaTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _pistaDestino = null);
    });
  }

  void _tocarCarta(int columna, int indice) {
    final j = _juego;
    if (j == null || j.gano) return;
    final sel = _seleccion;
    if (sel == null) {
      final grupo = j.grupoSeleccionable(columna, indice);
      if (grupo != null) setState(() => _seleccion = (columna, indice));
      return;
    }
    if (sel.$1 == columna) {
      if (sel.$2 == indice) {
        setState(() => _seleccion = null);
      } else {
        final grupo = j.grupoSeleccionable(columna, indice);
        setState(() => _seleccion = grupo != null ? (columna, indice) : null);
      }
      return;
    }
    _intentarMover(sel, columna, indice);
  }

  void _tocarColumnaVacia(int columna) {
    final sel = _seleccion;
    if (sel == null) return;
    if (sel.$1 == columna) {
      setState(() => _seleccion = null);
      return;
    }
    _intentarMover(sel, columna, null);
  }

  void _intentarMover((int, int) sel, int columnaDestino, int? indiceTocado) {
    final j = _juego!;
    final movido = j.mover(sel.$1, sel.$2, columnaDestino);
    if (movido) {
      setState(() {
        _seleccion = null;
        _pistaDestino = null;
        _huboMovimiento = true;
      });
      _guardarEstado();
      if (j.gano) _ganar();
      return;
    }
    // El movimiento no era válido: si lo que tocaste es en sí una
    // secuencia movible, la selección "salta" a esa en vez de quedar
    // trabada esperando un destino que nunca vas a tocar de nuevo.
    if (indiceTocado != null) {
      final grupo = j.grupoSeleccionable(columnaDestino, indiceTocado);
      setState(() => _seleccion = grupo != null ? (columnaDestino, indiceTocado) : null);
    } else {
      setState(() => _seleccion = null);
    }
  }

  Future<void> _ganar() async {
    if (_premiado) return;
    _premiado = true;
    _ticker?.cancel();
    _guardarEstado();
    await PreferenciasService.registrarPartidaJuego(_claveEstado, gano: true, tiempoSegundos: _segundos);
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
    if (mounted) setState(() => _statsRefresco++);
  }

  Future<void> _alternarMostrarTiempo() async {
    final nuevo = !_mostrarTiempo;
    await PreferenciasService.guardarMostrarTiempo(nuevo);
    if (mounted) setState(() => _mostrarTiempo = nuevo);
  }

  String _formatearTiempo(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _selectorDificultad() {
    const opciones = [(1, '😌 1 palo'), (2, '🙂 2 palos'), (4, '😤 4 palos')];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(o.$2, style: const TextStyle(fontSize: 12)),
            selected: _juego?.nPalos == o.$1,
            selectedColor: AppColors.gold,
            backgroundColor: Colors.white,
            onSelected: (_) => _elegirDificultad(o.$1),
          ),
      ],
    );
  }

  Widget _botonAccion(String texto, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color ?? AppColors.violet, padding: const EdgeInsets.symmetric(horizontal: 12)),
        child: Text(texto, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🕷️ Spider')),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        children: [
                          _selectorDificultad(),
                          const SizedBox(height: 6),
                          EstadisticasJuego(juego: _claveEstado, refresco: _statsRefresco),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('🏆 ${_juego!.secuenciasCompletas}/$secuenciasParaGanar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              GestureDetector(
                                onTap: _alternarMostrarTiempo,
                                child: Text(
                                  _mostrarTiempo ? '⏱️ ${_formatearTiempo(_segundos)}' : '⏱️ oculto',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              _botonAccion('🔁 Reiniciar', _reiniciar, color: AppColors.coral),
                              _botonAccion('💡 Ayuda', _ayuda, color: AppColors.indigo),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_juego!.gano)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('🎉 ¡Ganaste el Spider!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                              child: SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [for (var c = 0; c < columnasSpider; c++) _columnaWidget(c)],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _mazoWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _mazoWidget() {
    final j = _juego!;
    final restantes = j.stock.length ~/ columnasSpider;
    return GestureDetector(
      onTap: _repartir,
      child: Container(
        width: 90,
        height: 40,
        decoration: BoxDecoration(
          color: restantes > 0 ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('🂠 Repartir ($restantes)', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _columnaWidget(int c) {
    final j = _juego!;
    final col = j.columnas[c];
    final altura = col.isEmpty ? _altoCarta : _altoCarta + _solape * (col.length - 1);
    final destacada = _pistaDestino == c;
    return SizedBox(
      width: _anchoCarta + 2,
      child: SizedBox(
        height: altura,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (col.isEmpty)
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => _tocarColumnaVacia(c),
                  child: Container(
                    width: _anchoCarta,
                    height: _altoCarta,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: destacada ? AppColors.gold : Colors.white.withValues(alpha: 0.4), width: destacada ? 2.5 : 1.2),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < col.length; i++)
              Positioned(
                top: i * _solape,
                child: GestureDetector(
                  onTap: () => _tocarCarta(c, i),
                  child: _cartaWidget(
                    col[i],
                    seleccionada: _seleccion != null && _seleccion!.$1 == c && i >= _seleccion!.$2,
                    destacada: destacada && i == col.length - 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cartaWidget(Carta carta, {required bool seleccionada, bool destacada = false}) {
    final resaltar = seleccionada || destacada;
    return Container(
      width: _anchoCarta,
      height: _altoCarta,
      decoration: BoxDecoration(
        color: carta.bocaArriba ? Colors.white : AppColors.violetDark,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: resaltar ? AppColors.gold : Colors.black.withValues(alpha: 0.25), width: resaltar ? 2.5 : 1),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 1.5, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      alignment: Alignment.topCenter,
      child: carta.bocaArriba
          ? Text(
              '${carta.textoRango}${carta.simboloPalo}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: carta.esRoja ? _rojoCarta : AppColors.ink),
            )
          : null,
    );
  }
}
