import 'dart:math';

import 'package:flutter/material.dart';

/// Destello de estrellas al acertar Cuestionados (spec visual v2,
/// sección 5): estrellas que aparecen y se alejan del centro girando,
/// mientras se desvanecen.
class DestelloEstrellas extends StatefulWidget {
  const DestelloEstrellas({super.key, required this.onTerminado});

  final VoidCallback onTerminado;

  @override
  State<DestelloEstrellas> createState() => _DestelloEstrellasState();
}

class _EstrellaInfo {
  _EstrellaInfo(Random rng)
      : angulo = rng.nextDouble() * 2 * pi,
        distancia = 40 + rng.nextDouble() * 50,
        tamano = 14 + rng.nextDouble() * 14;

  final double angulo;
  final double distancia;
  final double tamano;
}

class _DestelloEstrellasState extends State<DestelloEstrellas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_EstrellaInfo> _estrellas;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _estrellas = List.generate(8, (_) => _EstrellaInfo(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onTerminado();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final e in _estrellas)
                  Transform.translate(
                    offset: Offset(cos(e.angulo), sin(e.angulo)) * (e.distancia * t),
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: t * 3,
                        child: Icon(Icons.star, color: Colors.amber, size: e.tamano),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
