/// Espeja la tabla `la_vuelta.jugadores_partida`.
class JugadorPartida {
  final String id;
  final String partidaId;
  final String? usuarioId;
  final String nombre;
  final bool esBot;
  final int posicion;
  final int? ordenTurno;
  final String? edadBracket;
  final String? pais;
  final bool saltaTurno;
  final int victorias;
  final String? comodinPendiente;
  final DateTime createdAt;

  const JugadorPartida({
    required this.id,
    required this.partidaId,
    required this.nombre,
    required this.esBot,
    required this.posicion,
    required this.saltaTurno,
    required this.victorias,
    required this.createdAt,
    this.usuarioId,
    this.ordenTurno,
    this.edadBracket,
    this.pais,
    this.comodinPendiente,
  });

  factory JugadorPartida.fromMap(Map<String, dynamic> map) {
    return JugadorPartida(
      id: map['id'] as String,
      partidaId: map['partida_id'] as String,
      usuarioId: map['usuario_id'] as String?,
      nombre: map['nombre'] as String,
      esBot: map['es_bot'] as bool? ?? false,
      posicion: map['posicion'] as int? ?? 0,
      ordenTurno: map['orden_turno'] as int?,
      edadBracket: map['edad_bracket'] as String?,
      pais: map['pais'] as String?,
      saltaTurno: map['salta_turno'] as bool? ?? false,
      victorias: map['victorias'] as int? ?? 0,
      comodinPendiente: map['comodin_pendiente'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
