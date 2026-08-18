import 'dart:async';
import 'package:flutter/material.dart';

/// Secuencia cortita (4 cuadros dibujados) de la Oca comiendo, como premio
/// al darle de comer — reemplaza la animación en video anterior: mismo
/// efecto, mucho más liviana y funciona igual en web.
class OcaComiendoSprite extends StatefulWidget {
  final VoidCallback onTerminado;
  final double size;
  const OcaComiendoSprite({super.key, required this.onTerminado, this.size = 160});

  @override
  State<OcaComiendoSprite> createState() => _OcaComiendoSpriteState();
}

class _OcaComiendoSpriteState extends State<OcaComiendoSprite> {
  static const _cuadros = ['oca_hambre', 'oca_comiendo_1', 'oca_comiendo_2', 'oca_feliz_boca_abierta'];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_i >= _cuadros.length - 1) {
        timer.cancel();
        widget.onTerminado();
        return;
      }
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _timer?.cancel();
        widget.onTerminado();
      },
      child: Image.asset('assets/mascota/${_cuadros[_i]}.png', width: widget.size, height: widget.size),
    );
  }
}
