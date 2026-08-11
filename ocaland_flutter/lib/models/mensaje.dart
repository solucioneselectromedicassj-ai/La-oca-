/// Fila de `mensajes`: buzón de avisos que llega entre dispositivos (a
/// diferencia de sellos/comodines, que son solo locales). Lo escriben tanto
/// el sistema (avisos de la mascota) como otros usuarios (invitaciones).
class Mensaje {
  final String id;
  final String? remitenteUsuarioId;
  final String? remitenteNombre;
  final String tipo;
  final String texto;
  final Map<String, dynamic>? payload;
  final bool leido;
  final DateTime creadoEn;

  const Mensaje({
    required this.id,
    this.remitenteUsuarioId,
    this.remitenteNombre,
    required this.tipo,
    required this.texto,
    this.payload,
    required this.leido,
    required this.creadoEn,
  });

  factory Mensaje.fromJson(Map<String, dynamic> j) => Mensaje(
        id: j['id'] as String,
        remitenteUsuarioId: j['remitente_usuario_id'] as String?,
        remitenteNombre: j['remitente_nombre'] as String?,
        tipo: j['tipo'] as String,
        texto: j['texto'] as String,
        payload: j['payload'] as Map<String, dynamic>?,
        leido: j['leido'] as bool,
        creadoEn: DateTime.parse(j['creado_en'] as String),
      );
}
