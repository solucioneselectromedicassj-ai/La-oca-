import 'board_layout.dart';

/// Fila de la tabla `partidas`.
class Partida {
  final String id;
  final String codigo;
  final String estado; // esperando | en_curso | finalizada | desempate
  final String? modo; // null/tanda | campana_grupal
  final int maxJugadores;
  final int turnoActual;
  final String? estadoTurno; // sorteo | resolviendo_trivia | jugando_minijuego | null
  final int rondaActual;
  final int etapaActual;
  final String? ultimoGanadorId;
  final int rachaGanador;
  final String? ganadorTandaId;
  final List<String> desempatePendientes;
  final int desempateTurnoIdx;
  final Map<String, dynamic>? sorteoTiradas;
  final Map<int, String> layoutCasillas;
  final Map<int, int> layoutPuentes;
  final String? triviaPreguntaActual;
  final DateTime? turnoVenceTs;

  Partida({
    required this.id,
    required this.codigo,
    required this.estado,
    this.modo,
    required this.maxJugadores,
    required this.turnoActual,
    this.estadoTurno,
    required this.rondaActual,
    required this.etapaActual,
    this.ultimoGanadorId,
    required this.rachaGanador,
    this.ganadorTandaId,
    required this.desempatePendientes,
    required this.desempateTurnoIdx,
    this.sorteoTiradas,
    required this.layoutCasillas,
    required this.layoutPuentes,
    this.triviaPreguntaActual,
    this.turnoVenceTs,
  });

  factory Partida.fromJson(Map<String, dynamic> j) => Partida(
        id: j['id'] as String,
        codigo: j['codigo'] as String,
        estado: j['estado'] as String? ?? 'esperando',
        modo: j['modo'] as String?,
        maxJugadores: (j['max_jugadores'] as num?)?.toInt() ?? 6,
        turnoActual: (j['turno_actual'] as num?)?.toInt() ?? 0,
        estadoTurno: j['estado_turno'] as String?,
        rondaActual: (j['ronda_actual'] as num?)?.toInt() ?? 1,
        etapaActual: (j['etapa_actual'] as num?)?.toInt() ?? 1,
        ultimoGanadorId: j['ultimo_ganador_id'] as String?,
        rachaGanador: (j['racha_ganador'] as num?)?.toInt() ?? 0,
        ganadorTandaId: j['ganador_tanda_id'] as String?,
        desempatePendientes: (j['desempate_pendientes'] as List?)?.map((e) => e.toString()).toList() ?? [],
        desempateTurnoIdx: (j['desempate_turno_idx'] as num?)?.toInt() ?? 0,
        sorteoTiradas: j['sorteo_tiradas'] as Map<String, dynamic>?,
        layoutCasillas: BoardEngine.parseLayoutCasillas(j['layout_casillas'] as Map<String, dynamic>?),
        layoutPuentes: BoardEngine.parseLayoutPuentes(j['layout_puentes'] as Map<String, dynamic>?),
        triviaPreguntaActual: j['trivia_pregunta_actual'] as String?,
        turnoVenceTs: j['turno_vence_ts'] != null ? DateTime.tryParse(j['turno_vence_ts'] as String) : null,
      );

  bool get esCampanaGrupal => modo == 'campana_grupal';
}
