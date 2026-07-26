/// Espeja la tabla `la_vuelta.partidas`.
enum EstadoPartida { esperando, enCurso, finalizada, desempate }

enum ModoPartida { tanda, campanaGrupal }

EstadoPartida estadoPartidaFromDb(String value) {
  switch (value) {
    case 'en_curso':
      return EstadoPartida.enCurso;
    case 'finalizada':
      return EstadoPartida.finalizada;
    case 'desempate':
      return EstadoPartida.desempate;
    case 'esperando':
    default:
      return EstadoPartida.esperando;
  }
}

ModoPartida modoPartidaFromDb(String value) {
  return value == 'campana_grupal' ? ModoPartida.campanaGrupal : ModoPartida.tanda;
}

class Partida {
  final String id;
  final String? codigo;
  final EstadoPartida estado;
  final ModoPartida modo;
  final int maxJugadores;
  final int turnoActual;
  final String? estadoTurno;
  final int rondaActual;
  final int etapaActual;
  final String? ultimoGanadorId;
  final int rachaGanador;
  final String? ganadorTandaId;
  final List<String> desempatePendientes;
  final int desempateTurnoIdx;
  final Map<String, dynamic>? sorteoTiradas;
  final Map<String, dynamic>? layoutCasillas;
  final Map<String, dynamic>? layoutPuentes;
  final String? triviaPreguntaActual;
  final DateTime? turnoVenceTs;
  final DateTime createdAt;

  const Partida({
    required this.id,
    required this.estado,
    required this.modo,
    required this.maxJugadores,
    required this.turnoActual,
    required this.rondaActual,
    required this.etapaActual,
    required this.rachaGanador,
    required this.desempatePendientes,
    required this.desempateTurnoIdx,
    required this.createdAt,
    this.codigo,
    this.estadoTurno,
    this.ultimoGanadorId,
    this.ganadorTandaId,
    this.sorteoTiradas,
    this.layoutCasillas,
    this.layoutPuentes,
    this.triviaPreguntaActual,
    this.turnoVenceTs,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    return Partida(
      id: map['id'] as String,
      codigo: map['codigo'] as String?,
      estado: estadoPartidaFromDb(map['estado'] as String),
      modo: modoPartidaFromDb(map['modo'] as String),
      maxJugadores: map['max_jugadores'] as int? ?? 6,
      turnoActual: map['turno_actual'] as int? ?? 0,
      estadoTurno: map['estado_turno'] as String?,
      rondaActual: map['ronda_actual'] as int? ?? 1,
      etapaActual: map['etapa_actual'] as int? ?? 1,
      ultimoGanadorId: map['ultimo_ganador_id'] as String?,
      rachaGanador: map['racha_ganador'] as int? ?? 0,
      ganadorTandaId: map['ganador_tanda_id'] as String?,
      desempatePendientes:
          (map['desempate_pendientes'] as List?)?.cast<String>() ?? const [],
      desempateTurnoIdx: map['desempate_turno_idx'] as int? ?? 0,
      sorteoTiradas: map['sorteo_tiradas'] as Map<String, dynamic>?,
      layoutCasillas: map['layout_casillas'] as Map<String, dynamic>?,
      layoutPuentes: map['layout_puentes'] as Map<String, dynamic>?,
      triviaPreguntaActual: map['trivia_pregunta_actual'] as String?,
      turnoVenceTs: map['turno_vence_ts'] != null
          ? DateTime.parse(map['turno_vence_ts'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
