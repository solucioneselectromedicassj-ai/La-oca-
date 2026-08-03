import 'package:flutter/material.dart';
import '../models/cell_descriptions.dart';
import '../services/sala_game_controller.dart';
import '../theme/app_colors.dart';
import 'lobby_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/desempate_panel.dart';
import 'widgets/dice_widget.dart';
import 'widgets/etapa_banner.dart';
import 'widgets/fin_partida_panel.dart';
import 'widgets/jugadores_status_row.dart';
import 'widgets/minijuego_overlay.dart';
import 'widgets/ruleta_overlay.dart';
import 'widgets/sorteo_overlay.dart';
import 'widgets/trivia_overlay.dart';

class GameScreenMulti extends StatefulWidget {
  final SalaGameController controller;
  const GameScreenMulti({super.key, required this.controller});

  @override
  State<GameScreenMulti> createState() => _GameScreenMultiState();
}

class _GameScreenMultiState extends State<GameScreenMulti> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> _salir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Salir del juego?'),
        content: const Text('Si la partida sigue en curso, vas a perder tu lugar.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirmar != true) return;
    await widget.controller.salir();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LobbyScreen(usuario: widget.controller.usuario, nombre: widget.controller.myNombre, edadBracket: widget.controller.myEdadBracket, pais: widget.controller.myPais),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            if (c.partida == null) return const Center(child: CircularProgressIndicator(color: AppColors.violetDark));
            final finalizada = c.partida!.estado == 'finalizada';
            final enDesempate = c.partida!.estado == 'desempate';
            final jugadorTurno = c.jugadorEnTurno;

            return Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            enDesempate
                                ? (jugadorTurno?.id == c.myPlayerId ? '¡Tu trivia de desempate!' : 'Turno de desempate: ${jugadorTurno?.nombre ?? ""}')
                                : (c.esMiTurno ? '¡Tu turno!' : jugadorTurno != null ? 'Turno de ${jugadorTurno.nombre}' : ''),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.esCampanaGrupal ? 'Campaña grupal (etapa ${c.partida!.rondaActual} de 10): ${c.marcadorTexto}' : 'Tanda (partida ${c.partida!.rondaActual}): ${c.marcadorTexto}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF9B8AB5)),
                          ),
                          const SizedBox(height: 6),
                          if (c.esCampanaGrupal) EtapaBanner(etapa: c.partida!.etapaActual),
                          if (enDesempate) DesempatePanel(pendientesIds: c.partida!.desempatePendientes, jugadores: c.jugadores),
                          if (finalizada)
                            FinPartidaPanel(
                              mensaje: c.finMensaje ?? '',
                              mostrarRevancha: c.finMostrarRevancha,
                              labelRevancha: c.finLabelRevancha,
                              onRevancha: c.btnRevanchaOSiguientePartida,
                              mostrarNuevaTanda: c.finMostrarNuevaTanda,
                              onNuevaTanda: c.btnNuevaTanda,
                              mostrarJugarOtra: c.finMostrarJugarOtra,
                              onJugarOtra: () => _salir(context),
                            ),
                          JugadoresStatusRow(jugadores: c.jugadores),
                          const SizedBox(height: 8),
                          BoardWidget(
                            layoutCasillas: c.partida!.layoutCasillas,
                            jugadores: c.jugadores,
                            etapa: c.esCampanaGrupal ? c.partida!.etapaActual : 1,
                            animatingPlayerId: c.animatingPlayerId,
                            animatingPos: c.animatingPos,
                            sufriendoPlayerId: c.sufriendoPlayerId,
                          ),
                          DiceWidget(
                            habilitado: c.diceHabilitado,
                            rodando: c.diceRodando,
                            valorFinal: c.diceValorMostrado,
                            onTap: c.tirarDado,
                          ),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(c.gameMsg, textAlign: TextAlign.center)),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: () => _salir(context), child: const Text('Salir del juego')),
                        ],
                      ),
                    ),
                  ),
                ),
                _overlayActual(c),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _overlayActual(SalaGameController c) {
    switch (c.overlay) {
      case MpOverlay.trivia:
        return TriviaOverlay(
          titulo: {'oca': '🪿 Oca — Cuestionados', 'carcel': '⛓️ Cárcel — Cuestionados', 'calavera': '💀 Calavera — Cuestionados DIFÍCIL'}[c.triviaTipo] ?? '🎯 Desempate — Cuestionados decisiva',
          subtitulo: cellDescriptions[c.triviaTipo],
          pregunta: c.triviaActual!,
          segundos: c.triviaSegundosRestantes,
          onResponder: c.responderTrivia,
        );
      case MpOverlay.minijuego:
        return MinijuegoOverlay(titulo: '🎮 ¡Casilla de minijuego!', subtitulo: cellDescriptions['minijuego'], tipo: c.minijuegoTipo ?? 'reflejos', onDone: c.resolverMinijuegoActual);
      case MpOverlay.transicionMinijuego:
        return MinijuegoOverlay(titulo: '🎉 ¡Ganaste la etapa!', tipo: c.minijuegoTipo ?? 'reflejos', onDone: c.resolverMinijuegoActual);
      case MpOverlay.transicionRuleta:
        return RuletaOverlay(
          girando: c.wheelGirando,
          listaParaContinuar: c.wheelListaParaContinuar,
          resultado: c.wheelResultLabel,
          onGirar: c.girarRuletaGanador,
          onContinuar: c.cerrarRuletaGanador,
        );
      case MpOverlay.sorteo:
        return _sorteoOverlay(c);
      case MpOverlay.none:
        return const SizedBox.shrink();
    }
  }

  Widget _sorteoOverlay(SalaGameController c) {
    if (c.sorteoTiradas == null) return const SizedBox.shrink();
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SorteoPanel(jugadores: c.jugadores, tiradas: c.sorteoTiradas!, ganadorId: c.sorteoGanadorId),
        ),
      ),
    );
  }

}
