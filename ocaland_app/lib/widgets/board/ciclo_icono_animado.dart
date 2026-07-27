import 'package:flutter/material.dart';

/// Animación de reposo genérica para casillas con arte real de varios
/// frames (oca aleteando, calavera moviendo la mandíbula, etc.) —
/// sección 4 de la spec visual v2: en loop mientras nadie las toca.
class CicloIconoAnimado extends StatefulWidget {
  const CicloIconoAnimado({
    super.key,
    required this.frames,
    this.alto = 30,
    this.duracionFrame = const Duration(milliseconds: 220),
  });

  final List<String> frames;
  final double alto;
  final Duration duracionFrame;

  @override
  State<CicloIconoAnimado> createState() => _CicloIconoAnimadoState();
}

class _CicloIconoAnimadoState extends State<CicloIconoAnimado> {
  int _indice = 0;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _programarSiguienteFrame();
  }

  void _programarSiguienteFrame() {
    Future.delayed(widget.duracionFrame, () {
      if (!mounted || !_activo) return;
      setState(() => _indice = (_indice + 1) % widget.frames.length);
      _programarSiguienteFrame();
    });
  }

  @override
  void dispose() {
    _activo = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      widget.frames[_indice],
      height: widget.alto,
      cacheHeight: 90,
      fit: BoxFit.contain,
    );
  }
}
