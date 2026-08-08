import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_overlay.dart';

/// Port de `ofrecerVideoOMonedas()` del prototipo: un diálogo genérico que
/// ofrece conseguir algo (una pista, otra oportunidad, etc.) viendo un
/// video, gastando monedas, o gastando sellos — o cancelar. Se reutiliza
/// en varios puntos del juego (pista de Cuestionados, reintento antes de
/// la penitencia, etc.).
class EleccionVideoMonedasOverlay extends StatelessWidget {
  final String descripcion;
  final int costoMonedas;
  final int monedasActuales;
  final int costoSellos;
  final int sellosActuales;
  final VoidCallback onVideo;
  final VoidCallback onMonedas;
  final VoidCallback onSellos;
  final VoidCallback onCancelar;

  const EleccionVideoMonedasOverlay({
    super.key,
    required this.descripcion,
    required this.costoMonedas,
    required this.monedasActuales,
    required this.costoSellos,
    required this.sellosActuales,
    required this.onVideo,
    required this.onMonedas,
    required this.onSellos,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final alcanzaMonedas = monedasActuales >= costoMonedas;
    final alcanzaSellos = sellosActuales >= costoSellos;
    return ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎬 ¿Cómo lo conseguís?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
          const SizedBox(height: 8),
          Text(descripcion, style: const TextStyle(fontSize: 13.5), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onVideo, child: const Text('📺 Ver un video (gratis)')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: alcanzaMonedas ? onMonedas : null,
              child: Text('🪙 Gastar $costoMonedas monedas (tenés $monedasActuales)'),
            ),
          ),
          if (costoSellos > 0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: alcanzaSellos ? onSellos : null,
                child: Text('🎖️ Usar $costoSellos sellos (tenés $sellosActuales)'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(onPressed: onCancelar, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
