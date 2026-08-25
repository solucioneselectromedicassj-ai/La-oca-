import 'package:flutter/material.dart';
import '../../models/trivia_bank.dart';
import '../../theme/app_colors.dart';

class TriviaOverlay extends StatefulWidget {
  final String titulo;
  final String? subtitulo;
  final TriviaQuestion pregunta;
  final int segundos; // 0 = sin límite (desafío de 3 Cuestionados)
  final ValueChanged<int> onResponder;

  /// Pista: elimina una opción incorrecta. Si es null, no se muestra el
  /// botón de pista (ej. en el desafío de 3 Cuestionados).
  final VoidCallback? onPedirPista;
  final bool pistaUsada;
  final int? opcionEliminada;
  final bool scrim;

  const TriviaOverlay({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.pregunta,
    required this.segundos,
    required this.onResponder,
    this.onPedirPista,
    this.pistaUsada = false,
    this.opcionEliminada,
    this.scrim = true,
  });

  @override
  State<TriviaOverlay> createState() => _TriviaOverlayState();
}

class _TriviaOverlayState extends State<TriviaOverlay> {
  int? _elegida;

  @override
  void didUpdateWidget(covariant TriviaOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cuando cambia la pregunta (siguiente ronda de una secuencia, como el
    // rescate de la mascota o el desafío de 3 Cuestionados) hay que
    // reiniciar la selección — si no, este widget queda "pensando" que ya
    // se respondió y ningún toque vuelve a reaccionar.
    if (!identical(oldWidget.pregunta, widget.pregunta)) {
      _elegida = null;
    }
  }

  void _tap(int idx) {
    if (_elegida != null || idx == widget.opcionEliminada) return;
    setState(() => _elegida = idx);
    Future.delayed(const Duration(milliseconds: 500), () => widget.onResponder(idx));
  }

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      scrim: widget.scrim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          if (widget.subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.subtitulo!, style: const TextStyle(fontSize: 12, color: Color(0xFF7A6A99)), textAlign: TextAlign.center),
            ),
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
                  style: OutlinedButton.styleFrom(backgroundColor: _colorFor(i), disabledBackgroundColor: _colorFor(i)),
                  onPressed: i == widget.opcionEliminada ? null : () => _tap(i),
                  child: Text(
                    widget.pregunta.options[i],
                    style: i == widget.opcionEliminada ? const TextStyle(decoration: TextDecoration.lineThrough, color: Color(0xFFAA9BC4)) : null,
                  ),
                ),
              ),
            ),
          if (widget.onPedirPista != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: (widget.pistaUsada || _elegida != null) ? null : widget.onPedirPista,
                child: Text(widget.pistaUsada ? '💡 Pista usada' : '💡 Pedir una pista'),
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
/// [scrim] oscurece el fondo (para cuando esta tarjeta flota arriba del
/// tablero, dentro de un Stack) — se desactiva cuando es el único
/// contenido de una pantalla propia (tanda de cuestionados, minijuegos
/// bonus), donde ese negro de por medio quedaba pisando el fondo vivo
/// de esa pantalla en vez de "atenuar" algo detrás.
class ModalCard extends StatelessWidget {
  final Widget child;
  final bool scrim;
  const ModalCard({super.key, required this.child, this.scrim = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scrim ? Colors.black.withValues(alpha: 0.72) : null,
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
