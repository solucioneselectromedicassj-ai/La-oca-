import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/paisaje_iconos.dart';

/// Fondo del tablero como paisaje continuo: cielo con sol y nubes, una
/// sola colina con textura de pasto (no color plano) y decoración real
/// (árboles, arbustos, rocas, flores) repartida en toda la altura del
/// tablero — no unos pocos íconos sueltos en puntos fijos, sino una
/// franja de vegetación que acompaña TODO el camino, para que se sienta
/// un escenario continuo y no piezas pegadas. Los colores de la colina
/// salen de la paleta del bloque de etapas actual.
///
/// [trampolinesPx] son las posiciones (en píxeles, en el mismo sistema
/// de coordenadas que el `size` de este widget) de las casillas de
/// trampolín del layout actual — así el agua y el puente real aparecen
/// justo donde hay una casilla de trampolín, no en un lugar arbitrario.
class FondoCandy extends StatelessWidget {
  const FondoCandy({
    super.key,
    required this.gradiente,
    required this.acento,
    required this.trampolinesPx,
    this.fondoAsset,
  });

  final List<Color> gradiente;
  final Color acento;
  final List<Offset> trampolinesPx;

  /// Fondo de escena real (arte del usuario), repetido verticalmente
  /// para cubrir todo el tablero. Si es `null`, se usa el fondo
  /// genérico (colina de color + pasto dibujado).
  final String? fondoAsset;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  Color _mezclar(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    final verdeBase = _mezclar(const Color(0xFF9CCC65), acento, 0.25);
    final verdeOscuro = _oscurecer(verdeBase, 0.18);
    const azulAgua = Color(0xFF4FC3F7);
    final agua = _mezclar(azulAgua, acento, 0.15);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (fondoAsset != null)
              // Escena real de fondo (arte del usuario), repetida
              // verticalmente — ya trae cielo, suelo y árboles pintados,
              // así que no hace falta la colina/pasto genéricos.
              DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(fondoAsset!),
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              )
            else ...[
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
              // Una sola colina, arranca bien arriba para que el camino
              // nunca quede flotando sobre el cielo vacío.
              Positioned.fill(child: CustomPaint(painter: _ColinaPainter(verdeBase))),
              // Textura de pasto sobre TODA la colina (no color liso).
              Positioned.fill(child: CustomPaint(painter: _PastoPainter(verdeOscuro))),
            ],
            Align(alignment: const Alignment(0.75, -0.94), child: _sol()),
            Align(
              alignment: const Alignment(-0.55, -0.92),
              child: Image.asset(PaisajeIconos.nube1, width: 92, cacheWidth: 184),
            ),
            Align(
              alignment: const Alignment(0.5, -0.86),
              child: Image.asset(PaisajeIconos.nube2, width: 78, cacheWidth: 156),
            ),
            // Decoración real repartida en toda la altura del tablero,
            // a los costados del camino — no unos pocos íconos sueltos.
            ..._decoracionesDelCamino(size),
            // Agua real + puente real, anclados a cada casilla de trampolín.
            for (final p in trampolinesPx) ..._puenteEnPunto(p, agua),
          ],
        );
      },
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
            gradient: RadialGradient(colors: [Color(0x66FFE082), Color(0x00FFE082)]),
          ),
        ),
        Image.asset(PaisajeIconos.sol, width: 62, cacheWidth: 124),
      ],
    );
  }

  List<Widget> _puenteEnPunto(Offset p, Color agua) {
    return [
      Positioned(
        left: p.dx - 70,
        top: p.dy - 18,
        child: Image.asset(PaisajeIconos.agua, width: 140, cacheWidth: 220),
      ),
      Positioned(
        left: p.dx - 55,
        top: p.dy - 62,
        child: Image.asset(PaisajeIconos.puente, width: 110, cacheWidth: 220),
      ),
    ];
  }

  /// Genera decoración (árboles/arbustos/rocas/flores) a intervalos
  /// regulares en TODA la altura del canvas, alternando de lado, con
  /// semilla fija para que no cambie en cada rebuild (parpadeo).
  List<Widget> _decoracionesDelCamino(Size size) {
    final rng = Random(23);
    const assets = [
      PaisajeIconos.arbolFrondoso,
      PaisajeIconos.arbolPino,
      PaisajeIconos.arbusto,
      PaisajeIconos.rocas,
      PaisajeIconos.flores,
    ];
    final widgets = <Widget>[];
    var y = size.height * 0.13;
    var lado = rng.nextBool();
    while (y < size.height * 0.98) {
      final asset = assets[rng.nextInt(assets.length)];
      final ancho = 34.0 + rng.nextDouble() * 28;
      final xFrac = lado ? (0.05 + rng.nextDouble() * 0.09) : (0.95 - rng.nextDouble() * 0.09);
      widgets.add(
        Positioned(
          left: size.width * xFrac - ancho / 2,
          top: y,
          child: Image.asset(asset, width: ancho, cacheWidth: (ancho * 2).round()),
        ),
      );
      y += 95 + rng.nextDouble() * 70;
      lado = !lado;
    }
    return widgets;
  }
}

/// Silueta de colina única (no dos capas): cubre casi todo el canvas
/// desde arriba, con un borde ondulado suave (no una línea horizontal
/// recta) para que se sienta terreno, no un bloque de color.
class _ColinaPainter extends CustomPainter {
  _ColinaPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * 0.1);
    const pasos = 40;
    for (var i = 0; i <= pasos; i++) {
      final x = size.width * i / pasos;
      final y = size.height * 0.1 + sin(i / pasos * 3.2 * pi) * size.height * 0.012;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ColinaPainter oldDelegate) => oldDelegate.color != color;
}

/// Textura de pasto: matitas sueltas repartidas por toda la colina
/// (semilla fija, no cambia en cada rebuild) para que el terreno no se
/// vea como un color plano liso.
class _PastoPainter extends CustomPainter {
  _PastoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(11);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cantidad = (size.height / 9).round().clamp(100, 1400);
    for (var i = 0; i < cantidad; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.1 + rng.nextDouble() * size.height * 0.9;
      final alto = 5 + rng.nextDouble() * 6;
      final inclinacion = (rng.nextDouble() - 0.5) * 4;
      canvas.drawLine(Offset(x, y), Offset(x + inclinacion, y - alto), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PastoPainter oldDelegate) => false;
}
