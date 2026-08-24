import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

class EleccionPerdisteOverlay extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  final VoidCallback onTresCuestionados;

  const EleccionPerdisteOverlay({super.key, required this.mensaje, required this.onReintentar, required this.onTresCuestionados});

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕 Te ganó el Cazador', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onReintentar, child: const Text('🔁 Reintentar la etapa'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onTresCuestionados, child: const Text('🎯 Responder 3 Cuestionados para pasar'))),
          const SizedBox(height: 8),
          const Text('Si fallás alguna, pasás a reintentar la etapa igual.', style: TextStyle(fontSize: 11.5, color: AppColors.violetDark)),
        ],
      ),
    );
  }
}
