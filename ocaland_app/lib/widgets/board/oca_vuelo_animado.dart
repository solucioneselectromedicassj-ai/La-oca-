import 'package:flutter/material.dart';

import 'casilla_iconos.dart';

/// Animación de reposo de la casilla oca: aletea en loop ciclando los 3
/// frames de vuelo (spec visual v2, sección 4 — "aletea suavemente").
class OcaVueloAnimado extends StatefulWidget {
  const OcaVueloAnimado({super.key, this.alto = 30});

  final double alto;

  @override
  State<OcaVueloAnimado> createState() => _OcaVueloAnimadoState();
}

class _OcaVueloAnimadoState extends State<OcaVueloAnimado> {
  int _indice = 0;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _programarSiguienteFrame();
  }

  void _programarSiguienteFrame() {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || !_activo) return;
      setState(() => _indice = (_indice + 1) % CasillaIconos.framesOca.length);
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
      CasillaIconos.framesOca[_indice],
      height: widget.alto,
      cacheHeight: 90,
      fit: BoxFit.contain,
    );
  }
}
