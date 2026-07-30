import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/paisaje_iconos.dart';

/// Fondo del tablero como paisaje ilustrado, con el arte real que
/// proveyó el usuario (árboles, arbustos, flores, rocas, puente, agua,
/// nubes, sol — estilo Candy Crush plano) en vez de formas vectoriales
/// genéricas. El terreno (colinas) sigue siendo color plano por bloque
/// de etapas (no hay textura de pasto real todavía), pero la
/// decoración ya es arte de verdad.
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
  });

  final List<Color> gradiente;
  final Color acento;
  final List<Offset> trampolinesPx;

  Color _oscurecer(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - cantidad).clamp(0.0, 1.0)).toColor();
  }

  Color _mezclar(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    final verdeBase = _mezclar(const Color(0xFF9CCC65), acento, 0.25);
    final colinaLejos = verdeBase;
    final colinaCerca = _oscurecer(verdeBase, 0.16);

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
        // Sol y nubes con el arte real.
        Align(
          alignment: const Alignment(0.75, -0.92),
          child: Image.asset(PaisajeIconos.sol, width: 62, cacheWidth: 124),
        ),
        Align(
          alignment: const Alignment(-0.55, -0.9),
          child: Image.asset(PaisajeIconos.nube1, width: 92, cacheWidth: 184),
        ),
        Align(
          alignment: const Alignment(0.5, -0.7),
          child: Image.asset(PaisajeIconos.nube2, width: 78, cacheWidth: 156),
        ),
        // Colina lejana: arranca bien arriba para que el camino nunca
        // quede flotando sobre el cielo vacío.
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([_Colina(colinaLejos, 0.18, 16, 1.2, 0.0)]),
          ),
        ),
        // Decoración dispersa a los costados del camino (no en el
        // centro, para no tapar las casillas).
        _decoracion(const Alignment(-0.92, -0.4), PaisajeIconos.arbolPino, 46),
        _decoracion(const Alignment(0.9, -0.55), PaisajeIconos.arbolFrondoso, 50),
        _decoracion(const Alignment(-0.88, 0.05), PaisajeIconos.rocas, 44),
        _decoracion(const Alignment(0.85, 0.15), PaisajeIconos.arbusto, 34),
        _decoracion(const Alignment(-0.75, 0.5), PaisajeIconos.flores, 40),
        _decoracion(const Alignment(0.88, 0.62), PaisajeIconos.arbolFrondoso, 56),
        _decoracion(const Alignment(-0.7, 0.85), PaisajeIconos.arbusto, 38),
        _decoracion(const Alignment(0.7, 0.9), PaisajeIconos.arbolPino, 42),
        // Agua real + puente real, anclados a cada casilla de trampolín.
        for (final p in trampolinesPx) ..._puenteEnPunto(p),
        // Colina cercana (primer plano), tapa la base del río lejano.
        Positioned.fill(
          child: CustomPaint(
            painter: _ColinasPainter([_Colina(colinaCerca, 0.62, 18, 1.4, 2.2)]),
          ),
        ),
        _decoracion(const Alignment(-0.85, -0.75), PaisajeIconos.rocas, 30),
      ],
    );
  }

  List<Widget> _puenteEnPunto(Offset p) {
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

  Widget _decoracion(Alignment alineacion, String asset, double ancho) {
    return Align(
      alignment: alineacion,
      child: Image.asset(asset, width: ancho, cacheWidth: (ancho * 2).round()),
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
