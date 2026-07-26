import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/casilla.dart';

/// Animación de reposo (idle, en loop) de las casillas de trampa, para que
/// el tablero se sienta vivo mientras nadie las toca (spec visual v2,
/// sección 4). Cada tipo tiene su propio gesto sugerido por la spec:
/// la oca aletea, el puente se balancea, la cárcel vibra, la calavera
/// flota y el minijuego pulsa con brillitos.
class CasillaTrampaAnimada extends StatefulWidget {
  const CasillaTrampaAnimada({super.key, required this.tipo, required this.child});

  final TipoCasilla tipo;
  final Widget child;

  @override
  State<CasillaTrampaAnimada> createState() => _CasillaTrampaAnimadaState();
}

class _CasillaTrampaAnimadaState extends State<CasillaTrampaAnimada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duracionDe(widget.tipo),
  )..repeat();

  static Duration _duracionDe(TipoCasilla tipo) {
    switch (tipo) {
      case TipoCasilla.carcel:
        return const Duration(milliseconds: 900);
      case TipoCasilla.minijuego:
        return const Duration(milliseconds: 1400);
      default:
        return const Duration(milliseconds: 2000);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tipo.esCasillaFlotante) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        switch (widget.tipo) {
          case TipoCasilla.oca:
            return Transform.rotate(angle: sin(t * 2 * pi) * 0.14, child: child);

          case TipoCasilla.puente:
            return Transform.rotate(angle: sin(t * 2 * pi) * 0.07, child: child);

          case TipoCasilla.carcel:
            return Transform.translate(
              offset: Offset(sin(t * 2 * pi * 5) * 1.6, 0),
              child: child,
            );

          case TipoCasilla.calavera:
            return Transform.translate(
              offset: Offset(0, sin(t * 2 * pi) * 5),
              child: child,
            );

          case TipoCasilla.minijuego:
            final escala = 1 + sin(t * 2 * pi) * 0.1;
            final brillo = (sin(t * 2 * pi * 2) + 1) / 2;
            return Transform.scale(
              scale: escala,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  child!,
                  Opacity(
                    opacity: brillo * 0.8,
                    child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  ),
                ],
              ),
            );

          default:
            return child!;
        }
      },
    );
  }
}
