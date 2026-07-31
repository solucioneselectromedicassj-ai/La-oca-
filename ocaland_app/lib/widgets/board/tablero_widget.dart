import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/board_layout.dart';
import '../../game/casilla.dart';
import '../../theme/ocaland_theme.dart';
import 'casilla_iconos.dart';
import 'casilla_trampa_animada.dart';
import 'ciclo_icono_animado.dart';
import 'fondo_candy.dart';

/// Tablero de 30 casillas sobre un sendero de tierra/piedra serpenteante
/// (no una grilla, no una línea fina): las casillas normales van
/// incrustadas en el camino mismo, como piedras, y las de trampa se ven
/// más grandes, con su propio arte a tamaño completo. El tablero es más
/// alto que la pantalla y se desplaza verticalmente (con auto-scroll a
/// la ficha activa) para darle a 30 casillas el aire real que necesitan.
class TableroWidget extends StatefulWidget {
  const TableroWidget({
    super.key,
    required this.layout,
    required this.camino,
    required this.posJugador,
    required this.posBot,
    required this.gradiente,
    required this.acento,
    this.sinSendero = false,
    this.fondoAsset,
    this.fondoAspectRatio,
    this.fondoColorPie,
    this.spriteJugador,
    this.frameJugador = 0,
    this.spriteBot,
    this.frameBot = 0,
  });

  final BoardLayout layout;

  /// Bloques Tensión/Cima (sección 1 de la spec visual): casillas
  /// sueltas sin camino de tierra dibujado conectándolas, a diferencia
  /// del resto de las etapas.
  final bool sinSendero;

  /// Paleta del bloque de etapas actual (sección 1 de la spec visual
  /// v2), para pintar el paisaje de fondo (cielo/colinas) del tablero.
  final List<Color> gradiente;
  final Color acento;

  /// Fondo de escena real de este bloque (si existe): se muestra una
  /// sola vez, a su tamaño natural, arriba del todo del tablero.
  final String? fondoAsset;
  final double? fondoAspectRatio;
  final Color? fondoColorPie;

  /// Forma del camino de esta etapa (varía por etapa, ver
  /// `CampanaSoloController.camino`).
  final List<Offset> camino;
  final int posJugador;
  final int posBot;

  /// Frames de caminata del avatar equipado (si tiene arte real, sección 3
  /// de la spec visual v2); `null` usa el placeholder de círculo+letra.
  final List<String>? spriteJugador;
  final int frameJugador;
  final List<String>? spriteBot;
  final int frameBot;

  static const int totalCasillas = 30;

  @override
  State<TableroWidget> createState() => _TableroWidgetState();
}

class _TableroWidgetState extends State<TableroWidget> {
  final _scrollController = ScrollController();
  double _anchoActual = 0;

