import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

const _diceFaces = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

/// Dado tocable. Mientras `rodando` es true muestra caras cambiando rápido
/// para que la tirada se sienta más "viva" y visible (pedido del usuario:
/// que se vea bien el momento de tirar el dado, no que sea instantáneo).
class DiceWidget extends StatefulWidget {
  final bool habilitado;
  final bool rodando;
  final int? valorFinal;
  final VoidCallback onTap;
  final double size;

  const DiceWidget({super.key, required this.habilitado, required this.rodando, required this.valorFinal, required this.onTap, this.size = 92});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> {
  Timer? _cycleTimer;
  int _cara = 0;

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rodando && !oldWidget.rodando) {
      _cycleTimer?.cancel();
      _cycleTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        setState(() => _cara = 1 + Random().nextInt(6));
      });
    } else if (!widget.rodando && oldWidget.rodando) {
      _cycleTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = widget.rodando ? _diceFaces[_cara] : (widget.valorFinal != null ? _diceFaces[widget.valorFinal!] : '🎲');
    final activo = widget.habilitado && !widget.rodando;
    return GestureDetector(
      onTap: activo ? widget.onTap : null,
      child: Container(
        width: widget.size,
        height: widget.size,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.violetDark, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: activo || widget.rodando ? 1 : 0.35,
          child: Text(texto, style: TextStyle(fontSize: widget.size * 0.5)),
        ),
      ),
    );
  }
}
