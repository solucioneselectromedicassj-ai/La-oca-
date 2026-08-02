import 'package:flutter/material.dart';

import '../../theme/ocaland_theme.dart';

/// "+N" con ícono de moneda que sube y se desvanece (spec visual v2,
/// sección 5). Versión simplificada del "vuelo hasta el contador": ese
/// vuelo con destino exacto a la posición del contador en el AppBar del
/// menú queda pendiente de una siguiente pasada (necesita sincronizar el
/// estado de monedas entre pantallas, no solo el efecto visual).
class MonedasGanadasFlotante extends StatefulWidget {
  const MonedasGanadasFlotante({
    super.key,
    required this.cantidad,
    required this.onTerminado,
  });

  final int cantidad;
  final VoidCallback onTerminado;

  @override
  State<MonedasGanadasFlotante> createState() => _MonedasGanadasFlotanteState();
}

class _MonedasGanadasFlotanteState extends State<MonedasGanadasFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _subida;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onTerminado();
      })
      ..forward();
    _subida = Tween<double>(begin: 0, end: -80)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacidad = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.3),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, _subida.value),
            child: Opacity(
              opacity: _opacidad.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: OcalandColors.amarillo),
                      const SizedBox(width: 6),
                      Text(
                        '+${widget.cantidad}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
