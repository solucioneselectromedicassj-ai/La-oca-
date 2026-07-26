import 'package:flutter/material.dart';

import '../../game/board_layout.dart';
import '../../game/casilla.dart';
import '../../theme/ocaland_theme.dart';
import 'casilla_iconos.dart';
import 'casilla_trampa_animada.dart';
import 'oca_vuelo_animado.dart';

/// Tablero de 30 casillas en trazado de serpiente (boustrophedon: de
/// izquierda a derecha y luego de derecha a izquierda, fila por fila).
///
/// Es una aproximación práctica al trazado en espiral de la especificación
/// (sección 3) — el orden lógico de las casillas (0 a 29) es el mismo, lo
/// que cambia es solo la disposición visual. Portar el trazado espiral
/// real (con geometría/`CustomPainter`) queda como pulido visual futuro.
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

  static const int columnas = 5;
  static const int filas = 6;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: columnas / filas,
      child: Column(
        children: List.generate(filas, (fila) {
          final deIzquierdaADerecha = fila.isEven;
          final indicesFila = List.generate(columnas, (col) {
            final colReal = deIzquierdaADerecha ? col : columnas - 1 - col;
            return fila * columnas + colReal;
          });
          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: indicesFila
                  .map((pos) => Expanded(child: _CasillaCelda(
                        posicion: pos,
                        tipo: layout.tipoDe(pos),
                        tieneJugador: pos == posJugador,
                        tieneBot: pos == posBot,
                        spriteJugador: spriteJugador,
                        frameJugador: frameJugador,
                        spriteBot: spriteBot,
                        frameBot: frameBot,
                      )))
                  .toList(),
            ),
          );
        }),
      ),
    );
  }
}

class _CasillaCelda extends StatelessWidget {
  const _CasillaCelda({
    required this.posicion,
    required this.tipo,
    required this.tieneJugador,
    required this.tieneBot,
    this.spriteJugador,
    this.frameJugador = 0,
    this.spriteBot,
    this.frameBot = 0,
  });

  final int posicion;
  final TipoCasilla tipo;
  final bool tieneJugador;
  final bool tieneBot;
  final List<String>? spriteJugador;
  final int frameJugador;
  final List<String>? spriteBot;
  final int frameBot;

  Color get _colorFondo {
    switch (tipo) {
      case TipoCasilla.oca:
        return OcalandColors.amarillo.withValues(alpha: 0.35);
      case TipoCasilla.puente:
        return OcalandColors.turquesa.withValues(alpha: 0.35);
      case TipoCasilla.carcel:
        return Colors.grey.withValues(alpha: 0.35);
      case TipoCasilla.calavera:
        return OcalandColors.fucsia.withValues(alpha: 0.35);
      case TipoCasilla.minijuego:
        return OcalandColors.celeste.withValues(alpha: 0.35);
      case TipoCasilla.meta:
        return OcalandColors.verde.withValues(alpha: 0.5);
      case TipoCasilla.normal:
        return posicion == 0
            ? OcalandColors.violeta.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.55);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: _colorFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Text('$posicion', style: const TextStyle(fontSize: 9, color: Colors.black45)),
          ),
          if (tipo == TipoCasilla.oca)
            const OcaVueloAnimado()
          else if (tipo.esCasillaFlotante)
            CasillaTrampaAnimada(
              tipo: tipo,
              child: CasillaIconos.iconoEstatico.containsKey(tipo)
                  ? Image.asset(
                      CasillaIconos.iconoEstatico[tipo]!,
                      height: 30,
                      cacheHeight: 90,
                    )
                  : Text(tipo.emoji, style: const TextStyle(fontSize: 26)),
            )
          else if (tipo == TipoCasilla.meta)
            Text(tipo.emoji, style: const TextStyle(fontSize: 16)),
          Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tieneJugador)
                  spriteJugador != null
                      ? _FichaSprite(
                          frames: spriteJugador!,
                          indice: frameJugador,
                        )
                      : const _Ficha(color: OcalandColors.violeta, letra: 'J'),
                if (tieneJugador && tieneBot) const SizedBox(width: 2),
                if (tieneBot)
                  spriteBot != null
                      ? _FichaSprite(frames: spriteBot!, indice: frameBot)
                      : const _Ficha(color: OcalandColors.fucsia, letra: 'B'),
              ],
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
    return SizedBox(
      height: 34,
      child: Image.asset(
        frames[indice % frames.length],
        height: 34,
        cacheHeight: 100,
        fit: BoxFit.contain,
      ),
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
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        letra,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
