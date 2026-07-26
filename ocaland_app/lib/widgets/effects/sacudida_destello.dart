import 'dart:math';

import 'package:flutter/material.dart';

/// Controlador imperativo para disparar la sacudida+destello rojo desde
/// fuera del widget (ej. al resolver una respuesta incorrecta).
class SacudidaDestelloController {
  VoidCallback? _disparar;

  void disparar() => _disparar?.call();
}

/// Sacudida breve + destello rojo al fallar Cuestionados (spec visual v2,
/// sección 5) — ya existía en el prototipo HTML, portado acá.
class SacudidaDestello extends StatefulWidget {
  const SacudidaDestello({
    super.key,
    required this.controller,
    required this.child,
  });

  final SacudidaDestelloController controller;
  final Widget child;

  @override
  State<SacudidaDestello> createState() => _SacudidaDestelloState();
}

class _SacudidaDestelloState extends State<SacudidaDestello>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    widget.controller._disparar = () => _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final desplazamiento = sin(t * pi * 6) * (1 - t) * 10;
        return Transform.translate(
          offset: Offset(desplazamiento, 0),
          child: Stack(
            children: [
              child!,
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0) * (t > 0 ? 0.25 : 0),
                  child: Container(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
