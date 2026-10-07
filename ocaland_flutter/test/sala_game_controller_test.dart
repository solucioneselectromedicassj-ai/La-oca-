import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/flecha_desafio.dart';
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

SalaGameController _controller({required List<JugadorPartida> jugadores, required String estado, required int turnoActual, required String myPlayerId}) {
  final c = SalaGameController(usuario: _usuario(), myNombre: 'Pablo', myEdadBracket: 'adultos', myPais: 'argentina');
  c.myPlayerId = myPlayerId;
  c.jugadores = jugadores;
  c.partida = _partida(estado: estado, turnoActual: turnoActual);
  return c;
}

void main() {
  // responderMedidor()/tocarDuelo() tocan AudioService.correct()/.wrong(),
  // que en un test sin binding de widgets intenta crear reproductores
  // reales de audio ("Binding has not yet been initialized"). Se apaga
  // una sola vez para todo el archivo en vez de por test: correct() programa
  // un segundo beep 110ms después con Future.delayed, que vuelve a chequear
  // `enabled` en ese momento — reactivarlo en un tearDown entre tests deja
  // una ventana donde ese beep tardío se dispara con el audio ya reactivado
  // y explota en medio de otro test.
  AudioService.enabled = false;

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

      for (final ov in [MpOverlay.trivia, MpOverlay.minijuego, MpOverlay.sorteo, MpOverlay.transicionMinijuego, MpOverlay.transicionRuleta, MpOverlay.chequeoTurno]) {
        c.overlay = ov;
        expect(c.diceHabilitado, isFalse, reason: 'overlay=$ov');
      }
      c.overlay = MpOverlay.none;
      expect(c.diceHabilitado, isTrue);
    });
  });

  group('SalaGameController — medidor compartido', () {
    final controller = _controller;

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
      expect(c.medidorDesafio, isNotNull);
      expect(c.medidorEsMiTurno, isFalse, reason: 'mientras hay un desafío abierto no se puede volver a abrir otro');
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
      expect(c.medidorDesafio, isNull);
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
      final correcta = c.medidorDesafio!.direccion;

      await c.responderMedidor(correcta);

      expect(c.medidorValor, 1);
      expect(c.medidorDesafio, isNull);
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
      final correcta = c.medidorDesafio!.direccion;
      final incorrecta = Direccion.values.firstWhere((d) => d != correcta);

      await c.responderMedidor(incorrecta);

      expect(c.medidorValor, 0);
    });
  });

  group('SalaGameController — duelo 1 contra 1 (Ta-Te-Ti)', () {
    test('no es visible si hay menos de dos jugadores esperando', () {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'rival', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 1, // le toca a "rival" -> solo "yo" espera
        myPlayerId: 'yo',
      );
      expect(c.dueloVisible, isFalse);
    });

    test('empareja a los dos primeros en espera por orden de turno, dejando afuera a quien tira el dado y a los bots', () {
      final c = _controller(
        jugadores: [
          _jugador(id: 'yo', ordenTurno: 0),
          _jugador(id: 'rival1', ordenTurno: 1),
          _jugador(id: 'rival2', ordenTurno: 2),
          _jugador(id: 'bot', ordenTurno: 3)..esBot = true,
        ],
        estado: 'en_curso',
        turnoActual: 0, // le toca a "yo" -> esperan rival1 y rival2 (el bot queda afuera)
        myPlayerId: 'rival1',
      );
      expect(c.dueloVisible, isTrue);
      expect(c.dueloJugadorX?.id, 'rival1');
      expect(c.dueloJugadorO?.id, 'rival2');
      expect(c.soyDueloX, isTrue);
      expect(c.soyDueloO, isFalse);
      expect(c.dueloEsMiTurno, isTrue, reason: 'arranca jugando X');
    });

    test('tocarDuelo ignora el toque si no es mi turno o la celda ya está ocupada', () {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'o', // le toca a X primero, no a "o"
      );
      c.tocarDuelo(0);
      expect(c.dueloCeldas[0], isNull, reason: 'todavía no es el turno de O');

      // Si fuera mi turno (X) pero la celda ya tiene algo, tampoco hace nada.
      final cX = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'x',
      );
      cX.dueloCeldas[4] = 'X';
      cX.tocarDuelo(4);
      expect(cX.dueloCeldas[4], 'X', reason: 'no se pisa una celda ya jugada');
    });

    test('tocarDuelo juega la celda y pasa el turno al otro jugador', () {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'x',
      );
      expect(c.dueloEsMiTurno, isTrue);
      c.tocarDuelo(0);
      expect(c.dueloCeldas[0], 'X');
      expect(c.dueloTurnoX, isFalse);
      expect(c.dueloEsMiTurno, isFalse, reason: 'ahora le toca a O');
    });

    test('detecta una línea ganadora y la marca', () async {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'x',
      );
      // X: 0,1,2 (gana la fila de arriba) — O juega en el medio en cada vuelta.
      c.dueloCeldas = ['X', 'X', null, 'O', 'O', null, null, null, null];
      c.dueloTurnoX = true;
      c.tocarDuelo(2);

      expect(c.dueloGanador, 'X');
      expect(c.dueloLineaGanadora, [0, 1, 2]);
    });

    test('empate cuando se llena el tablero sin ganador', () {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'x',
      );
      c.dueloCeldas = ['X', 'O', 'X', 'X', 'O', 'O', 'O', 'X', null];
      c.dueloTurnoX = true;
      c.tocarDuelo(8);

      expect(c.dueloGanador, 'empate');
      expect(c.dueloLineaGanadora, isNull);
    });

    test('reiniciarDuelo solo funciona para quienes participan del duelo', () {
      final cEspectador = _controller(
        jugadores: [
          _jugador(id: 'yo', ordenTurno: 0),
          _jugador(id: 'x', ordenTurno: 1),
          _jugador(id: 'o', ordenTurno: 2),
          _jugador(id: 'espectador', ordenTurno: 3),
        ],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'espectador',
      );
      cEspectador.dueloCeldas[0] = 'X';
      cEspectador.dueloGanador = 'X';
      cEspectador.reiniciarDuelo();
      expect(cEspectador.dueloCeldas[0], 'X', reason: 'un espectador no puede reiniciar el duelo de otros');

      final cJugador = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'x', ordenTurno: 1), _jugador(id: 'o', ordenTurno: 2)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'x',
      );
      cJugador.dueloCeldas[0] = 'X';
      cJugador.dueloGanador = 'X';
      cJugador.reiniciarDuelo();
      expect(cJugador.dueloCeldas.every((v) => v == null), isTrue);
      expect(cJugador.dueloGanador, isNull);
      expect(cJugador.dueloTurnoX, isTrue);
    });
  });

  group('SalaGameController — chequeo de turno obligatorio', () {
    test('responderChequeoTurno con acierto suma al medidor, cierra el desafío y destraba el overlay', () async {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'yo',
      );
      final desafio = FlechaDesafio.aleatoria();
      c.chequeoDesafio = desafio;
      c.overlay = MpOverlay.chequeoTurno;

      await c.responderChequeoTurno(desafio.direccion);

      expect(c.chequeoDesafio, isNull);
      expect(c.overlay, MpOverlay.none, reason: 'al responder (bien o mal) se destraba el dado');
      expect(c.medidorValor, 1);
    });

    test('responderChequeoTurno con error también destraba el overlay (solo participar alcanza)', () async {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'yo',
      );
      final desafio = FlechaDesafio.aleatoria();
      final incorrecta = Direccion.values.firstWhere((d) => d != desafio.direccion);
      c.chequeoDesafio = desafio;
      c.overlay = MpOverlay.chequeoTurno;

      await c.responderChequeoTurno(incorrecta);

      expect(c.chequeoDesafio, isNull);
      expect(c.overlay, MpOverlay.none);
      expect(c.medidorValor, 0, reason: 'no baja de 0');
    });

    test('responderChequeoTurno no hace nada si no hay un desafío pendiente', () async {
      final c = _controller(
        jugadores: [_jugador(id: 'yo', ordenTurno: 0), _jugador(id: 'otro', ordenTurno: 1)],
        estado: 'en_curso',
        turnoActual: 0,
        myPlayerId: 'yo',
      );
      await c.responderChequeoTurno(Direccion.arriba);
      expect(c.medidorValor, 0);
    });
  });
}
