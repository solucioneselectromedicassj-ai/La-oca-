import 'package:flutter/material.dart';

import '../../game/board_layout.dart';
import '../../game/casilla.dart';
import '../../theme/ocaland_theme.dart';

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
  });

  final BoardLayout layout;
  final int posJugador;
  final int posBot;

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
  });

  final int posicion;
  final TipoCasilla tipo;
  final bool tieneJugador;
  final bool tieneBot;

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
            : Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _colorFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Text('$posicion', style: const TextStyle(fontSize: 9, color: Colors.black45)),
          ),
          if (tipo != TipoCasilla.normal)
            Text(tipo.emoji, style: const TextStyle(fontSize: 16)),
          Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tieneJugador) const _Ficha(color: OcalandColors.violeta, letra: 'J'),
                if (tieneJugador && tieneBot) const SizedBox(width: 2),
                if (tieneBot) const _Ficha(color: OcalandColors.fucsia, letra: 'B'),
              ],
            ),
          ),
        ],
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
