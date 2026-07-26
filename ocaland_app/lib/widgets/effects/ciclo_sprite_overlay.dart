import 'package:flutter/material.dart';

/// Reproduce una secuencia de frames (festejo o reacción) una sola vez,
/// centrada en pantalla, y se remueve sola al terminar.
class CicloSpriteOverlay extends StatefulWidget {
  const CicloSpriteOverlay({
    super.key,
    required this.frames,
    required this.onTerminado,
    this.alto = 160,
    this.porFrame = const Duration(milliseconds: 350),
  });

  final List<String> frames;
  final VoidCallback onTerminado;
  final double alto;
  final Duration porFrame;

  @override
  State<CicloSpriteOverlay> createState() => _CicloSpriteOverlayState();
}

class _CicloSpriteOverlayState extends State<CicloSpriteOverlay> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    _programarSiguiente();
  }

  void _programarSiguiente() {
    Future.delayed(widget.porFrame, () {
      if (!mounted) return;
      if (_indice >= widget.frames.length - 1) {
        widget.onTerminado();
        return;
      }
      setState(() => _indice++);
      _programarSiguiente();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Image.asset(widget.frames[_indice], height: widget.alto),
      ),
    );
  }
}
