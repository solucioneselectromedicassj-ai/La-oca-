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
    required this.camino,
    this.fondoAsset,
    this.fondoAspectRatio,
    this.fondoColorPie,
  });

  final List<Color> gradiente;
  final Color acento;

  /// Posiciones (fraccionales 0..1) del camino, para poder decorar
  /// justo en los "codos" del sendero (donde tuerce) en vez de solo en
  /// los bordes del canvas.
  final List<Offset> camino;

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
            // El sol va arriba de todo, dentro de la franja de imagen
            // real (o de cielo genérico si no hay imagen) — nunca
            // centrado por fracción sobre el canvas COMPLETO, que es
            // mucho más alto que esa franja: con el tablero compactado
            // y los fondos recortados, un sol de tamaño fijo centrado
            // así se salía de la franja real y su halo terminaba
            // pisando el pasto de abajo. El tamaño y la posición salen
            // de `altoImagen` (o del 10% de alto que usa el cielo
            // genérico) para que siempre quede contenido ahí.
            //
            // Las nubes sueltas (`nube1`/`nube2`) se sacaron: el
            // usuario las pidió afuera directamente (no eran parte del
            // paisaje real que subió y se seguían viendo pegadas al
            // cartel de INICIO).
            Builder(builder: (context) {
              final cieloAlto = fondoAsset != null ? altoImagen : size.height * 0.1;
              final tamanoIcono = (cieloAlto * 0.42).clamp(18.0, 36.0);
              return Positioned(
                right: size.width * 0.1,
                top: cieloAlto * 0.05,
                child: _sol(tamanoIcono),
              );
            }),
            // Decoración real repartida en toda la altura del tablero,
            // a los costados del camino — no unos pocos íconos sueltos.
            ..._decoracionesDelCamino(size),
            // El doble de decoración, esta vez puntual en los "codos"
            // del sendero (donde tuerce), en el espacio verde que deja
            // la curva — no solo pegada a los bordes del canvas.
            ..._decoracionesEnCodos(size),
            // Unas pocas ocas volando de fondo, puramente decorativas
            // (no son casillas), para darle vida a la escena.
            ..._gansosVolando(size),
          ],
        );
      },
    );
  }

  Widget _sol(double tamanoIcono) {
    final tamanoHalo = tamanoIcono * 1.8;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: tamanoHalo,
          height: tamanoHalo,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color(0x66FFE082), Color(0x00FFE082)]),
          ),
        ),
        Image.asset(
          PaisajeIconos.sol,
          width: tamanoIcono,
          cacheWidth: (tamanoIcono * 2).round(),
        ),
      ],
    );
  }

  /// Genera decoración (árboles/arbustos/rocas/flores) a intervalos
  /// regulares en TODA la altura del canvas, alternando de lado, con
  /// semilla fija para que no cambie en cada rebuild (parpadeo).
  List<Widget> _decoracionesDelCamino(Size size) {
    final rng = Random(23);
    // Rocas y flores repetidas a propósito: el usuario pidió más
    // densidad de esas dos justamente (no más árboles/arbustos, que ya
    // abundaban) en la franja de pasto de relleno debajo de la imagen
    // real.
    const assets = [
      PaisajeIconos.arbolFrondoso,
      PaisajeIconos.arbolPino,
      PaisajeIconos.arbusto,
      PaisajeIconos.rocas,
      PaisajeIconos.rocas,
      PaisajeIconos.flores,
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
      // Intervalo más chico (95-165 → 60-105 → 40-70): el usuario pidió
      // más densidad todavía en la franja de pasto de relleno.
      y += 40 + rng.nextDouble() * 30;
      lado = !lado;
    }
    return widgets;
  }

  /// Decoración puntual en cada "codo" del sendero (donde el camino
  /// cambia de dirección): el usuario pidió el doble de arbustos,
  /// flores, ocas y rocas, ubicadas en el espacio verde que deja la
  /// curva, no solo pegadas a los bordes del canvas como
  /// `_decoracionesDelCamino`. Un codo es un punto donde `dx` es un
  /// máximo o mínimo local sobre los puntos consecutivos del camino;
  /// el "afuera" de la curva (donde hay espacio verde libre) es hacia
  /// donde apunta ese pico.
  List<Widget> _decoracionesEnCodos(Size size) {
    if (camino.length < 3) return [];
    final rng = Random(31);
    const assets = [
      PaisajeIconos.arbusto,
      PaisajeIconos.flores,
      PaisajeIconos.rocas,
    ];
    final widgets = <Widget>[];
    for (var i = 1; i < camino.length - 1; i++) {
      final prev = camino[i - 1].dx;
      final cur = camino[i].dx;
      final next = camino[i + 1].dx;
      final int lado;
      if (cur > prev && cur > next) {
        lado = 1; // pico hacia la derecha: afuera de la curva = derecha
      } else if (cur < prev && cur < next) {
        lado = -1; // pico hacia la izquierda: afuera de la curva = izquierda
      } else {
        continue;
      }
      final centro = Offset(camino[i].dx * size.width, camino[i].dy * size.height);
      // Dos ítems por codo (el "doble" que pidió el usuario), más
      // separados del camino que el ancho del sendero pintado.
      for (var n = 0; n < 2; n++) {
        final asset = n == 0
            ? CasillaIconos.framesOca[0]
            : assets[rng.nextInt(assets.length)];
        final ancho = asset == CasillaIconos.framesOca[0]
            ? 22.0 + rng.nextDouble() * 8
            : 30.0 + rng.nextDouble() * 24;
        final offsetX = (46 + rng.nextDouble() * 22) * lado;
        final offsetY = (rng.nextDouble() - 0.5) * 50 + n * 26 * lado.sign;
        widgets.add(
          Positioned(
            left: (centro.dx + offsetX - ancho / 2).clamp(0.0, size.width - ancho),
            top: centro.dy + offsetY,
            child: Image.asset(asset, width: ancho, cacheWidth: (ancho * 2).round()),
          ),
        );
      }
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
