import 'package:flutter/material.dart';
import '../../models/campana.dart';
import '../../theme/app_colors.dart';

/// Micro-historia de la etapa: se muestra una vez al llegar a cada etapa
/// nueva de la campaña solo, con el nombre y la leyenda que ya vivían
/// escondidos atrás del "📖 Leer" del banner — pedido explícito de
/// armar esto para ir completando etapa por etapa.
class EtapaHistoriaDialog extends StatelessWidget {
  final int etapa;
  final EtapaInfo info;
  const EtapaHistoriaDialog({super.key, required this.etapa, required this.info});

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
            const Text('📖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('Etapa $etapa', style: const TextStyle(fontSize: 13, color: AppColors.violetDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(info.nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
            const SizedBox(height: 14),
            Text(info.leyenda, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: AppColors.violetDark, height: 1.4)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.violetDark, shape: const StadiumBorder()),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('¡Vamos! 🎲', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
