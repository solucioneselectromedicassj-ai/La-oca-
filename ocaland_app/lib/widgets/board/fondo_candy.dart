import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo del tablero como paisaje ilustrado: cielo con sol y nubes,
/// colinas en capas con un río en el medio, y árboles a los costados
/// del camino — para que el camino se sienta "parado" sobre el terreno
/// en vez de flotando sobre un degradé vacío. Todo con formas
/// vectoriales en código (sin arte nuevo), en el mismo estilo plano
/// tipo Candy Crush del resto del arte. Los colores salen de la
/// paleta del bloque de etapas actual.
class FondoCandy extends StatelessWidget {
  const FondoCandy({super.key, required this.gradiente, required this.acento});

  final List<Color> gradiente;
  final Color acento;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  Color _mezclar(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    // Base de pasto verde (no del degradé del cielo): si tomáramos el
    // color del cielo, en bloques con cielo celeste/violeta las colinas
    // se confunden con el río y todo el fondo lee como "agua", no como
    // tierra. El acento del bloque solo lo matiza un poco.
    final verdeBase = _mezclar(const Color(0xFF9CCC65), acento, 0.25);
    final colinaLejos = verdeBase;
    final colinaMedia = _oscurecer(verdeBase, 0.1);
    final colinaCerca = _oscurecer(verdeBase, 0.22);
    const azulAgua = Color(0xFF4FC3F7);
    final agua = _mezclar(azulAgua, acento, 0.15);
    final verdeArbol = _mezclar(const Color(0xFF66BB6A), acento, 0.2);
    final verdeArbolOscuro = _oscurecer(verdeArbol, 0.14);

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
        // Sol arriba, con resplandor detrás.
        Align(
          alignment: const Alignment(0.78, -0.92),
          child: _sol(),
        ),
        Positioned.fill(child: CustomPaint(painter: _NubesPainter())),
        // Colinas lejanas: arrancan bien arriba para que el camino
        // siempre esté "parado" sobre tierra, nunca flotando en el cielo.
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([
              _Colina(colinaLejos, 0.22, 16, 1.2, 0.0),
              _Colina(colinaMedia, 0.4, 18, 1.5, 1.6),
            ]),
          ),
        ),
        // Río entre las colinas lejanas y la cercana.
        Positioned.fill(child: CustomPaint(painter: _RioPainter(agua, 0.55))),
        // Colina cercana (primer plano), tapa la parte de abajo del río.
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([
              _Colina(colinaCerca, 0.86, 16, 1.4, 2.6),
            ]),
          ),
        ),
        // Árboles a los costados, para que no se sienta vacío.
        _arbol(const Alignment(-0.92, 0.05), 44, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(0.9, -0.15), 32, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(-0.85, 0.62), 52, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(0.88, 0.55), 40, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(-0.7, -0.55), 26, verdeArbol, verdeArbolOscuro),
        _brillito(-0.82, -0.6, tamano: 14),
        _brillito(0.6, 0.15, tamano: 12),
      ],
    );
  }

  Widget _sol() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x66FFE082), Color(0x00FFE082)],
            ),
          ),
        ),
        const Icon(Icons.wb_sunny_rounded, size: 56, color: Color(0xFFFFC94D)),
      ],
    );
  }

  Widget _arbol(Alignment alineacion, double alto, Color canopia, Color canopiaOscura) {
    final anchoTronco = alto * 0.16;
    final altoTronco = alto * 0.32;
    return Align(
      alignment: alineacion,
      child: SizedBox(
        width: alto,
        height: alto + altoTronco * 0.6,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: anchoTronco,
                height: altoTronco,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D5A3B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Positioned(
              bottom: altoTronco * 0.5,
              child: Container(
                width: alto,
                height: alto,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [canopia, canopiaOscura],
                    center: const Alignment(-0.3, -0.4),
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
            ),
          ],
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

/// Franja de río horizontal ondulada, con una segunda pasada más clara
/// encima simulando el brillo del agua.
class _RioPainter extends CustomPainter {
  _RioPainter(this.color, this.baseY);

  final Color color;
  final double baseY;

  Path _onda(Size size, double amplitud, double frecuencia, double fase) {
    final path = Path();
    const pasos = 24;
    for (var i = 0; i <= pasos; i++) {
      final x = size.width * i / pasos;
      final y = baseY * size.height + amplitud * sin((i / pasos) * frecuencia * 2 * pi + fase);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _onda(size, 10, 1.3, 0.4),
      Paint()
        ..color = color
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _onda(size, 10, 1.3, 0.4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RioPainter oldDelegate) => false;
}

class _NubesPainter extends CustomPainter {
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
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    _nube(canvas, Offset(size.width * 0.24, size.height * 0.07), 0.65, paint);
    _nube(canvas, Offset(size.width * 0.62, size.height * 0.05), 0.45, paint);
  }

  @override
  bool shouldRepaint(covariant _NubesPainter oldDelegate) => false;
}
