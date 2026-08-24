import 'package:flutter/material.dart';
import '../models/cell_descriptions.dart';
import '../models/sesion_activa.dart';
import '../services/audio_service.dart';
import '../services/solo_game_controller.dart';
import '../theme/app_colors.dart';
import 'lobby_screen.dart';
import 'widgets/anuncio_simulado_overlay.dart';
import 'widgets/board_widget.dart';
import 'widgets/boton_salir_juego.dart';
import 'widgets/campana_terminada_overlay.dart';
import 'widgets/dice_widget.dart';
import 'widgets/eleccion_comodin_overlay.dart';
import 'widgets/eleccion_perdiste_overlay.dart';
import 'widgets/eleccion_video_monedas_overlay.dart';
import 'widgets/espectador_overlay.dart';
import 'widgets/etapa_banner.dart';
import 'widgets/jugadores_status_row.dart';
import 'widgets/message_bubble.dart';
import 'widgets/minijuego_overlay.dart';
import 'widgets/ruleta_overlay.dart';
import 'widgets/sorteo_overlay.dart';
import 'widgets/trivia_overlay.dart';

class GameScreenSolo extends StatefulWidget {
  final SoloGameController controller;
  final SesionActiva? sesionAReanudar;

  const GameScreenSolo({super.key, required this.controller, this.sesionAReanudar});

  @override
  State<GameScreenSolo> createState() => _GameScreenSoloState();
}

class _GameScreenSoloState extends State<GameScreenSolo> {
  SoloGameController get _c => widget.controller;
  String? _errorInicio;

  @override
  void initState() {
    super.initState();
    AudioService.iniciarMusica();
    final futuro = widget.sesionAReanudar != null ? _c.reanudar(widget.sesionAReanudar!) : _c.iniciar();
    futuro.catchError((e) {
      if (mounted) setState(() => _errorInicio = 'No pudimos conectar con el servidor para arrancar la partida.');
    });
  }

