import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/sesion_activa.dart';
import 'package:ocaland_flutter/models/usuario.dart';
import 'package:ocaland_flutter/services/solo_game_controller.dart';

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
}
