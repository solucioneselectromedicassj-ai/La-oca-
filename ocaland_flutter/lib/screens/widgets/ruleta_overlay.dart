import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

class RuletaOverlay extends StatelessWidget {
  final bool girando;
  final bool listaParaContinuar;
  final String resultado;
  final VoidCallback onGirar;
  final VoidCallback onContinuar;

  const RuletaOverlay({
    super.key,
    required this.girando,
    required this.listaParaContinuar,
    required this.resultado,
    required this.onGirar,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉 ¡Etapa superada!', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 6),
          const Text('¡Girá la ruleta de premios!'),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violetDark, width: 4),
              gradient: const SweepGradient(colors: [
                AppColors.green, AppColors.lemon, AppColors.turquoise, AppColors.sky, Color(0xFFFF5A7A), AppColors.gold, AppColors.green,
              ]),
            ),
            child: girando ? const Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : null,
          ),
          const SizedBox(height: 14),
          if (!listaParaContinuar)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: girando ? null : onGirar, child: const Text('Girar ruleta'))),
          if (resultado.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(resultado, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.violetDark))),
          if (listaParaContinuar)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onContinuar, child: const Text('Continuar a la siguiente etapa'))),
            ),
        ],
      ),
    );
  }
}
