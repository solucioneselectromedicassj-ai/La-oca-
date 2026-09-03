import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import '../utils/klondike_engine.dart';
import 'widgets/estadisticas_juego.dart';

const _claveEstado = 'solitario';
const _anchoCarta = 48.0;
const _altoCarta = 70.0;
const _solape = 24.0;
const _rojoCarta = Color(0xFFD32F2F);

/// Solitario clásico (Klondike, 1 mazo de 52 cartas) — pedido explícito
/// del usuario ("este es el que juego... creo es el solitario"), con
/// cartas más grandes a propósito para que se lea bien ("para personas
/// mayores que no ven bien"). Reemplaza al Spider para adolescentes y
/// adultos en la Zona de juegos.
class SolitarioScreen extends StatefulWidget {
  final String usuarioId;
  const SolitarioScreen({super.key, required this.usuarioId});

  @override
  State<SolitarioScreen> createState() => _SolitarioScreenState();
}

class _SolitarioScreenState extends State<SolitarioScreen> {
  KlondikeGame? _juego;
  (int, int)? _seleccion; // (columna, índice) del grupo tomado del tablero
  bool _descarteSeleccionado = false;
  PistaMovimiento? _pista;
  int _segundos = 0;
  bool _premiado = false;
  bool _cargando = true;
  bool _mostrarTiempo = true;
  bool _huboMovimiento = false;
  int _statsRefresco = 0;
  final List<Map<String, dynamic>> _historial = [];
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
      _juego = KlondikeGame.desdeJson(g['juego'] as Map<String, dynamic>);
      _segundos = g['segundos'] as int? ?? 0;
      _premiado = g['premiado'] as bool? ?? false;
      _huboMovimiento = true;
    } else {
      _juego = KlondikeGame.nuevo(drawCount: 1);
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

  Future<void> _reiniciar() async {
    if (!await _confirmarSiHayProgreso()) return;
    final draw = _juego?.drawCount ?? 1;
    setState(() {
      _juego = KlondikeGame.nuevo(drawCount: draw);
      _seleccion = null;
      _descarteSeleccionado = false;
      _pista = null;
      _segundos = 0;
      _premiado = false;
      _huboMovimiento = false;
      _historial.clear();
    });
    _guardarEstado();
    _iniciarTicker();
  }

  void _elegirDrawCount(int n) {
    final j = _juego;
    if (j == null || j.drawCount == n) return;
    setState(() => j.drawCount = n);
    _guardarEstado();
  }

  /// Ejecuta una acción mutante del motor guardando antes una foto del
  /// estado (para poder deshacer); si la acción no era válida, no se
  /// guarda nada y se informa que falló.
  bool _ejecutar(bool Function() accion) {
    final j = _juego;
    if (j == null) return false;
    final snapshot = j.aJson();
    final exito = accion();
    if (!exito) return false;
    _historial.add(snapshot);
    if (_historial.length > 60) _historial.removeAt(0);
    setState(() {
      _seleccion = null;
      _descarteSeleccionado = false;
      _pista = null;
      _huboMovimiento = true;
    });
    _guardarEstado();
    if (j.gano) _ganar();
    return true;
  }

  void _deshacer() {
    if (_historial.isEmpty) return;
    final snapshot = _historial.removeLast();
    setState(() {
      _juego = KlondikeGame.desdeJson(snapshot);
      _seleccion = null;
      _descarteSeleccionado = false;
      _pista = null;
    });
    _guardarEstado();
  }

  void _robar() {
    final j = _juego;
    if (j == null || j.gano || !j.puedeRobar) return;
    _ejecutar(() {
      j.robarDelMazo();
      return true;
    });
  }

  void _ayuda() {
    final j = _juego;
    if (j == null) return;
    final pista = j.buscarPista();
    _pistaTimer?.cancel();
    if (pista == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No quedan movimientos posibles.')));
      return;
    }
    setState(() => _pista = pista);
    if (pista.tipo == 'robar') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Probá robar del mazo. 🂠')));
    }
    _pistaTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _pista = null);
    });
  }

  void _tocarDescarte() {
    final j = _juego;
    if (j == null || j.gano || j.descarte.isEmpty) return;
    if (j.puedeApilarEnFundacion(j.descarte.last)) {
      _ejecutar(() => j.moverDescarteAFundacion());
      return;
    }
    setState(() {
      _seleccion = null;
      _descarteSeleccionado = !_descarteSeleccionado;
    });
  }

  void _tocarCarta(int columna, int indice) {
    final j = _juego;
    if (j == null || j.gano) return;

    if (_descarteSeleccionado) {
      final ok = _ejecutar(() => j.moverDescarteAColumna(columna));
      if (!ok) {
        final grupo = j.grupoSeleccionable(columna, indice);
        setState(() {
          _descarteSeleccionado = false;
          _seleccion = grupo != null ? (columna, indice) : null;
        });
      }
      return;
    }

    final sel = _seleccion;
    if (sel == null) {
      final col = j.columnas[columna];
      final esUltima = indice == col.length - 1;
      if (esUltima && col[indice].bocaArriba && j.puedeApilarEnFundacion(col[indice])) {
        _ejecutar(() => j.moverTableauAFundacion(columna));
        return;
      }
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

    final origColumna = sel.$1, origIndice = sel.$2;
    final ok = _ejecutar(() => j.mover(origColumna, origIndice, columna));
    if (!ok) {
      final grupo = j.grupoSeleccionable(columna, indice);
      setState(() => _seleccion = grupo != null ? (columna, indice) : null);
    }
  }

  void _tocarColumnaVacia(int columna) {
    final j = _juego;
    if (j == null || j.gano) return;
    if (_descarteSeleccionado) {
      _ejecutar(() => j.moverDescarteAColumna(columna));
      return;
    }
    final sel = _seleccion;
    if (sel == null) return;
    if (sel.$1 == columna) {
      setState(() => _seleccion = null);
      return;
    }
    _ejecutar(() => j.mover(sel.$1, sel.$2, columna));
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

  Widget _selectorSacar() {
    const opciones = [(1, 'Sacar 1'), (3, 'Sacar 3')];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(o.$2, style: const TextStyle(fontSize: 12)),
            selected: _juego?.drawCount == o.$1,
            selectedColor: AppColors.gold,
            backgroundColor: Colors.white,
            onSelected: (_) => _elegirDrawCount(o.$1),
          ),
      ],
    );
  }

  Widget _botonAccion(String texto, VoidCallback? onTap, {Color? color}) {
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🃏 Solitario')),
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
                          EstadisticasJuego(juego: _claveEstado, refresco: _statsRefresco),
                          _filaContadores(),
                          const SizedBox(height: 6),
                          _selectorSacar(),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _botonAccion('🔁 Reiniciar', _reiniciar, color: AppColors.coral),
                              _botonAccion('💡 Ayuda', _ayuda, color: AppColors.indigo),
                              _botonAccion('↩️ Deshacer', _historial.isEmpty ? null : _deshacer, color: AppColors.turquoise),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_juego!.gano)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('🎉 ¡Ganaste el Solitario!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          _filaFundacionesYMazo(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [for (var c = 0; c < columnasKlondike; c++) _columnaWidget(c)],
                              ),
                            ),
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

  Widget _filaContadores() {
    final j = _juego!;
    Widget columna(String etiqueta, String valor, {VoidCallback? onTap}) {
      final contenido = Column(
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.5) ?? TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
      return Expanded(child: onTap == null ? contenido : GestureDetector(onTap: onTap, child: contenido));
    }

    return Row(
      children: [
        columna('PUNTOS', '${j.puntos}'),
        columna('TIEMPO', _mostrarTiempo ? _formatearTiempo(_segundos) : '·····', onTap: _alternarMostrarTiempo),
        columna('MOVIM.', '${j.movimientos}'),
      ],
    );
  }

  Widget _filaFundacionesYMazo() {
    final j = _juego!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [for (final p in Palo.values) Padding(padding: const EdgeInsets.only(right: 6), child: _fundacionWidget(p))]),
        Row(
          children: [
            SizedBox(
              width: _anchoCarta,
              height: _altoCarta,
              child: j.descarte.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: _tocarDescarte,
                      child: _cartaWidget(j.descarte.last, seleccionada: _descarteSeleccionado, destacada: _esDescartePista()),
                    ),
            ),
            const SizedBox(width: 6),
            _mazoWidget(),
          ],
        ),
      ],
    );
  }

  bool _esDescartePista() => _pista?.tipo == 'descarteAFundacion' || _pista?.tipo == 'descarteAColumna';

  Widget _fundacionWidget(Palo palo) {
    final j = _juego!;
    final tope = j.fundaciones[palo] ?? 0;
    final vista = Carta(tope == 0 ? 1 : tope, palo);
    return Container(
      width: _anchoCarta,
      height: _altoCarta,
      decoration: BoxDecoration(
        color: tope == 0 ? Colors.white.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
      ),
      alignment: Alignment.center,
      child: tope == 0
          ? Text(vista.simboloPalo, style: TextStyle(fontSize: 22, color: Colors.white.withValues(alpha: 0.55)))
          : Text('${vista.textoRango}${vista.simboloPalo}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: vista.esRoja ? _rojoCarta : AppColors.ink)),
    );
  }

  Widget _mazoWidget() {
    final j = _juego!;
    return GestureDetector(
      onTap: _robar,
      child: Container(
        width: _anchoCarta,
        height: _altoCarta,
        decoration: BoxDecoration(
          color: j.stock.isNotEmpty ? AppColors.violetDark : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
        ),
        alignment: Alignment.center,
        child: j.stock.isNotEmpty
            ? Text('${j.stock.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
            : Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.6), size: 22),
      ),
    );
  }

  Widget _columnaWidget(int c) {
    final j = _juego!;
    final col = j.columnas[c];
    final altura = col.isEmpty ? _altoCarta : _altoCarta + _solape * (col.length - 1);
    final esDestinoPista = _pista?.columnaDestino == c;
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
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: esDestinoPista ? AppColors.gold : Colors.white.withValues(alpha: 0.4), width: esDestinoPista ? 2.5 : 1.2),
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
                    destacada: (esDestinoPista && i == col.length - 1) || _esOrigenPista(c, i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _esOrigenPista(int columna, int indice) {
    final p = _pista;
    if (p == null || p.columnaOrigen != columna) return false;
    if (p.tipo == 'tableauAFundacion') return indice == _juego!.columnas[columna].length - 1;
    if (p.tipo == 'tableauATableau') return indice >= (p.indice ?? 0);
    return false;
  }

  Widget _cartaWidget(Carta carta, {required bool seleccionada, bool destacada = false}) {
    final resaltar = seleccionada || destacada;
    return Container(
      width: _anchoCarta,
      height: _altoCarta,
      decoration: BoxDecoration(
        color: carta.bocaArriba ? Colors.white : AppColors.violetDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: resaltar ? AppColors.gold : Colors.black.withValues(alpha: 0.25), width: resaltar ? 2.5 : 1),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 1.5, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: Alignment.topCenter,
      child: carta.bocaArriba
          ? Text(
              '${carta.textoRango}${carta.simboloPalo}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: carta.esRoja ? _rojoCarta : AppColors.ink),
            )
          : null,
    );
  }
}
