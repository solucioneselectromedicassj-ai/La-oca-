import 'package:flutter/material.dart';
import '../../services/sala_game_controller.dart';
import '../../theme/app_colors.dart';

/// Actividad para los jugadores que están esperando su turno en una tanda
/// multijugador — pedido explícito del usuario: "cuando a uno le toca
/// esperar, salte un juego uno contra uno... no dependa de cuántos
/// jueguen" y "mientras uno hace, otro deshace, hasta que alguien
/// termina ganando". Un medidor compartido (0 a [medidorMeta]) donde
/// cualquiera de los que no tiene el turno del tablero puede responder
/// una pregunta rápida: acertar suma un punto, fallar resta uno. Quien
/// lo completa se lleva unas monedas extra.
class MedidorCompartidoWidget extends StatelessWidget {
  final SalaGameController controller;
  const MedidorCompartidoWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (!c.medidorVisible) return const SizedBox.shrink();
    final actual = c.medidorJugadorActual;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🪢', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: c.medidorValor / medidorMeta,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('${c.medidorValor}/$medidorMeta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          if (c.medidorPregunta != null && c.medidorEsMiTurno)
            _preguntaMedidor(c)
          else if (c.medidorUltimoMensaje != null)
            Text(c.medidorUltimoMensaje!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
          else if (c.medidorEsMiTurno)
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: c.abrirPreguntaMedidor,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, padding: const EdgeInsets.symmetric(horizontal: 14)),
                child: const Text('🎯 ¡Jugá mientras esperás!', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            Text(
              actual == null ? 'Esperando jugadores...' : 'Le toca a ${actual.nombre}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
            ),
        ],
      ),
    );
  }

  Widget _preguntaMedidor(SalaGameController c) {
    final pregunta = c.medidorPregunta!;
    return Column(
      children: [
        Text('⏱️ ${c.medidorSegundosRestantes}s', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(pregunta.q, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < pregunta.options.length; i++)
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => c.responderMedidor(i),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.violet, padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: Text(pregunta.options[i], style: const TextStyle(fontSize: 11.5)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