  /// Ancho/alto del contenido interno (no de la pantalla): antes era
  /// mucho más angosto/alto (0.22) para separar las 30 casillas, pero
  /// el usuario marcó que ni así entraba en una pantalla de celular.
  /// Con el camino de más vueltas apretadas (`CaminoTablero`) alcanza
  /// una proporción bastante más compacta y sigue sin superponerse.
  static const double _aspectRatioContenido = 0.62;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnJugador(animar: false));
  }

  @override
  void didUpdateWidget(covariant TableroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posJugador != widget.posJugador) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnJugador(animar: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centrarEnJugador({required bool animar}) {
    if (!_scrollController.hasClients || _anchoActual == 0) return;
    final alto = _anchoActual / _aspectRatioContenido;
    final centroY = widget.camino[widget.posJugador].dy * alto;
    final viewport = _scrollController.position.viewportDimension;
    final destino =
        (centroY - viewport / 2).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animar) {
      _scrollController.animateTo(
        destino,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(destino);
    }
  }

  double _tamanoDe(TipoCasilla tipo) => tipo.esCasillaFlotante ? 46 : 32;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _anchoActual = constraints.maxWidth;
        final size = Size(constraints.maxWidth, constraints.maxWidth / _aspectRatioContenido);
        return Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: FondoCandy(
                      gradiente: widget.gradiente,
                      acento: widget.acento,
                      camino: widget.camino,
                      sinSendero: widget.sinSendero,
                      fondoAsset: widget.fondoAsset,
                      fondoAspectRatio: widget.fondoAspectRatio,
                      fondoColorPie: widget.fondoColorPie,
                    ),
                  ),
                  if (!widget.sinSendero)
                    Positioned.fill(
                      child: CustomPaint(painter: _CaminoPainter(widget.camino)),
                    ),
                  for (var i = 0; i < TableroWidget.totalCasillas; i++)
                    _posicionarCasilla(i, size),
                  _posicionarFichas(size),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _posicionarCasilla(int posicion, Size size) {
    final tipo = widget.layout.tipoDe(posicion);
    final centro = Offset(
      widget.camino[posicion].dx * size.width,
      widget.camino[posicion].dy * size.height,
    );

    if (posicion == 0) {
      const w = 74.0, h = 96.0;
      return Positioned(
        left: centro.dx - w / 2,
        top: centro.dy - h + 15,
        width: w,
        height: h,
        child: const _MarcadorInicio(),
      );
    }
    if (tipo == TipoCasilla.meta) {
      const w = 84.0, h = 100.0;
      return Positioned(
        left: centro.dx - w / 2,
        top: centro.dy - h + 17,
        width: w,
        height: h,
        child: const _MarcadorMeta(),
      );
    }

    final tamano = _tamanoDe(tipo);
    return Positioned(
      left: centro.dx - tamano / 2,
      top: centro.dy - tamano / 2,
      width: tamano,
      height: tamano,
      child: _Casilla(posicion: posicion, tipo: tipo, tamano: tamano),
    );
  }

  Widget _posicionarFichas(Size size) {
    final mismaCasilla = widget.posJugador == widget.posBot;
    final centroJugador = Offset(
      widget.camino[widget.posJugador].dx * size.width,
      widget.camino[widget.posJugador].dy * size.height,
    );
    final centroBot = Offset(
      widget.camino[widget.posBot].dx * size.width,
      widget.camino[widget.posBot].dy * size.height,
    );
    const fichaTamano = 42.0;
    const duracion = Duration(milliseconds: 210);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: duracion,
          curve: Curves.easeInOut,
          left: centroJugador.dx - fichaTamano / 2 - (mismaCasilla ? 10 : 0),
          top: centroJugador.dy - fichaTamano - 6,
          width: fichaTamano,
          height: fichaTamano,
          child: widget.spriteJugador != null
              ? _FichaSprite(frames: widget.spriteJugador!, indice: widget.frameJugador)
              : const _Ficha(color: OcalandColors.violeta, letra: 'J'),
        ),
        AnimatedPositioned(
          duration: duracion,
          curve: Curves.easeInOut,
          left: centroBot.dx - fichaTamano / 2 + (mismaCasilla ? 10 : 0),
          top: centroBot.dy - fichaTamano - 6,
          width: fichaTamano,
          height: fichaTamano,
          child: widget.spriteBot != null
              ? _FichaSprite(frames: widget.spriteBot!, indice: widget.frameBot)
              : const _Ficha(color: OcalandColors.fucsia, letra: 'B'),
        ),
      ],
    );
  }
}

/// Sendero de tierra/piedra que conecta las 30 casillas: borde oscuro,
/// cuerpo de tierra clara, resalte pisado al centro, y piedritas
/// sueltas a los costados como textura — no una línea fina pintada
/// encima del paisaje, sino un camino real.
class _CaminoPainter extends CustomPainter {
  _CaminoPainter(this.puntos);

