import 'package:flutter/material.dart';
import '../models/sesion_activa.dart';
import '../services/solo_game_controller.dart';
import '../theme/app_colors.dart';
import 'lobby_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/campana_terminada_overlay.dart';
import 'widgets/dice_widget.dart';
import 'widgets/eleccion_perdiste_overlay.dart';
import 'widgets/etapa_banner.dart';
import 'widgets/jugadores_status_row.dart';
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
    final futuro = widget.sesionAReanudar != null ? _c.reanudar(widget.sesionAReanudar!) : _c.iniciar();
    futuro.catchError((e) {
      if (mounted) setState(() => _errorInicio = 'No pudimos conectar con el servidor para arrancar la partida.');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
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
                      Text(_errorInicio!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: () => _salir(context), child: const Text('← Volver')),
                    ],
                  ),
                ),
              );
            }
            if (_c.cargando || _c.partida == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.violetDark));
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
                            _c.esMiTurno ? '¡Tu turno!' : (_c.jugadorEnTurno?.esBot == true ? '🤖 Turno del bot...' : 'Esperando...'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text('Campaña: etapa ${_c.partida!.etapaActual} de 10${_c.reintentosEtapaActual > 0 ? " · ${_c.reintentosEtapaActual} reintentos" : ""}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9B8AB5))),
                          const SizedBox(height: 6),
                          EtapaBanner(etapa: _c.partida!.etapaActual),
                          if (_c.overlay == GameOverlay.sorteo && _c.sorteoTiradas != null)
                            SorteoPanel(jugadores: _c.jugadores, tiradas: _c.sorteoTiradas!, ganadorId: _c.sorteoGanadorId),
                          JugadoresStatusRow(jugadores: _c.jugadores),
                          const SizedBox(height: 8),
                          BoardWidget(
                            layoutCasillas: _c.partida!.layoutCasillas,
                            jugadores: _c.jugadores,
                            animatingPlayerId: _c.animatingPlayerId,
                            animatingPos: _c.animatingPos,
                            sufriendoPlayerId: _c.sufriendoPlayerId,
                          ),
                          DiceWidget(
                            habilitado: _c.diceHabilitado && _c.overlay == GameOverlay.none,
                            rodando: _c.diceRodando,
                            valorFinal: _c.diceValorMostrado,
                            onTap: _c.tirarDado,
                          ),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_c.gameMsg, textAlign: TextAlign.center)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => _salir(context),
                            child: const Text('Salir del juego'),
                          ),
                          const SizedBox(height: 16),
                          _leyenda(),
                        ],
                      ),
                    ),
                  ),
                ),
                _overlayActual(),
              ],
            );
          },
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
          pregunta: _c.triviaActual!,
          segundos: _c.triviaSegundosRestantes,
          onResponder: _c.responderTrivia,
        );
      case GameOverlay.tresCuestionados:
        return TriviaOverlay(
          titulo: '🎯 Desafío',
          pregunta: _c.triviaActual!,
          segundos: 0,
          onResponder: _c.responderTrivia,
        );
      case GameOverlay.minijuegoCasilla:
      case GameOverlay.transicionMinijuego:
        return MinijuegoOverlay(
          titulo: _c.overlay == GameOverlay.transicionMinijuego ? '🎉 ¡Etapa superada!' : '🎮 ¡Casilla de minijuego!',
          tipo: _c.minijuegoTipo ?? 'reflejos',
          onDone: _c.resolverMinijuegoActual,
        );
      case GameOverlay.transicionRuleta:
        return RuletaOverlay(
          girando: _c.wheelGirando,
          listaParaContinuar: _c.wheelListaParaContinuar,
          resultado: _c.wheelResultLabel,
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
      case GameOverlay.sorteo:
      case GameOverlay.none:
        return const SizedBox.shrink();
    }
  }

  Widget _leyenda() {
    const items = [
      ('#FFD93D', 'Oca: Cuestionados, acertá y tirás de nuevo'),
      ('#4FD8E0', 'Puente: salto directo'),
      ('#5C7CFA', 'Cárcel: Cuestionados o perdés turno'),
      ('#FF7043', 'Calavera: Cuestionados difícil o volvés al inicio'),
      ('#29B6F6', 'Minijuego: reflejos o memoria'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final it in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 9, height: 9, color: Color(int.parse(it.$1.replaceFirst('#', '0xFF')))),
              const SizedBox(width: 3),
              Text(it.$2, style: const TextStyle(fontSize: 10.5, color: Color(0xFF7A6A99))),
            ],
          ),
      ],
    );
  }
}
