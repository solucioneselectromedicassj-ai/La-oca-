import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/paisaje_iconos.dart';
import 'casilla_iconos.dart';

/// Fondo del tablero como paisaje continuo: cielo con sol y nubes, una
/// sola colina con textura de pasto (no color plano) y decoración real
/// (árboles, arbustos, rocas, flores) repartida en toda la altura del
/// tablero — no unos pocos íconos sueltos en puntos fijos, sino una
/// franja de vegetación que acompaña TODO el camino, para que se sienta
/// un escenario continuo y no piezas pegadas. Los colores de la colina
/// salen de la paleta del bloque de etapas actual.
///
class FondoCandy extends StatelessWidget {
  const FondoCandy({
    super.key,
    required this.gradiente,
    required this.acento,
    this.fondoAsset,
    this.fondoAspectRatio,
    this.fondoColorPie,
  });

  final List<Color> gradiente;
  final Color acento;

  /// Fondo de escena real (arte del usuario): se muestra UNA sola vez,
  /// a su tamaño natural, arriba del todo del tablero (ahí van el
  /// cielo y el inicio del camino). Si es `null`, se usa el fondo
  /// genérico (colina de color + pasto dibujado).
  final String? fondoAsset;
  final double? fondoAspectRatio;
  final Color? fondoColorPie;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  Color _mezclar(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    final verdeBase = _mezclar(const Color(0xFF9CCC65), acento, 0.25);
    final verdeOscuro = _oscurecer(verdeBase, 0.18);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final altoImagen =
            fondoAspectRatio != null ? size.width / fondoAspectRatio! : 0.0;
        final colorSuelo = fondoColorPie ?? verdeBase;
        final colorPasto = fondoColorPie != null ? _oscurecer(fondoColorPie!, 0.12) : verdeOscuro;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (fondoAsset != null) ...[
              // Suelo de base para TODO el tablero (se ve debajo de la
              // imagen real y llena el resto, más abajo), del mismo
              // color que el borde inferior de la imagen para que la
              // transición sea pareja.
              DecoratedBox(decoration: BoxDecoration(color: colorSuelo)),
              Positioned.fill(child: CustomPaint(painter: _PastoPainter(colorPasto))),
              // La imagen real, UNA sola vez, a su proporción natural,
              // arriba del todo — no estirada para cubrir todo el
              // tablero (eso desalineaba el cielo/nubes con el pasto y
              // el camino terminaba en cualquier lado).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: altoImagen,
                child: Image.asset(fondoAsset!, fit: BoxFit.cover, alignment: Alignment.topCenter),
              ),
            ] else ...[
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
            // El sol/nubes van pegados al borde de arriba (no más
            // abajo, como el cartel de INICIO): el camino arranca en
            // un x aleatorio (puede ser cualquier lado), así que
            // cualquier posición más baja corre el riesgo real de
            // quedar tapada por el cartel/avatares de salida.
            Align(alignment: const Alignment(0.7, -0.985), child: _sol()),
            Align(
              alignment: const Alignment(-0.6, -0.97),
              child: Image.asset(PaisajeIconos.nube1, width: 92, cacheWidth: 184),
            ),
            Align(
              alignment: const Alignment(0.15, -0.965),
              child: Image.asset(PaisajeIconos.nube2, width: 78, cacheWidth: 156),
            ),
            // Decoración real repartida en toda la altura del tablero,
            // a los costados del camino — no unos pocos íconos sueltos.
            ..._decoracionesDelCamino(size),
            // Unas pocas ocas volando de fondo, puramente decorativas
            // (no son casillas), para darle vida a la escena.
            ..._gansosVolando(size),
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
      // Pegados a los bordes de verdad (el camino puede curvar hasta
      // ~0.08-0.92 de ancho), para no quedar montados sobre el sendero.
      final xFrac = lado ? (0.0 + rng.nextDouble() * 0.05) : (1.0 - rng.nextDouble() * 0.05);
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

  /// Un par de ocas volando de fondo (decoración, no casillas), para
  /// que la escena se sienta con más vida — semilla fija.
  List<Widget> _gansosVolando(Size size) {
    final rng = Random(41);
    final fracs = [0.22, 0.48, 0.74];
    return [
      for (final f in fracs)
        Positioned(
          left: size.width * (0.2 + rng.nextDouble() * 0.6),
          top: size.height * f,
          child: Opacity(
            opacity: 0.85,
            child: Image.asset(CasillaIconos.framesOca[0], width: 26, cacheWidth: 52),
          ),
        ),
    ];
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
