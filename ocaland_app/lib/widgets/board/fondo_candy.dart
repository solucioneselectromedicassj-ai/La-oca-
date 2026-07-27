import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo del tablero como paisaje ilustrado: cielo con sol y nubes,
/// colinas en capas con charcos de río bajo cada casilla de puente
/// (para que el puente real quede "cruzando" el agua en vez de flotar
/// sobre nada), y árboles a los costados del camino. Todo con formas
/// vectoriales en código (sin arte nuevo), en el mismo estilo plano
/// tipo Candy Crush del resto del arte. Los colores salen de la
/// paleta del bloque de etapas actual.
///
/// [puentesPx] son las posiciones (en píxeles, en el mismo sistema de
/// coordenadas que el `size` de este widget) de las casillas de puente
/// del layout actual — así el agua aparece justo donde hay un puente
/// real dibujado encima, no en un lugar arbitrario del camino.
class FondoCandy extends StatelessWidget {
  const FondoCandy({
    super.key,
    required this.gradiente,
    required this.acento,
    required this.puentesPx,
  });

  final List<Color> gradiente;
  final Color acento;
  final List<Offset> puentesPx;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  Color _mezclar(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    // Base de pasto verde (no del degradé del cielo): si tomáramos el
    // color del cielo, en bloques con cielo celeste/violeta las colinas
    // se confunden con el agua y todo el fondo lee como "mar", no tierra.
    final verdeBase = _mezclar(const Color(0xFF9CCC65), acento, 0.25);
    final colinaLejos = verdeBase;
    final colinaCerca = _oscurecer(verdeBase, 0.16);
    const azulAgua = Color(0xFF4FC3F7);
    final agua = _mezclar(azulAgua, acento, 0.15);
    final verdeArbol = _mezclar(const Color(0xFF66BB6A), acento, 0.2);
    final verdeArbolOscuro = _oscurecer(verdeArbol, 0.14);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cielo (solo se asoma una franja arriba del todo: el resto es
        // tierra, para que ninguna casilla quede flotando en el cielo).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradiente,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.78, -0.92),
          child: _sol(),
        ),
        Positioned.fill(child: CustomPaint(painter: _NubesPainter())),
        // Colina lejana, arranca bien arriba.
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([_Colina(colinaLejos, 0.1, 16, 1.2, 0.0)]),
          ),
        ),
        // Charcos de río bajo cada casilla de puente real.
        if (puentesPx.isNotEmpty)
          Positioned.fill(child: CustomPaint(painter: _RioPainter(agua, puentesPx))),
        // Colina cercana (primer plano).
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([_Colina(colinaCerca, 0.5, 18, 1.4, 2.2)]),
          ),
        ),
        // Árboles a los costados, para que no se sienta vacío.
        _arbol(const Alignment(-0.92, -0.55), 30, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(0.9, -0.7), 24, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(-0.85, 0.15), 42, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(0.88, 0.05), 34, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(-0.7, 0.75), 46, verdeArbol, verdeArbolOscuro),
        _arbol(const Alignment(0.75, 0.82), 36, verdeArbol, verdeArbolOscuro),
        _brillito(-0.82, -0.35, tamano: 14),
        _brillito(0.6, 0.4, tamano: 12),
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
    // Copa con 3 lóbulos superpuestos (en vez de un solo círculo) y una
    // sombra ovalada en la base, para que no se vea como un simple
    // palito con una bolita.
    return Align(
      alignment: alineacion,
      child: SizedBox(
        width: alto * 1.3,
        height: alto + altoTronco * 0.7,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: alto * 0.7,
                height: alto * 0.16,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              bottom: altoTronco * 0.15,
              child: Container(
                width: anchoTronco,
                height: altoTronco,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D5A3B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            for (final lobulo in const [
              Offset(-0.32, 0.08),
              Offset(0.32, 0.1),
              Offset(0.0, -0.18),
            ])
              Positioned(
                bottom: altoTronco * 0.55 - lobulo.dy * alto,
                left: alto * 0.15 + lobulo.dx * alto,
                child: Container(
                  width: alto * 0.72,
                  height: alto * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [canopia, canopiaOscura],
                      center: const Alignment(-0.3, -0.4),
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
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

/// Charco/tramo de río bajo cada casilla de puente real, para que el
/// puente se vea "cruzando" agua en vez de flotar sobre pasto vacío.
class _RioPainter extends CustomPainter {
  _RioPainter(this.color, this.puntos);

  final Color color;
  final List<Offset> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    // Charco angosto (no una franja que cruce toda la pantalla): solo
    // un poco más ancho que la propia casilla de puente, para que se
    // vea como un tramo corto de arroyo bajo el puente, no un río que
    // corta el tablero sin conexión visual con la casilla.
    for (final p in puntos) {
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 96, height: 30),
        Paint()..color = color,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 64, height: 10),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RioPainter oldDelegate) => oldDelegate.puntos != puntos;
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
    _nube(canvas, Offset(size.width * 0.24, size.height * 0.055), 0.6, paint);
    _nube(canvas, Offset(size.width * 0.62, size.height * 0.035), 0.42, paint);
  }

  @override
  bool shouldRepaint(covariant _NubesPainter oldDelegate) => false;
}
