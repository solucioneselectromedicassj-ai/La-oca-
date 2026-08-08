import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/wheel_prizes.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

const _wheelColors = [
  AppColors.green, AppColors.lemon, AppColors.turquoise, AppColors.sky, AppColors.coral, AppColors.magenta,
];

/// Ruleta con divisiones reales (una por premio, con su ícono) y un
/// puntero fijo arriba — antes era solo un gradiente sin marcar nada,
/// así que no se entendía ni dónde empezaba/terminaba ni qué se podía
/// ganar. Ahora gira de verdad hasta frenar en el premio que ya salió
/// sorteado (controller.wheelPremioIdx), no es un giro genérico.
class RuletaOverlay extends StatefulWidget {
  final bool girando;
  final bool listaParaContinuar;
  final String resultado;
  final int? premioIdx;
  final VoidCallback onGirar;
  final VoidCallback onContinuar;

  const RuletaOverlay({
    super.key,
    required this.girando,
    required this.listaParaContinuar,
    required this.resultado,
    required this.premioIdx,
    required this.onGirar,
    required this.onContinuar,
  });

  @override
  State<RuletaOverlay> createState() => _RuletaOverlayState();
}

class _RuletaOverlayState extends State<RuletaOverlay> with SingleTickerProviderStateMixin {
  static final _segAngle = 2 * pi / wheelPrizes.length;

  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  Tween<double>? _tween;
  double _rotacion = 0;

  @override
  void didUpdateWidget(covariant RuletaOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.girando && !oldWidget.girando && widget.premioIdx != null) {
      _arrancarGiro(widget.premioIdx!);
    }
  }

  void _arrancarGiro(int idx) {
    var deseadoMod = (-idx * _segAngle) % (2 * pi);
    if (deseadoMod < 0) deseadoMod += 2 * pi;
    final actualMod = _rotacion % (2 * pi);
    var delta = deseadoMod - actualMod;
    if (delta <= 0) delta += 2 * pi;
    final destino = _rotacion + delta + 2 * pi * 5; // vueltas extra para que se sienta el giro
    _tween = Tween<double>(begin: _rotacion, end: destino);
    _ctrl.forward(from: 0).whenComplete(() => _rotacion = destino);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉 ¡Etapa superada!', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 6),
          const Text('¡Girá la ruleta de premios!'),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            height: 236,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 36,
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      final t = _tween;
                      final angle = t != null ? t.transform(Curves.easeOutCubic.transform(_ctrl.value)) : _rotacion;
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: CustomPaint(size: const Size(200, 200), painter: _WheelPainter()),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 44, color: AppColors.violetDark),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (!widget.listaParaContinuar)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.girando ? null : widget.onGirar, child: const Text('Girar ruleta'))),
          if (widget.resultado.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.resultado, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.violetDark))),
          if (widget.listaParaContinuar)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.onContinuar, child: const Text('Continuar a la siguiente etapa'))),
            ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final prizes = wheelPrizes;
    final segAngle = 2 * pi / prizes.length;

    for (var i = 0; i < prizes.length; i++) {
      final startAngle = -pi / 2 + i * segAngle;
      final paint = Paint()..color = _wheelColors[i % _wheelColors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, segAngle, true, paint);
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    for (var i = 0; i < prizes.length; i++) {
      final angle = -pi / 2 + i * segAngle;
      final p = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, p, linePaint);
    }

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.violetDark,
    );

    for (var i = 0; i < prizes.length; i++) {
      final midAngle = -pi / 2 + (i + 0.5) * segAngle;
      final iconRadius = radius * 0.62;
      final pos = Offset(center.dx + iconRadius * cos(midAngle), center.dy + iconRadius * sin(midAngle));
      final tp = TextPainter(
        text: TextSpan(text: prizes[i]['icon'], style: const TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
