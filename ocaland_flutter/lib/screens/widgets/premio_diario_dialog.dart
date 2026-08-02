import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/identity_service.dart';
import '../../theme/app_colors.dart';

class PremioDiarioDialog extends StatelessWidget {
  final Usuario usuario;
  final PremioDiario premio;
  const PremioDiarioDialog({super.key, required this.usuario, required this.premio});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.parchment,
      title: const Text('🎁 ¡Recompensa diaria!'),
      content: Text(
        '🔥 Racha de ${premio.nuevaRacha} día${premio.nuevaRacha == 1 ? "" : "s"} seguidos (día ${premio.diaDelCiclo} de 7).\n'
        'Ganaste ${premio.monedasGanadas} 🪙 monedas.\nTotal: ${usuario.monedas} 🪙',
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('¡Genial!')),
      ],
    );
  }
}
