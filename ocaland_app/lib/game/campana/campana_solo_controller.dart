import 'dart:ui';

import '../board_layout.dart';
import '../camino_tablero.dart';
import '../game_engine.dart';
import '../tablero_carnaval.dart';
import '../tablero_lava.dart';
import 'comodin_ruleta.dart';
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

  /// A partir de la etapa 7 (bloques Tensión y Cima) el tablero no
  /// dibuja un sendero: las casillas quedan sueltas/flotando y sin
  /// cárcel, pedido explícito del usuario. `board_screen.dart` y
  /// `tablero_widget.dart` usan esto para no pintar el camino de
  /// tierra ni la decoración que depende de su dirección.
  bool get sinSendero => etapa >= 7;

  /// Últimas etapas del bloque Tensión (8 y 9): más trampas que la
  /// primera del bloque, pedido explícito del usuario.
  bool get trampasIntensas => etapa >= 8 && etapa <= 9;

  int posJugador = 0;
  int posBot = 0;
  bool jugadorSaltaTurno = false;
  bool botSaltaTurno = false;
  int reintentosEtapa = 0;
  Turno turno = Turno.jugador;

  /// Comodín ganado en la ruleta de premio, pendiente de consumir
  /// (sección 9). `ventaja3` se aplica y se limpia acá mismo al arrancar
  /// la etapa; los demás quedan pendientes hasta que la jugada los use.
  ComodinRuleta? comodinPendiente;

  void iniciarEtapa(int numero) {
    etapa = numero;
    layout = BoardLayout.generar(sinCarcel: sinSendero, trampasIntensas: trampasIntensas);
    engine = GameEngine(layout);
    config = ConfigEtapa.generar(numero);
    camino = switch (numero) {
      10 => TableroCarnaval.generar(BoardLayout.meta + 1),
      >= 7 => TableroLava.generar(BoardLayout.meta + 1),
      // El usuario marcó que en el valle (4-6) el sendero llegaba
      // hasta las montañas de los bordes de la imagen — se angosta
      // hacia el centro para que se quede en la franja abierta.
      >= 4 && <= 6 => CaminoTablero.generar(
          BoardLayout.meta + 1,
          forma: FormaCamino.deEtapa(numero),
          escalaHorizontal: 0.55,
        ),
      _ => CaminoTablero.generar(BoardLayout.meta + 1, forma: FormaCamino.deEtapa(numero)),
    };
    posJugador = 0;
    posBot = 0;
    jugadorSaltaTurno = false;
    botSaltaTurno = false;
    turno = Turno.jugador;

    if (comodinPendiente == ComodinRuleta.ventaja3) {
      posJugador = 3;
      comodinPendiente = null;
    }
  }

  void reintentarEtapa() => iniciarEtapa(etapa);
}
