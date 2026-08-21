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
    return Dialog(
      backgroundColor: AppColors.parchment,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            const Text(
              '¡Recompensa diaria!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.violetDark),
            ),
            const SizedBox(height: 16),
            Text(
              '🔥 Racha de ${premio.nuevaRacha} día${premio.nuevaRacha == 1 ? "" : "s"} seguidos\n(día ${premio.diaDelCiclo} de 7)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.violetDark),
            ),
            const SizedBox(height: 10),
            Text(
              'Ganaste ${premio.monedasGanadas} 🪙',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.violetDark),
            ),
            const SizedBox(height: 2),
            Text('Total: ${usuario.monedas} 🪙', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF9B8AB5))),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.violet, padding: const EdgeInsets.symmetric(vertical: 14), shape: const StadiumBorder()),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('¡Genial!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
