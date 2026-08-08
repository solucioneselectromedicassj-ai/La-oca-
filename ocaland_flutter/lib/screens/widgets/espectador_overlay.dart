import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/trivia_bank.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

/// Cuando le toca a otro jugador (el bot, u otro participante en
/// multijugador): muestra la misma pregunta que le tocó, de solo lectura
/// (sin poder responder), y después revela si la supo o no — para que el
/// jugador tenga algo para mirar mientras espera su turno en vez de que
/// sea una caja negra.
class TriviaEspectadorOverlay extends StatefulWidget {
  final String nombre;
  final TriviaQuestion pregunta;
  final bool acierto;
  const TriviaEspectadorOverlay({super.key, required this.nombre, required this.pregunta, required this.acierto});

  @override
  State<TriviaEspectadorOverlay> createState() => _TriviaEspectadorOverlayState();
}

class _TriviaEspectadorOverlayState extends State<TriviaEspectadorOverlay> {
  bool _revelado = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _revelado = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🤖 Le toca a ${widget.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Mirá qué le preguntan (no podés responder)', style: TextStyle(fontSize: 12, color: Color(0xFF7A6A99)), textAlign: TextAlign.center),
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
                  style: OutlinedButton.styleFrom(backgroundColor: _colorFor(i), disabledForegroundColor: AppColors.violetDark, disabledBackgroundColor: _colorFor(i)),
                  onPressed: null,
                  child: Text(widget.pregunta.options[i]),
                ),
              ),
            ),
          if (_revelado)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.acierto ? '✅ ¡${widget.nombre} la supo!' : '❌ ${widget.nombre} no la supo.',
                style: TextStyle(fontWeight: FontWeight.bold, color: widget.acierto ? AppColors.green : AppColors.fuchsia),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorFor(int i) {
    if (!_revelado) return Colors.white;
    if (i == widget.pregunta.correct) return const Color(0xFF43D67D);
    return Colors.white;
  }
}

/// Igual que [TriviaEspectadorOverlay] pero para la casilla de minijuego.
class MinijuegoEspectadorOverlay extends StatefulWidget {
  final String nombre;
  final String tipo; // 'reflejos' | 'memoria'
  final bool exito;
  const MinijuegoEspectadorOverlay({super.key, required this.nombre, required this.tipo, required this.exito});

  @override
  State<MinijuegoEspectadorOverlay> createState() => _MinijuegoEspectadorOverlayState();
}

class _MinijuegoEspectadorOverlayState extends State<MinijuegoEspectadorOverlay> {
  bool _revelado = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _revelado = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombreMinijuego = widget.tipo == 'reflejos' ? '⚡ Reflejos' : '🧠 Memoria';
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎮 Le toca a ${widget.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 6),
          Text('Le tocó el minijuego de $nombreMinijuego', style: const TextStyle(fontSize: 13.5), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          if (!_revelado) const CircularProgressIndicator(color: AppColors.violetDark),
          if (_revelado)
            Text(
              widget.exito ? '✅ ¡${widget.nombre} lo superó!' : '❌ ${widget.nombre} no lo superó.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: widget.exito ? AppColors.green : AppColors.fuchsia),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
