import 'package:flutter/material.dart';
import '../../services/sala_game_controller.dart';
import '../../theme/app_colors.dart';
import 'ahorcado_eleccion_widget.dart';
import 'flecha_desafio_widget.dart';
import 'tetris_eleccion_widget.dart';

/// Actividad para los jugadores que están esperando su turno en una tanda
/// multijugador — pedido explícito del usuario: "cuando a uno le toca
/// esperar, salte un juego uno contra uno... no dependa de cuántos
/// jueguen" y "mientras uno hace, otro deshace, hasta que alguien
/// termina ganando". Un medidor compartido (0 a [medidorMeta]) donde
/// cualquiera de los que no tiene el turno del tablero puede resolver un
/// desafío rápido de flechas: acertar suma un punto, fallar resta uno.
/// Quien lo completa se lleva unas monedas extra.
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
          // El desafío abierto (de cualquiera de los 3 tipos) es siempre
          // local a este cliente — solo se setea cuando YO lo abro con mi
          // propio botón — así que si no es null, es mío sin falta.
          if (c.medidorDesafio != null)
            FlechaDesafioWidget(desafio: c.medidorDesafio!, segundos: c.medidorSegundosRestantes, onResponder: c.responderMedidor, compacto: true)
          else if (c.medidorAhorcado != null)
            AhorcadoEleccionWidget(desafio: c.medidorAhorcado!, segundos: c.medidorSegundosRestantes, onResponder: c.responderMedidorAhorcado, compacto: true)
          else if (c.medidorTetris != null)
            TetrisEleccionWidget(desafio: c.medidorTetris!, segundos: c.medidorSegundosRestantes, onResponder: c.responderMedidorTetris, compacto: true)
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
}
