import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/ocaland_theme.dart';

/// Confeti cayendo al ganar una etapa/partida (spec visual v2, sección 5).
/// Efecto puro en código (sin asset gráfico), vía `CustomPainter`.
class ConfetiOverlay extends StatefulWidget {
  const ConfetiOverlay({super.key, required this.onTerminado});

  final VoidCallback onTerminado;

  @override
  State<ConfetiOverlay> createState() => _ConfetiOverlayState();
}

class _Particula {
  _Particula(Random rng)
      : x = rng.nextDouble(),
        retraso = rng.nextDouble() * 0.3,
        velocidad = 0.7 + rng.nextDouble() * 0.6,
        angulo = rng.nextDouble() * 2 * pi,
        velocidadAngular = (rng.nextDouble() - 0.5) * 6,
        tamano = 6 + rng.nextDouble() * 6,
        color = _colores[rng.nextInt(_colores.length)];

  final double x;
  final double retraso;
  final double velocidad;
  final double angulo;
  final double velocidadAngular;
  final double tamano;
  final Color color;

  static const _colores = [
    OcalandColors.violeta,
    OcalandColors.fucsia,
    OcalandColors.amarillo,
    OcalandColors.turquesa,
    OcalandColors.celeste,
    OcalandColors.verde,
  ];
}

class _ConfetiOverlayState extends State<ConfetiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particula> _particulas;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particulas = List.generate(50, (_) => _Particula(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfetiPainter(_particulas, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfetiPainter extends CustomPainter {
  _ConfetiPainter(this.particulas, this.progreso);

  final List<_Particula> particulas;
  final double progreso;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particulas) {
      final t = ((progreso - p.retraso) / (1 - p.retraso)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = t * p.velocidad * size.height;
      final opacidad = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacidad);
      final centro = Offset(p.x * size.width, y);
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(p.angulo + p.velocidadAngular * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.tamano, height: p.tamano * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetiPainter oldDelegate) => true;
}
