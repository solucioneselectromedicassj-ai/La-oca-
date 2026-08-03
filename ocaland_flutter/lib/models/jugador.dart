/// Fila de la tabla `jugadores_partida`. Campos mutables por la misma razón
/// que en [Partida]: el modo solo los mantiene como estado local para poder
/// jugar offline.
class JugadorPartida {
  String id;
  String partidaId;
  String? usuarioId;
  String nombre;
  bool esBot;
  int posicion;
  int ordenTurno;
  String? edadBracket;
  String? pais;
  bool saltaTurno;
  int victorias;
  String? comodinPendiente;

  JugadorPartida({
    required this.id,
    required this.partidaId,
    this.usuarioId,
    required this.nombre,
    required this.esBot,
    required this.posicion,
    required this.ordenTurno,
    this.edadBracket,
    this.pais,
    required this.saltaTurno,
    required this.victorias,
    this.comodinPendiente,
  });

  factory JugadorPartida.fromJson(Map<String, dynamic> j) => JugadorPartida(
        id: j['id'] as String,
        partidaId: j['partida_id'] as String,
        usuarioId: j['usuario_id'] as String?,
        nombre: j['nombre'] as String? ?? '',
        esBot: j['es_bot'] as bool? ?? false,
        posicion: (j['posicion'] as num?)?.toInt() ?? 0,
        ordenTurno: (j['orden_turno'] as num?)?.toInt() ?? 0,
        edadBracket: j['edad_bracket'] as String?,
        pais: j['pais'] as String?,
        saltaTurno: j['salta_turno'] as bool? ?? false,
        victorias: (j['victorias'] as num?)?.toInt() ?? 0,
        comodinPendiente: j['comodin_pendiente'] as String?,
      );

  /// Aplica localmente el mismo mapa de valores que se manda en un
  /// `.update(values)` a Supabase (ver [Partida.applyPatch]).
  void applyPatch(Map<String, dynamic> values) {
    if (values.containsKey('nombre')) nombre = values['nombre'] as String;
    if (values.containsKey('posicion')) posicion = (values['posicion'] as num).toInt();
    if (values.containsKey('orden_turno')) ordenTurno = (values['orden_turno'] as num).toInt();
    if (values.containsKey('edad_bracket')) edadBracket = values['edad_bracket'] as String?;
    if (values.containsKey('pais')) pais = values['pais'] as String?;
    if (values.containsKey('salta_turno')) saltaTurno = values['salta_turno'] as bool;
    if (values.containsKey('victorias')) victorias = (values['victorias'] as num).toInt();
    if (values.containsKey('comodin_pendiente')) comodinPendiente = values['comodin_pendiente'] as String?;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'partida_id': partidaId,
        'usuario_id': usuarioId,
        'nombre': nombre,
        'es_bot': esBot,
        'posicion': posicion,
        'orden_turno': ordenTurno,
        'edad_bracket': edadBracket,
        'pais': pais,
        'salta_turno': saltaTurno,
        'victorias': victorias,
        'comodin_pendiente': comodinPendiente,
      };
}
