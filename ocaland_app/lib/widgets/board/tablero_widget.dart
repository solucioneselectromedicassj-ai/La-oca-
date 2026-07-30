import 'package:flutter/material.dart';

import '../../game/board_layout.dart';
import '../../game/casilla.dart';
import '../../theme/ocaland_theme.dart';
import 'casilla_iconos.dart';
import 'casilla_trampa_animada.dart';
import 'ciclo_icono_animado.dart';
import 'fondo_candy.dart';

/// Tablero de 30 casillas en camino serpenteante (tipo mapa de Candy
/// Crush), no en grilla. La curva es paramétrica (`CaminoTablero`,
/// repartida por longitud de arco para que las casillas no se
/// amonton en las curvas). El tablero es más alto que la pantalla y
/// se desplaza verticalmente (con auto-scroll a la ficha activa) — es
/// la única forma de darle a 30 casillas el aire que necesitan sin que
/// se toquen entre sí, ya que un simple `AspectRatio` sigue estando
/// acotado por el alto real disponible del padre. Las casillas de
/// trampa se muestran con su propio arte a tamaño completo (sin un
/// círculo de fondo genérico atrás) — la trampa ES la casilla.
class TableroWidget extends StatefulWidget {
  const TableroWidget({
    super.key,
    required this.layout,
    required this.camino,
    required this.posJugador,
    required this.posBot,
    required this.gradiente,
    required this.acento,
    this.spriteJugador,
    this.frameJugador = 0,
    this.spriteBot,
    this.frameBot = 0,
  });

  final BoardLayout layout;

  /// Paleta del bloque de etapas actual (sección 1 de la spec visual
  /// v2), para pintar el paisaje de fondo (cielo/colinas) del tablero.
  final List<Color> gradiente;
  final Color acento;

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

  /// Ancho/alto del contenido interno (no de la pantalla): bien angosto
  /// para que las 30 casillas tengan espacio real entre sí. El usuario
  /// hace scroll vertical para recorrerlo.
  static const double _aspectRatioContenido = 0.22;

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

  double _tamanoDe(int posicion, TipoCasilla tipo) {
    if (tipo.esCasillaFlotante) return 38;
    if (tipo == TipoCasilla.meta) return 34;
    if (posicion == 0) return 30;
    return 22;
  }

  List<Offset> _trampolinesPx(Size size) {
    return [
      for (var i = 1; i < BoardLayout.meta; i++)
        if (widget.layout.tipoDe(i) == TipoCasilla.trampolin)
          Offset(widget.camino[i].dx * size.width, widget.camino[i].dy * size.height),
    ];
  }

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
                      trampolinesPx: _trampolinesPx(size),
                    ),
                  ),
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
    final tamano = _tamanoDe(posicion, tipo);
    final centro = Offset(
      widget.camino[posicion].dx * size.width,
      widget.camino[posicion].dy * size.height,
    );
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
    const fichaTamano = 30.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: centroJugador.dx - fichaTamano / 2 - (mismaCasilla ? 10 : 0),
          top: centroJugador.dy - fichaTamano - 6,
          width: fichaTamano,
          height: fichaTamano,
          child: widget.spriteJugador != null
              ? _FichaSprite(frames: widget.spriteJugador!, indice: widget.frameJugador)
              : const _Ficha(color: OcalandColors.violeta, letra: 'J'),
        ),
        Positioned(
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

/// Línea de camino que conecta las 30 casillas, pintada debajo de ellas.
class _CaminoPainter extends CustomPainter {
  _CaminoPainter(this.puntos);

  final List<Offset> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final p = Offset(puntos[i].dx * size.width, puntos[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // Camino en 3 capas (borde + cuerpo + brillo central) para que se
    // vea como un sendero con relieve en vez de una línea plana.
    void trazo(double ancho, double alpha) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = ancho
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    trazo(15, 0.28);
    trazo(9, 0.75);
    trazo(3, 0.95);
  }

  @override
  bool shouldRepaint(covariant _CaminoPainter oldDelegate) => false;
}

/// Una casilla del tablero. Las normales (y salida/meta) son un disco
/// tipo "ficha" con número; las de trampa son directamente su propio
/// arte (más grande, sin disco de fondo) — la trampa es la casilla.
class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.posicion,
    required this.tipo,
    required this.tamano,
  });

  final int posicion;
  final TipoCasilla tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    if (tipo.esCasillaFlotante) {
      return CasillaTrampaAnimada(
        tipo: tipo,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: _arteTrampa()),
        ),
      );
    }
    return _Disco(posicion: posicion, tipo: tipo, tamano: tamano);
  }

  Widget _arteTrampa() {
    switch (tipo) {
      case TipoCasilla.oca:
        return CicloIconoAnimado(frames: CasillaIconos.framesOca, alto: tamano);
      case TipoCasilla.calavera:
        return CicloIconoAnimado(
          frames: CasillaIconos.framesCalavera,
          alto: tamano * 1.05,
          duracionFrame: const Duration(milliseconds: 380),
        );
      default:
        final ruta = CasillaIconos.iconoEstatico[tipo];
        if (ruta == null) return Text(tipo.emoji, style: TextStyle(fontSize: tamano * 0.7));
        return Image.asset(ruta, height: tamano, cacheHeight: (tamano * 2).round());
    }
  }
}

/// Disco tipo "ficha de tablero" para casillas normales, salida y meta.
class _Disco extends StatelessWidget {
  const _Disco({required this.posicion, required this.tipo, required this.tamano});

  final int posicion;
  final TipoCasilla tipo;
  final double tamano;

  Color get _colorFondo {
    switch (tipo) {
      case TipoCasilla.meta:
        return OcalandColors.verde;
      default:
        return posicion == 0 ? OcalandColors.violeta : Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_colorFondo.withValues(alpha: 0.85), _colorFondo],
          center: const Alignment(-0.3, -0.3),
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: tamano * 0.14,
            left: tamano * 0.3,
            child: Container(
              width: tamano * 0.42,
              height: tamano * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: tipo == TipoCasilla.meta
                ? Text(tipo.emoji, style: TextStyle(fontSize: tamano * 0.5))
                : posicion == 0
                ? const Icon(Icons.flag, color: Colors.white, size: 16)
                : Text(
                    '$posicion',
                    style: TextStyle(
                      fontSize: tamano * 0.42,
                      fontWeight: FontWeight.w800,
                      color: OcalandColors.violeta,
                    ),
                  ),
          ),
        ],
      ),
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
      height: 40,
      cacheHeight: 120,
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
