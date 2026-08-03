/// Una partida/campaña en curso guardada localmente (equivalente a
/// `ocaland_sesiones_activas` en el localStorage del prototipo), para que
/// "Mis partidas" pueda ofrecer volver a entrar sin perder el lugar.
class SesionActiva {
  final String partidaId;
  final String playerId;
  final String nombre;
  final String edadBracket;
  final String pais;
  final String codigo;
  final bool esModoSolo;

  /// Solo para el modo solo: snapshot completo del estado local del juego
  /// (partida + jugadores + progreso de campaña), para poder reanudar sin
  /// depender de la red — el modo solo no guarda nada en Supabase.
  final Map<String, dynamic>? snapshot;

  const SesionActiva({
    required this.partidaId,
    required this.playerId,
    required this.nombre,
    required this.edadBracket,
    required this.pais,
    required this.codigo,
    required this.esModoSolo,
    this.snapshot,
  });

  Map<String, dynamic> toJson() => {
        'partidaId': partidaId,
        'playerId': playerId,
        'nombre': nombre,
        'edadBracket': edadBracket,
        'pais': pais,
        'codigo': codigo,
        'esModoSolo': esModoSolo,
        if (snapshot != null) 'snapshot': snapshot,
      };

  factory SesionActiva.fromJson(Map<String, dynamic> j) => SesionActiva(
        partidaId: j['partidaId'] as String,
        playerId: j['playerId'] as String,
        nombre: j['nombre'] as String,
        edadBracket: j['edadBracket'] as String,
        pais: j['pais'] as String,
        codigo: j['codigo'] as String? ?? '',
        esModoSolo: j['esModoSolo'] as bool? ?? false,
        snapshot: (j['snapshot'] as Map?)?.cast<String, dynamic>(),
      );
}
