import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo del tablero como paisaje ilustrado (no un degradé vacío): cielo
/// con nubes, y colinas en capas para dar sensación de profundidad
/// (2.5D), todo en el mismo estilo plano tipo Candy Crush del resto del
/// arte (nada fotorrealista). Los colores salen de la paleta del bloque
/// de etapas actual, así el paisaje también cambia con la campaña.
class FondoCandy extends StatelessWidget {
  const FondoCandy({super.key, required this.gradiente, required this.acento});

  final List<Color> gradiente;
  final Color acento;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final colinaLejos = _oscurecer(gradiente.last, 0.06);
    final colinaMedia = _oscurecer(gradiente.last, 0.16);
    final colinaCerca = _oscurecer(gradiente.last, 0.26);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cielo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradiente,
            ),
          ),
        ),
        // Nubes flotando en el cielo.
        Positioned.fill(child: CustomPaint(painter: _NubesPainter(acento))),
        // Manchas de color suaves (magia/luz ambiente) detrás de las colinas.
        _mancha(top: -50, left: -60, diametro: 220, color: acento),
        _mancha(top: 110, right: -70, diametro: 240, color: gradiente.first),
        // Colinas en 3 capas para dar profundidad (más lejos = más clara).
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([
              _Colina(colinaLejos, 0.62, 14, 1.3, 0.0),
              _Colina(colinaMedia, 0.74, 18, 1.7, 1.4),
              _Colina(colinaCerca, 0.87, 16, 1.4, 2.6),
            ]),
          ),
        ),
        _brillito(-0.82, -0.86, tamano: 16),
        _brillito(0.72, -0.62, tamano: 12),
        _brillito(-0.6, -0.3, tamano: 14),
      ],
    );
  }

  Widget _mancha({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double diametro,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _brillito(double fx, double fy, {double tamano = 16, double opacidad = 0.55}) {
    return Align(
      alignment: Alignment(fx, fy),
      child: Icon(
        Icons.star_rounded,
        size: tamano,
        color: Colors.white.withValues(alpha: opacidad),
      ),
    );
  }
}

class _Colina {
  const _Colina(this.color, this.baseY, this.amplitud, this.frecuencia, this.fase);

  final Color color;

  /// Altura base de la colina, como fracción de la altura del canvas.
  final double baseY;
  final double amplitud;
  final double frecuencia;
  final double fase;
}

class _ColinasPainter extends CustomPainter {
  _ColinasPainter(this.colinas);

  final List<_Colina> colinas;

  @override
  void paint(Canvas canvas, Size size) {
    for (final colina in colinas) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, colina.baseY * size.height);
      const pasos = 24;
      for (var i = 0; i <= pasos; i++) {
        final x = size.width * i / pasos;
        final y = colina.baseY * size.height +
            colina.amplitud * sin((i / pasos) * colina.frecuencia * 2 * pi + colina.fase);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = colina.color);
    }
  }

  @override
  bool shouldRepaint(covariant _ColinasPainter oldDelegate) => false;
}

class _NubesPainter extends CustomPainter {
  _NubesPainter(this.acento);

  final Color acento;

  void _nube(Canvas canvas, Offset centro, double escala, Paint paint) {
    for (final off in const [
      Offset(-0.5, 0.05),
      Offset(-0.15, -0.12),
      Offset(0.2, -0.08),
      Offset(0.5, 0.05),
      Offset(0, 0.12),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centro + Offset(off.dx * 90 * escala, off.dy * 60 * escala),
          width: 70 * escala,
          height: 42 * escala,
        ),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    _nube(canvas, Offset(size.width * 0.28, size.height * 0.09), 0.7, paint);
    _nube(canvas, Offset(size.width * 0.78, size.height * 0.16), 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant _NubesPainter oldDelegate) => false;
}
