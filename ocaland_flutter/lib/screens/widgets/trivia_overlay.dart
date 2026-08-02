import 'package:flutter/material.dart';
import '../../models/trivia_bank.dart';
import '../../theme/app_colors.dart';

class TriviaOverlay extends StatefulWidget {
  final String titulo;
  final TriviaQuestion pregunta;
  final int segundos; // 0 = sin límite (desafío de 3 Cuestionados)
  final ValueChanged<int> onResponder;

  const TriviaOverlay({super.key, required this.titulo, required this.pregunta, required this.segundos, required this.onResponder});

  @override
  State<TriviaOverlay> createState() => _TriviaOverlayState();
}

class _TriviaOverlayState extends State<TriviaOverlay> {
  int? _elegida;

  void _tap(int idx) {
    if (_elegida != null) return;
    setState(() => _elegida = idx);
    Future.delayed(const Duration(milliseconds: 500), () => widget.onResponder(idx));
  }

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          if (widget.segundos > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('⏱️ ${widget.segundos}s', style: const TextStyle(color: AppColors.fuchsia, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 10),
          Text(widget.pregunta.q, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          for (var i = 0; i < widget.pregunta.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: _colorFor(i)),
                  onPressed: () => _tap(i),
                  child: Text(widget.pregunta.options[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color? _colorFor(int i) {
    if (_elegida == null) return Colors.white;
    if (i == widget.pregunta.correct) return const Color(0xFF43D67D);
    if (i == _elegida) return const Color(0xFFFF5A7A);
    return Colors.white;
  }
}

/// Overlay modal compartido por trivia, minijuegos, sorteo, ruleta, etc.
class ModalCard extends StatelessWidget {
  final Widget child;
  const ModalCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))]),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}
