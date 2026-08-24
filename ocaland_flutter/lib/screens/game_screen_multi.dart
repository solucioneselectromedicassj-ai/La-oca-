import 'package:flutter/material.dart';
import '../models/cell_descriptions.dart';
import '../services/audio_service.dart';
import '../services/sala_game_controller.dart';
import '../theme/app_colors.dart';
import 'lobby_screen.dart';
import 'widgets/anuncio_simulado_overlay.dart';
import 'widgets/board_widget.dart';
import 'widgets/boton_salir_juego.dart';
import 'widgets/desempate_panel.dart';
import 'widgets/dice_widget.dart';
import 'widgets/eleccion_video_monedas_overlay.dart';
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
  void initState() {
    super.initState();
    AudioService.iniciarMusica();
  }

  @override
  void dispose() {
    AudioService.detenerMusica();
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            if (c.partida == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            c.esCampanaGrupal ? 'Campaña grupal (etapa ${c.partida!.rondaActual} de 10): ${c.marcadorTexto}' : 'Tanda (partida ${c.partida!.rondaActual}): ${c.marcadorTexto}',
                            style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
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
                            trampaCellIndex: c.trampaCasillaIdx,
                          ),
                          DiceWidget(
                            habilitado: c.diceHabilitado,
                            rodando: c.diceRodando,
                            valorFinal: c.diceValorMostrado,
                            onTap: c.tirarDado,
                          ),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(c.gameMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 4, left: 4, child: BotonSalirJuego(onTap: () => _salir(context))),
                _overlayActual(c),
              ],
            );
          },
        ),
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
          onPedirPista: c.pedirPista,
          pistaUsada: c.pistaUsada,
          opcionEliminada: c.pistaOpcionEliminada,
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
          premioIdx: c.wheelPremioIdx,
          onGirar: c.girarRuletaGanador,
          onContinuar: c.cerrarRuletaGanador,
        );
      case MpOverlay.sorteo:
        return _sorteoOverlay(c);
      case MpOverlay.eleccionVideoMonedas:
        return EleccionVideoMonedasOverlay(
          descripcion: c.eleccionDescripcion,
          costoMonedas: c.eleccionCostoMonedas,
          monedasActuales: c.usuario.monedas,
          costoSellos: c.eleccionCostoSellos,
          sellosActuales: c.sellos,
          onVideo: c.elegirVideo,
          onMonedas: c.elegirMonedasParaEleccion,
          onSellos: c.elegirSellosParaEleccion,
          onCancelar: c.cancelarEleccionVideoMonedas,
        );
      case MpOverlay.anuncioSimulado:
        return AnuncioSimuladoOverlay(onContinuar: c.continuarDesdeAnuncio);
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
