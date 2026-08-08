import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/jugador.dart';
import 'package:ocaland_flutter/models/partida.dart';
import 'package:ocaland_flutter/models/sesion_activa.dart';
import 'package:ocaland_flutter/models/trivia_bank.dart';
import 'package:ocaland_flutter/models/usuario.dart';
import 'package:ocaland_flutter/services/solo_game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Usuario _usuario() => Usuario(
      id: '',
      nombre: 'Pablo',
      rachaDias: 1,
      partidasJugadas: 0,
      partidasGanadas: 0,
      campanasCompletadas: 0,
      monedas: 0,
      minutosActivosHoy: 0,
      amigosInvitados: 0,
    );

Map<String, dynamic> _partidaJson({required int turnoActual, required int etapaActual}) => {
      'id': 'p1',
      'codigo': 'ABCD',
      'estado': 'en_curso',
      'max_jugadores': 2,
      'turno_actual': turnoActual,
      'ronda_actual': 1,
      'etapa_actual': etapaActual,
      'racha_ganador': 0,
      'desempate_pendientes': [],
      'desempate_turno_idx': 0,
      'layout_casillas': <String, dynamic>{},
      'layout_puentes': <String, dynamic>{},
    };

Map<String, dynamic> _jugadorJson({required String id, required int ordenTurno, required bool esBot, int posicion = 0, bool saltaTurno = false}) => {
      'id': id,
      'partida_id': 'p1',
      'nombre': esBot ? 'Bot' : 'Pablo',
      'es_bot': esBot,
      'posicion': posicion,
      'orden_turno': ordenTurno,
      'edad_bracket': 'adultos',
      'pais': 'argentina',
      'salta_turno': saltaTurno,
      'victorias': 0,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SoloGameController — modo offline', () {
    test('reanudar() restaura la partida y jugadores desde el snapshot local, sin red', () async {
      final sesion = SesionActiva(
        partidaId: 'p1',
        playerId: 'yo',
        nombre: 'Pablo',
        edadBracket: 'adultos',
        pais: 'argentina',
        codigo: 'ABCD',
        esModoSolo: true,
        snapshot: {
          'partida': _partidaJson(turnoActual: 0, etapaActual: 3),
          'jugadores': [
            _jugadorJson(id: 'yo', ordenTurno: 0, esBot: false, posicion: 7),
            _jugadorJson(id: 'bot', ordenTurno: 1, esBot: true, posicion: 5),
          ],
          'myPlayerId': 'yo',
          'reintentosEtapaActual': 2,
          'campanaInicioTs': DateTime.now().toIso8601String(),
          'etapaInicioTs': DateTime.now().toIso8601String(),
        },
      );

      final c = SoloGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      await c.reanudar(sesion);

      expect(c.cargando, isFalse);
      expect(c.partida?.id, 'p1');
      expect(c.partida?.etapaActual, 3);
      expect(c.jugadores.length, 2);
      expect(c.yo?.posicion, 7);
      expect(c.reintentosEtapaActual, 2);
      // Es mi turno (turnoActual apunta a mi orden_turno, no soy bot, no estoy preso).
      expect(c.diceHabilitado, isTrue);
    });

    test('reanudar() rechaza una sesión sin snapshot (versión anterior sin modo offline)', () async {
      final sesion = SesionActiva(
        partidaId: 'p1',
        playerId: 'yo',
        nombre: 'Pablo',
        edadBracket: 'adultos',
        pais: 'argentina',
        codigo: 'ABCD',
        esModoSolo: true,
      );
      final c = SoloGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      expect(() => c.reanudar(sesion), throwsException);
    });
  });

  group('SoloGameController.diceHabilitado', () {
    // Regresión: antes era un campo que había que acordarse de resetear en
    // cada lugar del código; si algún camino se olvidaba, el dado quedaba
    // trabado en false aunque fuera mi turno (el título "¡Tu turno!" usa
    // esMiTurno, que sí está siempre al día). Ahora es un getter calculado
    // en vivo a partir del mismo estado, así no puede desincronizarse.
    JugadorPartida jugador({required String id, required int ordenTurno, bool esBot = false, bool saltaTurno = false}) => JugadorPartida.fromJson({
          'id': id,
          'partida_id': 'p1',
          'nombre': id,
          'es_bot': esBot,
          'posicion': 0,
          'orden_turno': ordenTurno,
          'salta_turno': saltaTurno,
          'victorias': 0,
        });

    SoloGameController controller() => SoloGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');

    test('habilitado cuando es mi turno y la partida está en curso', () {
      final c = controller();
      c.myPlayerId = 'yo';
      c.jugadores = [jugador(id: 'yo', ordenTurno: 0), jugador(id: 'bot', ordenTurno: 1, esBot: true)];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 0, etapaActual: 1));

      expect(c.diceHabilitado, isTrue);
    });

    test('deshabilitado cuando le toca al bot', () {
      final c = controller();
      c.myPlayerId = 'yo';
      c.jugadores = [jugador(id: 'yo', ordenTurno: 0), jugador(id: 'bot', ordenTurno: 1, esBot: true)];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 1, etapaActual: 1));

      expect(c.diceHabilitado, isFalse);
    });

    test('deshabilitado si estoy preso (salta_turno)', () {
      final c = controller();
      c.myPlayerId = 'yo';
      c.jugadores = [jugador(id: 'yo', ordenTurno: 0, saltaTurno: true), jugador(id: 'bot', ordenTurno: 1, esBot: true)];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 0, etapaActual: 1));

      expect(c.diceHabilitado, isFalse);
    });

    test('deshabilitado mientras hay un overlay abierto o el dado está rodando', () {
      final c = controller();
      c.myPlayerId = 'yo';
      c.jugadores = [jugador(id: 'yo', ordenTurno: 0), jugador(id: 'bot', ordenTurno: 1, esBot: true)];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 0, etapaActual: 1));

      for (final ov in [GameOverlay.trivia, GameOverlay.sorteo, GameOverlay.minijuegoCasilla, GameOverlay.transicionRuleta]) {
        c.overlay = ov;
        expect(c.diceHabilitado, isFalse, reason: 'overlay=$ov');
      }
      c.overlay = GameOverlay.none;
      expect(c.diceHabilitado, isTrue);

      c.diceRodando = true;
      expect(c.diceHabilitado, isFalse);
    });

    test('habilitado justo después de que el bot resuelve una trampa y me vuelve a tocar a mí', () {
      // Reproduce el escenario reportado: el bot cae en la cárcel, se salva,
      // termina su turno (turno_actual pasa a mí, estado_turno vuelve a
      // null) y no queda ningún overlay abierto.
      final c = controller();
      c.myPlayerId = 'yo';
      c.jugadores = [jugador(id: 'yo', ordenTurno: 0), jugador(id: 'bot', ordenTurno: 1, esBot: true)];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 1, etapaActual: 2)); // turno del bot
      c.overlay = GameOverlay.none;
      expect(c.diceHabilitado, isFalse, reason: 'todavía es el turno del bot');

      c.partida!.applyPatch({'turno_actual': 0, 'estado_turno': null}); // termina el turno del bot
      expect(c.diceHabilitado, isTrue);
    });
  });

  group('SoloGameController.pedirPista', () {
    // Regresión: pedir la pista pausaba el diálogo de "video o monedas"
    // pero dejaba corriendo el timer de la trivia en segundo plano, y
    // nunca volvía a mostrar la trivia después — si el timer vencía
    // mientras se elegía, o incluso al elegir normalmente, el juego
    // quedaba sin overlay visible y el dado sin poder tirarse (trabado).
    test('vuelve a mostrar la trivia (no queda trabado) después de conseguir la pista con sellos', () async {
      // SellosService lee/escribe SharedPreferences de verdad (no el campo
      // c.sellos, que es solo una copia en memoria para la UI) — hay que
      // sembrar el mock ahí para que el gasto de sellos se vea reflejado.
      SharedPreferences.setMockInitialValues({'sellos_count': 5});
      final c = SoloGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [
        JugadorPartida.fromJson(_jugadorJson(id: 'yo', ordenTurno: 0, esBot: false)),
        JugadorPartida.fromJson(_jugadorJson(id: 'bot', ordenTurno: 1, esBot: true)),
      ];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 0, etapaActual: 1));
      c.triviaActual = const TriviaQuestion('¿Test?', ['a', 'b', 'c', 'd'], 0);
      c.triviaTipo = 'carcel';
      c.sellos = 5;
      c.overlay = GameOverlay.trivia;

      final pedido = c.pedirPista();
      expect(c.overlay, GameOverlay.eleccionVideoMonedas, reason: 'se abrió el diálogo de video/monedas/sellos');

      c.elegirSellosParaEleccion();
      await pedido;

      expect(c.overlay, GameOverlay.trivia, reason: 'la trivia tiene que seguir en pantalla, no un overlay vacío');
      expect(c.triviaActual, isNotNull);
      expect(c.pistaUsada, isTrue);
      expect(c.pistaOpcionEliminada, isNotNull);
      expect(c.pistaOpcionEliminada, isNot(0)); // nunca elimina la opción correcta
      expect(c.sellos, 2); // gastó 3 de los 5 que tenía
    });

    test('también vuelve a mostrar la trivia si se cancela el diálogo de pista', () async {
      final c = SoloGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [
        JugadorPartida.fromJson(_jugadorJson(id: 'yo', ordenTurno: 0, esBot: false)),
        JugadorPartida.fromJson(_jugadorJson(id: 'bot', ordenTurno: 1, esBot: true)),
      ];
      c.partida = Partida.fromJson(_partidaJson(turnoActual: 0, etapaActual: 1));
      c.triviaActual = const TriviaQuestion('¿Test?', ['a', 'b', 'c', 'd'], 0);
      c.triviaTipo = 'carcel';
      c.overlay = GameOverlay.trivia;

      final pedido = c.pedirPista();
      c.cancelarEleccionVideoMonedas();
      await pedido;

      expect(c.overlay, GameOverlay.trivia);
      expect(c.triviaActual, isNotNull);
      expect(c.pistaUsada, isFalse);
      expect(c.pistaOpcionEliminada, isNull);
    });
  });
}