  @override
  void dispose() {
    AudioService.detenerMusica();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            if (_errorInicio != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorInicio!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: () => _salir(context), child: const Text('← Volver')),
                    ],
                  ),
                ),
              );
            }
            if (_c.cargando || _c.partida == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
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
                            _c.esMiTurno ? '¡Tu turno!' : (_c.jugadorEnTurno?.esBot == true ? '🏹 Turno del Cazador...' : 'Esperando...'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            'Campaña: etapa ${_c.partida!.etapaActual} de 10${_c.reintentosEtapaActual > 0 ? " · ${_c.reintentosEtapaActual} reintentos" : ""}',
                            style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                          const SizedBox(height: 6),
                          EtapaBanner(etapa: _c.partida!.etapaActual),
                          if (_c.overlay == GameOverlay.sorteo && _c.sorteoTiradas != null)
                            SorteoPanel(
                              jugadores: _c.jugadores,
                              tiradas: _c.sorteoTiradas!,
                              ganadorId: _c.sorteoGanadorId,
                              esperandoTapDeId: _c.sorteoEsperandoTapDeId,
                              onTirar: _c.tirarDadoSorteo,
                            ),
                          JugadoresStatusRow(jugadores: _c.jugadores),
                          const SizedBox(height: 8),
                          BoardWidget(
                            layoutCasillas: _c.partida!.layoutCasillas,
                            jugadores: _c.jugadores,
                            etapa: _c.partida!.etapaActual,
                            animatingPlayerId: _c.animatingPlayerId,
                            animatingPos: _c.animatingPos,
                            sufriendoPlayerId: _c.sufriendoPlayerId,
                            trampaCellIndex: _c.trampaCasillaIdx,
                          ),
                          if (_c.jugadorEnTurno?.esBot == true && (_c.botPensando || _c.botDiceRodando || _c.botDiceValorMostrado != null))
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                children: [
                                  const Text('🏹 el Cazador tira:', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  DiceWidget(
                                    habilitado: false,
                                    rodando: _c.botDiceRodando,
                                    valorFinal: _c.botDiceValorMostrado,
                                    onTap: () {},
                                    size: 56,
                                  ),
                                ],
                              ),
                            )
                          else
                            DiceWidget(
                              habilitado: _c.diceHabilitado,
                              rodando: _c.diceRodando,
                              valorFinal: _c.diceValorMostrado,
                              onTap: _c.tirarDado,
                            ),
                          MessageBubble(mensaje: _c.gameMsg),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 4, left: 4, child: BotonSalirJuego(onTap: () => _salir(context))),
                _overlayActual(),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  Future<void> _salir(BuildContext context) async {
    await _c.salir();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LobbyScreen(usuario: _c.usuario, nombre: _c.myNombre, edadBracket: _c.myEdadBracket, pais: _c.myPais)),
      (route) => false,
    );
  }

  Widget _overlayActual() {
    switch (_c.overlay) {
      case GameOverlay.trivia:
        return TriviaOverlay(
          titulo: {'oca': '🪿 Oca — Cuestionados', 'carcel': '⛓️ Cárcel — Cuestionados', 'calavera': '💀 Calavera — Cuestionados DIFÍCIL'}[_c.triviaTipo] ?? '🎯 Cuestionados',
          subtitulo: cellDescriptions[_c.triviaTipo],
          pregunta: _c.triviaActual!,
          segundos: _c.triviaSegundosRestantes,
          onResponder: _c.responderTrivia,
          onPedirPista: _c.pedirPista,
          pistaUsada: _c.pistaUsada,
          opcionEliminada: _c.pistaOpcionEliminada,
        );
      case GameOverlay.triviaEspectador:
        return TriviaEspectadorOverlay(
          nombre: _c.triviaEspectadorNombre,
          pregunta: _c.triviaActual!,
          acierto: _c.triviaEspectadorAcierto,
        );
      case GameOverlay.minijuegoEspectador:
        return MinijuegoEspectadorOverlay(
          nombre: _c.triviaEspectadorNombre,
          tipo: _c.minijuegoTipo ?? 'reflejos',
          exito: _c.triviaEspectadorAcierto,
        );
      case GameOverlay.tresCuestionados:
        return TriviaOverlay(
          titulo: '🎯 Desafío',
          pregunta: _c.triviaActual!,
          segundos: 0,
          onResponder: _c.responderTrivia,
        );
      case GameOverlay.minijuegoCasilla:
        return MinijuegoOverlay(
          titulo: '🎮 ¡Casilla de minijuego!',
          subtitulo: cellDescriptions['minijuego'],
          tipo: _c.minijuegoTipo ?? 'reflejos',
          onDone: _c.resolverMinijuegoActual,
        );
      case GameOverlay.transicionMinijuego:
        return MinijuegoOverlay(
          titulo: '🎉 ¡Etapa superada!',
          tipo: _c.minijuegoTipo ?? 'reflejos',
          onDone: _c.resolverMinijuegoActual,
        );
      case GameOverlay.transicionRuleta:
        return RuletaOverlay(
          girando: _c.wheelGirando,
          listaParaContinuar: _c.wheelListaParaContinuar,
          resultado: _c.wheelResultLabel,
          premioIdx: _c.wheelPremioIdx,
          onGirar: _c.girarRuleta,
          onContinuar: _c.continuarDesdeRuleta,
        );
      case GameOverlay.eleccionPerdiste:
        return EleccionPerdisteOverlay(
          mensaje: _c.perdidaMsg,
          onReintentar: _c.elegirReintentar,
          onTresCuestionados: _c.elegirTresCuestionados,
        );
      case GameOverlay.campanaTerminada:
        return CampanaTerminadaOverlay(texto: _c.campanaFinTexto, onVolverAlLobby: () => _salir(context));
      case GameOverlay.eleccionVideoMonedas:
        return EleccionVideoMonedasOverlay(
          descripcion: _c.eleccionDescripcion,
          costoMonedas: _c.eleccionCostoMonedas,
          monedasActuales: _c.usuario.monedas,
          costoSellos: _c.eleccionCostoSellos,
          sellosActuales: _c.sellos,
          onVideo: _c.elegirVideo,
          onMonedas: _c.elegirMonedasParaEleccion,
          onSellos: _c.elegirSellosParaEleccion,
          onCancelar: _c.cancelarEleccionVideoMonedas,
        );
      case GameOverlay.anuncioSimulado:
        return AnuncioSimuladoOverlay(onContinuar: _c.continuarDesdeAnuncio);
      case GameOverlay.eleccionComodin:
        return EleccionComodinOverlay(
          comodines: _c.comodines,
          onElegir: _c.elegirComodinParaEtapa,
          onSaltar: () => _c.elegirComodinParaEtapa(null),
        );
      case GameOverlay.sorteo:
      case GameOverlay.none:
        return const SizedBox.shrink();
    }
  }

}
