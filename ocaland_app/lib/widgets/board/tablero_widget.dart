import 'package:flutter/material.dart';

import '../../game/board_layout.dart';
import '../../game/casilla.dart';
import '../../theme/ocaland_theme.dart';
import 'camino_tablero.dart';
import 'casilla_iconos.dart';
import 'casilla_trampa_animada.dart';
import 'oca_vuelo_animado.dart';

/// Tablero de 30 casillas en camino serpenteante (tipo mapa de Candy
/// Crush), no en grilla. La curva es paramétrica (`CaminoTablero`) — no
/// calca ningún mapa puntual, pero da esa sensación de camino sinuoso en
/// vez de filas rectas. Las casillas de trampa se ven más grandes que
/// las normales (sección 4 de la spec visual v2).
class TableroWidget extends StatelessWidget {
  const TableroWidget({
    super.key,
    required this.layout,
    required this.posJugador,
    required this.posBot,
    this.spriteJugador,
    this.frameJugador = 0,
    this.spriteBot,
    this.frameBot = 0,
  });

  final BoardLayout layout;
  final int posJugador;
  final int posBot;

  /// Frames de caminata del avatar equipado (si tiene arte real, sección 3
  /// de la spec visual v2); `null` usa el placeholder de círculo+letra.
  final List<String>? spriteJugador;
  final int frameJugador;
  final List<String>? spriteBot;
  final int frameBot;

  static const int totalCasillas = 30;
  static final List<Offset> _puntos = CaminoTablero.generar(totalCasillas);

  double _radioDe(int posicion, TipoCasilla tipo) {
    if (tipo.esCasillaFlotante || tipo == TipoCasilla.oca) return 24;
    if (tipo == TipoCasilla.meta) return 22;
    if (posicion == 0) return 20;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _CaminoPainter(_puntos)),
              ),
              for (var i = 0; i < totalCasillas; i++)
                _posicionarCasilla(i, size),
              _posicionarFichas(size),
            ],
          );
        },
      ),
    );
  }

  Widget _posicionarCasilla(int posicion, Size size) {
    final tipo = layout.tipoDe(posicion);
    final radio = _radioDe(posicion, tipo);
    final centro = Offset(
      _puntos[posicion].dx * size.width,
      _puntos[posicion].dy * size.height,
    );
    return Positioned(
      left: centro.dx - radio,
      top: centro.dy - radio,
      width: radio * 2,
      height: radio * 2,
      child: _CasillaCirculo(posicion: posicion, tipo: tipo, radio: radio),
    );
  }

  Widget _posicionarFichas(Size size) {
    final mismaCasilla = posJugador == posBot;
    final centroJugador = Offset(
      _puntos[posJugador].dx * size.width,
      _puntos[posJugador].dy * size.height,
    );
    final centroBot = Offset(
      _puntos[posBot].dx * size.width,
      _puntos[posBot].dy * size.height,
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
          child: spriteJugador != null
              ? _FichaSprite(frames: spriteJugador!, indice: frameJugador)
              : const _Ficha(color: OcalandColors.violeta, letra: 'J'),
        ),
        Positioned(
          left: centroBot.dx - fichaTamano / 2 + (mismaCasilla ? 10 : 0),
          top: centroBot.dy - fichaTamano - 6,
          width: fichaTamano,
          height: fichaTamano,
          child: spriteBot != null
              ? _FichaSprite(frames: spriteBot!, indice: frameBot)
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
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final p = Offset(puntos[i].dx * size.width, puntos[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CaminoPainter oldDelegate) => false;
}

class _CasillaCirculo extends StatelessWidget {
  const _CasillaCirculo({
    required this.posicion,
    required this.tipo,
    required this.radio,
  });

  final int posicion;
  final TipoCasilla tipo;
  final double radio;

  Color get _colorFondo {
    switch (tipo) {
      case TipoCasilla.oca:
        return OcalandColors.amarillo;
      case TipoCasilla.puente:
        return OcalandColors.turquesa;
      case TipoCasilla.carcel:
        return Colors.blueGrey.shade300;
      case TipoCasilla.calavera:
        return OcalandColors.fucsia;
      case TipoCasilla.minijuego:
        return OcalandColors.celeste;
      case TipoCasilla.meta:
        return OcalandColors.verde;
      case TipoCasilla.normal:
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
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: tipo == TipoCasilla.oca
            ? OcaVueloAnimado(alto: radio * 1.2)
            : tipo.esCasillaFlotante
                ? CasillaTrampaAnimada(
                    tipo: tipo,
                    child: CasillaIconos.iconoEstatico.containsKey(tipo)
                        ? Image.asset(
                            CasillaIconos.iconoEstatico[tipo]!,
                            height: radio * 1.15,
                            cacheHeight: 90,
                          )
                        : Text(tipo.emoji, style: TextStyle(fontSize: radio)),
                  )
                : tipo == TipoCasilla.meta
                    ? Text(tipo.emoji, style: TextStyle(fontSize: radio))
                    : posicion == 0
                        ? const Icon(Icons.flag, color: Colors.white, size: 16)
                        : null,
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
