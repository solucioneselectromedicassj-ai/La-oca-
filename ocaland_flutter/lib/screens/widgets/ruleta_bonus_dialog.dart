import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/economy_service.dart';
import '../../theme/app_colors.dart';

const _segmentos = ['x1', 'x1.5', 'x2', 'x3', 'Nada', 'x1'];
const _colores = [AppColors.green, AppColors.lemon, AppColors.turquoise, AppColors.sky, AppColors.coral, AppColors.magenta];

/// Ruleta de bonus diaria. Antes era solo un spinner circular genérico
/// mientras esperaba la respuesta del servidor — no se veía "girar" nada.
/// Ahora dibuja una rueda de verdad (mismo estilo que la del premio de
/// etapa): gira rápido mientras se resuelve el pedido y frena con una
/// desaceleración, recién ahí se muestra el resultado.
class RuletaBonusDialog extends StatefulWidget {
  final String usuarioId;
  const RuletaBonusDialog({super.key, required this.usuarioId});

  @override
  State<RuletaBonusDialog> createState() => _RuletaBonusDialogState();
}

class _RuletaBonusDialogState extends State<RuletaBonusDialog> with TickerProviderStateMixin {
  bool _girando = false;
  String? _resultado;

  late final AnimationController _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _settleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  double _baseAngle = 0;
  double _settleFrom = 0;
  double _settleTo = 0;

  double get _anguloActual {
    if (_spinCtrl.isAnimating) return _baseAngle + _spinCtrl.value * 2 * pi;
    if (_settleCtrl.value > 0) {
      final t = Curves.easeOutCubic.transform(_settleCtrl.value);
      return _settleFrom + (_settleTo - _settleFrom) * t;
    }
    return _baseAngle;
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _settleCtrl.dispose();
    super.dispose();
  }

  Future<void> _girar() async {
    setState(() {
      _girando = true;
      _resultado = null;
    });
    AudioService.sorteo();
    _settleCtrl.value = 0;
    _spinCtrl.repeat();

    RuletaBonusResultado? r;
    Object? error;
    try {
      final resultados = await Future.wait([
        EconomyService.girarRuletaBonus(widget.usuarioId),
        Future.delayed(const Duration(milliseconds: 1300)), // giro mínimo, aunque la red responda al toque
      ]);
      r = resultados[0] as RuletaBonusResultado?;
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    _spinCtrl.stop();
    _baseAngle += _spinCtrl.value * 2 * pi;
    _spinCtrl.value = 0;
    _settleFrom = _baseAngle;
    _settleTo = _baseAngle + 2 * pi * 2 + Random().nextDouble() * 2 * pi;
    await _settleCtrl.forward(from: 0);
    _baseAngle = _settleTo;
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _resultado = 'No pudimos conectar con el servidor.';
        _girando = false;
      });
      return;
    }
    if (r == null || r.yaUsado) {
      setState(() {
        _resultado = '⏳ Ya usaste tu giro de hoy. Volvé mañana.';
        _girando = false;
      });
    } else if (r.valor > 1) {
      AudioService.win();
      setState(() {
        _resultado = '🎉 ¡Conseguiste x${r!.valor.toStringAsFixed(r.valor == r.valor.roundToDouble() ? 0 : 1)} monedas por ${r.minutosDuracion} minutos!';
        _girando = false;
      });
    } else {
      setState(() {
        _resultado = '😅 Nada esta vez. Probá de nuevo mañana.';
        _girando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.parchment,
      title: const Text('🎰 Ruleta de bonus'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Girá una vez por día para conseguir un multiplicador de monedas por un rato.', style: TextStyle(fontSize: 12.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: 180,
            height: 196,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 26,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spinCtrl, _settleCtrl]),
                    builder: (context, child) => Transform.rotate(angle: _anguloActual, child: child),
                    child: CustomPaint(size: const Size(160, 160), painter: _BonusWheelPainter()),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 36, color: AppColors.violetDark),
              ],
            ),
          ),
          if (_resultado != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_resultado!, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
      actions: [
        if (_resultado == null)
          ElevatedButton(
            onPressed: _girando ? null : _girar,
            child: const Text('Girar'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}

class _BonusWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segAngle = 2 * pi / _segmentos.length;

    for (var i = 0; i < _segmentos.length; i++) {
      final startAngle = -pi / 2 + i * segAngle;
      final paint = Paint()..color = _colores[i % _colores.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, segAngle, true, paint);
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;
    for (var i = 0; i < _segmentos.length; i++) {
      final angle = -pi / 2 + i * segAngle;
      final p = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, p, linePaint);
    }

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.violetDark,
    );

    for (var i = 0; i < _segmentos.length; i++) {
      final midAngle = -pi / 2 + (i + 0.5) * segAngle;
      final txtRadius = radius * 0.62;
      final pos = Offset(center.dx + txtRadius * cos(midAngle), center.dy + txtRadius * sin(midAngle));
      final tp = TextPainter(
        text: TextSpan(text: _segmentos[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BonusWheelPainter oldDelegate) => false;
}