  final List<Offset> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final pxPuntos = <Offset>[];
    for (var i = 0; i < puntos.length; i++) {
      final p = Offset(puntos[i].dx * size.width, puntos[i].dy * size.height);
      pxPuntos.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    void trazo(double ancho, Color color) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = ancho
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    trazo(42, const Color(0xFF8A6A4A));
    trazo(34, const Color(0xFFD9B77E));
    trazo(14, const Color(0xFFECD8AE));

    final rng = Random(7);
    final piedrita = Paint()..color = const Color(0xFF8A6A4A).withValues(alpha: 0.55);
    for (var i = 0; i < pxPuntos.length - 1; i++) {
      final a = pxPuntos[i];
      final b = pxPuntos[i + 1];
      final distancia = (b - a).distance;
      final segmentos = (distancia / 16).round().clamp(1, 20);
      final d = b - a;
      final largo = d.distance == 0 ? 1 : d.distance;
      final perpendicular = Offset(-d.dy / largo, d.dx / largo);
      for (var s = 0; s < segmentos; s++) {
        final t = s / segmentos;
        final centro = Offset.lerp(a, b, t)!;
        final lado = rng.nextBool() ? 1 : -1;
        final offset = centro + perpendicular * (lado * (16 + rng.nextDouble() * 5));
        canvas.drawCircle(offset, 1.6 + rng.nextDouble() * 1.6, piedrita);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CaminoPainter oldDelegate) => false;
}

/// Una casilla de trampa: su propio arte a tamaño completo (sin disco
/// de fondo genérico) — la trampa es la casilla.
class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.posicion,
    required this.tipo,
    required this.tamano,
  });

  final int posicion;
  final TipoCasilla tipo;
  final double tamano;

  /// Color característico por tipo, para el aura de fondo — ayuda a
  /// distinguir de un vistazo qué trampa es cada una, sobre todo con
  /// un fondo de foto real detrás (no un color plano liso).
  Color get _colorAura {
    switch (tipo) {
      case TipoCasilla.oca:
        return OcalandColors.amarillo;
      case TipoCasilla.trampolin:
        return OcalandColors.turquesa;
      case TipoCasilla.carcel:
        return Colors.blueGrey.shade200;
      case TipoCasilla.calavera:
        return OcalandColors.fucsia;
      case TipoCasilla.minijuego:
        return OcalandColors.celeste;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tipo.esCasillaFlotante) {
      return CasillaTrampaAnimada(
        tipo: tipo,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Aura de color detrás, para distinguir el tipo de trampa
            // de un vistazo aunque el fondo real sea una foto ocupada.
            Container(
              width: tamano * 1.35,
              height: tamano * 1.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_colorAura.withValues(alpha: 0.55), _colorAura.withValues(alpha: 0)],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _arteTrampa(),
            ),
          ],
        ),
      );
    }
    return _Piedra(posicion: posicion, tamano: tamano);
  }

  Widget _arteTrampa() {
    if (tipo == TipoCasilla.oca) {
      return CicloIconoAnimado(frames: CasillaIconos.framesOca, alto: tamano);
    }
    final ruta = CasillaIconos.iconoEstatico[tipo];
    if (ruta == null) return Text(tipo.emoji, style: TextStyle(fontSize: tamano * 0.7));
    return Image.asset(ruta, height: tamano, cacheHeight: (tamano * 2).round());
  }
}

/// Piedra numerada incrustada en el camino (casillas normales): no un
/// disco flotando encima, sino algo que se ve parte del sendero.
class _Piedra extends StatelessWidget {
  const _Piedra({required this.posicion, required this.tamano});

  final int posicion;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFEDDFC4), Color(0xFFBCA47F)],
          center: Alignment(-0.3, -0.3),
        ),
        border: Border.all(color: const Color(0xFF8A6A4A), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$posicion',
        style: TextStyle(
          fontSize: tamano * 0.42,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF6B4F35),
        ),
      ),
    );
  }
}

/// Marca de INICIO: banderín con etiqueta + la piedra de la casilla 0.
class _MarcadorInicio extends StatelessWidget {
  const _MarcadorInicio();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: OcalandColors.verde,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3, offset: const Offset(0, 2)),
            ],
          ),
          child: const Text(
            'INICIO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.4),
          ),
        ),
        const SizedBox(height: 2),
        const Icon(Icons.flag_rounded, color: Color(0xFF43D67D), size: 26),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFEDDFC4), Color(0xFFBCA47F)],
              center: Alignment(-0.3, -0.3),
            ),
            border: Border.all(color: const Color(0xFF8A6A4A), width: 2.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.32), blurRadius: 3, offset: const Offset(0, 3)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Marca de META: banderín con etiqueta + trofeo + medallón dorado.
class _MarcadorMeta extends StatelessWidget {
  const _MarcadorMeta();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE0A800),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3, offset: const Offset(0, 2)),
            ],
          ),
          child: const Text(
            'META',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.4),
          ),
        ),
        const SizedBox(height: 2),
        const Text('🏆', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 2),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFFE8B0), Color(0xFFE0A800)],
              center: Alignment(-0.3, -0.3),
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.32), blurRadius: 4, offset: const Offset(0, 3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FichaSprite extends StatelessWidget {
  const _FichaSprite({required this.frames, required this.indice});

  final List<String> frames;
  final int indice;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      frames[indice % frames.length],
      height: 52,
      cacheHeight: 156,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.color, required this.letra});

  final Color color;
  final String letra;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letra,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
