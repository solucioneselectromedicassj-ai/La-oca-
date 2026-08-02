import 'dart:math';

import 'package:flutter/material.dart';

/// Ruleta de premio: gira y se detiene sobre el segmento
/// [indiceObjetivo] (0-5, mismo orden que `RuletaPremios.segmentos`).
class RuletaWidget extends StatefulWidget {
  const RuletaWidget({
    super.key,
    required this.indiceObjetivo,
    required this.totalSegmentos,
    required this.onTerminarGiro,
    this.tamano = 240,
  });

  final int indiceObjetivo;
  final int totalSegmentos;
  final VoidCallback onTerminarGiro;
  final double tamano;

  /// Centro real (en grados, horario desde arriba) de cada gajo en
  /// `assets/ruleta/disco.png` — el arte no divide el círculo en 6
  /// partes perfectamente iguales, así que se midió el centro real de
  /// cada color en vez de asumir 60° parejos.
  static const List<double> centrosGrados = [1.6, 39.2, 90.5, 179.4, 263.2, 323.7];

  @override
  State<RuletaWidget> createState() => _RuletaWidgetState();
}

class _RuletaWidgetState extends State<RuletaWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angulo;

  @override
  void initState() {
    super.initState();
    final centroObjetivo =
        RuletaWidget.centrosGrados[widget.indiceObjetivo] * pi / 180;
    // 5 vueltas completas + lo que falta para que el objetivo quede
    // justo bajo el puntero fijo de arriba.
    final anguloFinal = 5 * 2 * pi + (2 * pi - centroObjetivo);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _angulo = Tween<double>(begin: 0, end: anguloFinal).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward().whenComplete(widget.onTerminarGiro);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.tamano,
      height: widget.tamano + 24,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: widget.tamano * 0.02,
            child: AnimatedBuilder(
              animation: _angulo,
              builder: (context, child) => Transform.rotate(angle: _angulo.value, child: child),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.08,
                  child: Image.asset(
                    'assets/ruleta/disco.png',
                    width: widget.tamano,
                    height: widget.tamano,
                    fit: BoxFit.cover,
                    cacheWidth: (widget.tamano * 2).round(),
                  ),
                ),
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 46, color: Colors.black87),
        ],
      ),
    );
  }
}
