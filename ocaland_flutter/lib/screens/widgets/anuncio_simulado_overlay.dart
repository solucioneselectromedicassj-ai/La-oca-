import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

/// Port de `showAdSimulada()` del prototipo: una pantalla de "video
/// publicitario" simulado con una cuenta regresiva, para no depender de
/// una integración real de AdMob todavía. El botón "Continuar" queda
/// deshabilitado hasta que termina la cuenta regresiva.
class AnuncioSimuladoOverlay extends StatefulWidget {
  final VoidCallback onContinuar;
  const AnuncioSimuladoOverlay({super.key, required this.onContinuar});

  @override
  State<AnuncioSimuladoOverlay> createState() => _AnuncioSimuladoOverlayState();
}

class _AnuncioSimuladoOverlayState extends State<AnuncioSimuladoOverlay> {
  int _segundosRestantes = 4;
  Timer? _timer;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _segundosRestantes--;
        if (_segundosRestantes <= 0) {
          _listo = true;
          t.cancel();
        }
      });
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
          const Text('📺 Anuncio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: const Color(0xFF241B33), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('Acá va un anuncio (simulado).', style: TextStyle(color: Colors.white, fontSize: 13.5), textAlign: TextAlign.center),
                const Text('En la app real sería un video de AdMob.', style: TextStyle(color: Color(0xFFB9A9D6), fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(
                  _listo ? '✓' : '$_segundosRestantes',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _listo ? widget.onContinuar : null,
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
