import 'package:flutter/material.dart';

/// Fondo del tablero con profundidad tipo Candy Crush: además del
/// degradé por bloque de etapas, agrega manchas de color difuminadas
/// detrás del camino y algunos brillitos, para que no se vea plano.
class FondoCandy extends StatelessWidget {
  const FondoCandy({super.key, required this.gradiente, required this.acento});

  final List<Color> gradiente;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradiente,
            ),
          ),
        ),
        _mancha(top: -50, left: -60, diametro: 220, color: acento),
        _mancha(top: 130, right: -80, diametro: 260, color: gradiente.last),
        _mancha(bottom: 90, left: -60, diametro: 210, color: gradiente.first),
        _mancha(bottom: -70, right: -40, diametro: 240, color: acento),
        _brillito(-0.82, -0.86, tamano: 16),
        _brillito(0.72, -0.6, tamano: 12),
        _brillito(0.6, 0.02, tamano: 20, opacidad: 0.35),
        _brillito(-0.62, 0.32, tamano: 14),
        _brillito(0.8, 0.68, tamano: 18, opacidad: 0.45),
        _brillito(-0.3, 0.88, tamano: 12),
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
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
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
