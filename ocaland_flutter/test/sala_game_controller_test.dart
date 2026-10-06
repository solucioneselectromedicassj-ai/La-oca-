import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/jugador.dart';
import 'package:ocaland_flutter/models/partida.dart';
import 'package:ocaland_flutter/models/usuario.dart';
import 'package:ocaland_flutter/services/audio_service.dart';
import 'package:ocaland_flutter/services/sala_game_controller.dart';

Usuario _usuario() => Usuario(
      id: 'u1',
      nombre: 'Pablo',
      rachaDias: 1,
      partidasJugadas: 0,
      partidasGanadas: 0,
      campanasCompletadas: 0,
      monedas: 0,
      minutosActivosHoy: 0,
      amigosInvitados: 0,
    );

JugadorPartida _jugador({required String id, required int ordenTurno, bool saltaTurno = false}) => JugadorPartida(
      id: id,
      partidaId: 'p1',
      nombre: id,
      esBot: false,
      posicion: 0,
      ordenTurno: ordenTurno,
      saltaTurno: saltaTurno,
      victorias: 0,
    );

Partida _partida({required String estado, required int turnoActual}) => Partida.fromJson({
      'id': 'p1',
      'codigo': 'ABCD',
      'estado': estado,
      'max_jugadores': 6,
      'turno_actual': turnoActual,
      'ronda_actual': 1,
      'etapa_actual': 1,
      'racha_ganador': 0,
      'desempate_pendientes': [],
      'desempate_turno_idx': 0,
    });

void main() {
  group('SalaGameController.diceHabilitado', () {
    test('habilitado cuando es mi turno y la partida está en curso', () {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)];
      c.partida = _partida(estado: 'en_curso', turnoActual: 0);

      expect(c.diceHabilitado, isTrue);
    });

    test('deshabilitado cuando es el turno de otro jugador', () {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)];
      c.partida = _partida(estado: 'en_curso', turnoActual: 1);

      expect(c.diceHabilitado, isFalse);
    });

    test('deshabilitado si estoy preso (salta_turno)', () {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [_jugador(id: 'yo', ordenTurno: 0, saltaTurno: true), _jugador(id: 'otro', ordenTurno: 1)];
      c.partida = _partida(estado: 'en_curso', turnoActual: 0);

      expect(c.diceHabilitado, isFalse);
    });

    test('deshabilitado si la partida no está en curso (esperando/finalizada/desempate)', () {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)];

      for (final estado in ['esperando', 'finalizada', 'desempate']) {
        c.partida = _partida(estado: estado, turnoActual: 0);
        expect(c.diceHabilitado, isFalse, reason: 'estado=$estado');
      }
    });

    test('deshabilitado mientras hay un overlay abierto (trivia, minijuego, sorteo)', () {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = 'yo';
      c.jugadores = [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)];
      c.partida = _partida(estado: 'en_curso', turnoActual: 0);

      for (final ov in [MpOverlay.trivia, MpOverlay.minijuego, MpOverlay.sorteo, MpOverlay.transicionMinijuego, MpOverlay.transicionRuleta]) {
        c.overlay = ov;
        expect(c.diceHabilitado, isFalse, reason: 'overlay=$ov');
      }
      c.overlay = MpOverlay.none;
      expect(c.diceHabilitado, isTrue);
    });
  });

  group('SalaGameController — medidor compartido', () {
    // responderMedidor() toca AudioService.correct()/.wrong(), que en un
    // test sin binding de widgets intenta crear reproductores reales de
    // audio (falla con "Binding has not yet been initialized"). Lo
    // apagamos acá — no es lo que se está probando.
    setUp(() => AudioService.enabled = false);
    tearDown(() => AudioService.enabled = true);

    SalaGameController controller({required List<JugadorPartida> jugadores, required String estado, required int turnoActual, required String myPlayerId}) {
      final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
      c.myPlayerId = myPlayerId;
      c.jugadores = jugadores;
      c.partida = _partida(estado: estado, turnoActual: turnoActual);
      return c;
    }

    test('no es visible si la partida no está en curso', () {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)],
        estado: 'esperando',
        turnoActual: 0,
        myPlayerId: 'yo',
      );
      expect(c.medidorVisible, isFalse);
    });

    test('no es visible si no hay nadie esperando (el único rival es un bot)', () {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'bot', ordenTurno: 1)..esBot = true],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'yo',
      );
      expect(c.medidorVisible, isFalse);
    });

    test('medidorJugadorActual excluye a quien tiene el turno del tablero y a los bots', () {
      final c = controller(
        jugadores: [
          _jugador(id: 'yo', ordenTurno: 0),
          _jugador(id: 'rival', ordenTurno: 1),
          _jugador(id: 'bot', ordenTurno: 2)..esBot = true,
        ],
        estado: 'en_curso',
        turnoActual: 0, // le toca a "yo" en el tablero
        myPlayerId: 'yo',
      );
      expect(c.medidorJugadorActual?.id, 'rival');
      expect(c.medidorVisible, isTrue);
    });

    test('medidorEsMiTurno solo es true para quien le toca, y no mientras hay una pregunta abierta', () {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'rival', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0, // le toca a "yo" en el tablero -> el del medidor es "rival"
        myPlayerId: 'rival',
      );
      expect(c.medidorEsMiTurno, isTrue);
      c.abrirPreguntaMedidor();
      expect(c.medidorPregunta, isNotNull);
      expect(c.medidorEsMiTurno, isFalse, reason: 'mientras hay una pregunta abierta no se puede volver a abrir otra');
    });

    test('abrirPreguntaMedidor no hace nada si no es mi turno de medidor', () {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'rival', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'yo', // "yo" tiene el turno del tablero, no del medidor
      );
      expect(c.medidorEsMiTurno, isFalse);
      c.abrirPreguntaMedidor();
      expect(c.medidorPregunta, isNull);
    });

    test('responderMedidor: acertar suma un punto y pasa el turno al siguiente que espera', () async {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'rival', ordenTurno: 1), _jugador(id: 'otro', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0, // esperan "rival" y "otro"
        myPlayerId: 'rival',
      );
      expect(c.medidorJugadorActual?.id, 'rival');
      c.abrirPreguntaMedidor();
      final correcta = c.medidorPregunta!.correct;

      await c.responderMedidor(correcta);

      expect(c.medidorValor, 1);
      expect(c.medidorPregunta, isNull);
      expect(c.medidorJugadorActual?.id, 'otro', reason: 'el turno del medidor rota al siguiente jugador en espera');
    });

    test('responderMedidor: fallar resta un punto sin bajar de 0', () async {
      final c = controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'rival', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'rival',
      );
      c.abrirPreguntaMedidor();
      final incorrecta = (c.medidorPregunta!.correct + 1) % c.medidorPregunta!.options.length;

      await c.responderMedidor(incorrecta);

      expect(c.medidorValor, 0);
    });
  });
}
