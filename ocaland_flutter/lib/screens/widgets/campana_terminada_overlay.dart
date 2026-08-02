import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

class CampanaTerminadaOverlay extends StatelessWidget {
  final String texto;
  final VoidCallback onVolverAlLobby;

  const CampanaTerminadaOverlay({super.key, required this.texto, required this.onVolverAlLobby});

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆 ¡Campaña completa!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 10),
          Text(texto, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onVolverAlLobby, child: const Text('🔄 Jugar otra partida (sala nueva)'))),
        ],
      ),
    );
  }
}
