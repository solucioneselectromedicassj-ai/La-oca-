import 'package:flutter/material.dart';
import '../../models/wheel_prizes.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

/// Se muestra al empezar una nueva etapa si el jugador tiene comodines
/// guardados en el inventario: elegir cuál usar en esta etapa (se gasta
/// uno), o seguir sin usar ninguno.
class EleccionComodinOverlay extends StatelessWidget {
  final Map<String, int> comodines;
  final ValueChanged<String> onElegir;
  final VoidCallback onSaltar;
  const EleccionComodinOverlay({super.key, required this.comodines, required this.onElegir, required this.onSaltar});

  @override
  Widget build(BuildContext context) {
    final tipos = comodines.entries.where((e) => e.value > 0).toList();
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎒 ¿Usás un comodín en esta etapa?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.violetDark), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text('Se gasta uno de tu inventario y dura toda la etapa.', style: TextStyle(fontSize: 12, color: Color(0xFF7A6A99)), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          for (final e in tipos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onElegir(e.key),
                  child: Text('${comodinInfo[e.key]?.$1 ?? '🎁'} ${comodinInfo[e.key]?.$2 ?? e.key} (x${e.value})'),
                ),
              ),
            ),
          TextButton(onPressed: onSaltar, child: const Text('No usar ninguno')),
        ],
      ),
    );
  }
}
