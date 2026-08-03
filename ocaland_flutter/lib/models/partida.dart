import 'board_layout.dart';

/// Fila de la tabla `partidas`. Los campos son mutables a propósito: el
/// modo solo mantiene esta instancia como estado local "fuente de verdad"
/// (para poder jugar offline) en vez de siempre reconstruirla desde una
/// respuesta de red como hace el multijugador.
class Partida {
  String id;
  String codigo;
  String estado; // esperando | en_curso | finalizada | desempate
  String? modo; // null/tanda | campana_grupal
  int maxJugadores;
  int turnoActual;
  String? estadoTurno; // sorteo | resolviendo_trivia | jugando_minijuego | null
  int rondaActual;
  int etapaActual;
  String? ultimoGanadorId;
  int rachaGanador;
  String? ganadorTandaId;
  List<String> desempatePendientes;
  int desempateTurnoIdx;
  Map<String, dynamic>? sorteoTiradas;
  Map<int, String> layoutCasillas;
  Map<int, int> layoutPuentes;
  String? triviaPreguntaActual;
  DateTime? turnoVenceTs;

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

  /// Aplica localmente el mismo mapa de valores que se manda en un
  /// `.update(values)` a Supabase — así el modo solo puede mutar su propio
  /// estado sin depender de una respuesta de red (offline-first). Solo
  /// toca las claves presentes en [values].
  void applyPatch(Map<String, dynamic> values) {
    if (values.containsKey('estado')) estado = values['estado'] as String;
    if (values.containsKey('modo')) modo = values['modo'] as String?;
    if (values.containsKey('max_jugadores')) maxJugadores = (values['max_jugadores'] as num).toInt();
    if (values.containsKey('turno_actual')) turnoActual = (values['turno_actual'] as num).toInt();
    if (values.containsKey('estado_turno')) estadoTurno = values['estado_turno'] as String?;
    if (values.containsKey('ronda_actual')) rondaActual = (values['ronda_actual'] as num).toInt();
    if (values.containsKey('etapa_actual')) etapaActual = (values['etapa_actual'] as num).toInt();
    if (values.containsKey('ultimo_ganador_id')) ultimoGanadorId = values['ultimo_ganador_id'] as String?;
    if (values.containsKey('racha_ganador')) rachaGanador = (values['racha_ganador'] as num).toInt();
    if (values.containsKey('ganador_tanda_id')) ganadorTandaId = values['ganador_tanda_id'] as String?;
    if (values.containsKey('desempate_pendientes')) {
      desempatePendientes = (values['desempate_pendientes'] as List).map((e) => e.toString()).toList();
    }
    if (values.containsKey('desempate_turno_idx')) desempateTurnoIdx = (values['desempate_turno_idx'] as num).toInt();
    if (values.containsKey('sorteo_tiradas')) sorteoTiradas = (values['sorteo_tiradas'] as Map?)?.cast<String, dynamic>();
    if (values.containsKey('layout_casillas')) {
      layoutCasillas = BoardEngine.parseLayoutCasillas((values['layout_casillas'] as Map?)?.cast<String, dynamic>());
    }
    if (values.containsKey('layout_puentes')) {
      layoutPuentes = BoardEngine.parseLayoutPuentes((values['layout_puentes'] as Map?)?.cast<String, dynamic>());
    }
    if (values.containsKey('trivia_pregunta_actual')) triviaPreguntaActual = values['trivia_pregunta_actual'] as String?;
    if (values.containsKey('turno_vence_ts')) {
      final raw = values['turno_vence_ts'] as String?;
      turnoVenceTs = raw != null ? DateTime.tryParse(raw) : null;
    }
  }

  /// Mismas claves que las columnas de la tabla `partidas` — sirve tanto
  /// para mandar un update a Supabase como para guardar un snapshot local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'estado': estado,
        'modo': modo,
        'max_jugadores': maxJugadores,
        'turno_actual': turnoActual,
        'estado_turno': estadoTurno,
        'ronda_actual': rondaActual,
        'etapa_actual': etapaActual,
        'ultimo_ganador_id': ultimoGanadorId,
        'racha_ganador': rachaGanador,
        'ganador_tanda_id': ganadorTandaId,
        'desempate_pendientes': desempatePendientes,
        'desempate_turno_idx': desempateTurnoIdx,
        'sorteo_tiradas': sorteoTiradas,
        'layout_casillas': layoutCasillas.map((k, v) => MapEntry(k.toString(), v)),
        'layout_puentes': layoutPuentes.map((k, v) => MapEntry(k.toString(), v)),
        'trivia_pregunta_actual': triviaPreguntaActual,
        'turno_vence_ts': turnoVenceTs?.toIso8601String(),
      };
}
