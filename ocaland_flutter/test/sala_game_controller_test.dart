import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/jugador.dart';
import 'package:ocaland_flutter/models/partida.dart';
import 'package:ocaland_flutter/models/usuario.dart';
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
}
