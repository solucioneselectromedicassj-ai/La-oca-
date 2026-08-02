/// Fila de la tabla `jugadores_partida`.
class JugadorPartida {
  final String id;
  final String partidaId;
  final String? usuarioId;
  final String nombre;
  final bool esBot;
  final int posicion;
  final int ordenTurno;
  final String? edadBracket;
  final String? pais;
  final bool saltaTurno;
  final int victorias;
  final String? comodinPendiente;

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
}
