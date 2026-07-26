import 'dart:ui';

import '../board_layout.dart';
import '../camino_tablero.dart';
import '../game_engine.dart';
import 'config_etapa.dart';

enum Turno { jugador, bot }

/// Estado de una partida de campaña Solo contra un bot: una etapa a la
/// vez, tablero regenerado en cada etapa (sección 6.1).
class CampanaSoloController {
  CampanaSoloController({this.edadBracket = 'adultos'});

  final String edadBracket;

  int etapa = 1;
  late BoardLayout layout;
  late GameEngine engine;
  late ConfigEtapa config;

  /// Forma del camino serpenteante de esta etapa (no siempre la misma,
  /// igual que el layout de trampas).
  late List<Offset> camino;

  int posJugador = 0;
  int posBot = 0;
  bool jugadorSaltaTurno = false;
  bool botSaltaTurno = false;
  int reintentosEtapa = 0;
  Turno turno = Turno.jugador;

  void iniciarEtapa(int numero) {
    etapa = numero;
    layout = BoardLayout.generar();
    engine = GameEngine(layout);
    config = ConfigEtapa.generar(numero);
    camino = CaminoTablero.generar(BoardLayout.meta + 1);
    posJugador = 0;
    posBot = 0;
    jugadorSaltaTurno = false;
    botSaltaTurno = false;
    turno = Turno.jugador;
  }

  void reintentarEtapa() => iniciarEtapa(etapa);
}
