/// Espeja la tabla `la_vuelta.usuarios`.
class Usuario {
  final String id;
  final String nombre;
  final DateTime creadoEn;
  final DateTime ultimaConexion;
  final int rachaDias;
  final int partidasJugadas;
  final int partidasGanadas;
  final int campanasCompletadas;
  final int? mejorTiempoCampanaMs;
  final int monedas;
  final String? onesignalPlayerId;
  final double multiplicadorValor;
  final DateTime? multiplicadorVenceTs;
  final DateTime? ultimaRuletaBonus;
  final DateTime? ultimoShareApp;
  final int minutosActivosHoy;
  final DateTime? fechaActividad;
  final String? codigoReferido;
  final String? referidoPor;
  final int amigosInvitados;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.creadoEn,
    required this.ultimaConexion,
    required this.rachaDias,
    required this.partidasJugadas,
    required this.partidasGanadas,
    required this.campanasCompletadas,
    required this.monedas,
    required this.multiplicadorValor,
    required this.minutosActivosHoy,
    required this.amigosInvitados,
    this.mejorTiempoCampanaMs,
    this.onesignalPlayerId,
    this.multiplicadorVenceTs,
    this.ultimaRuletaBonus,
    this.ultimoShareApp,
    this.fechaActividad,
    this.codigoReferido,
    this.referidoPor,
  });

  bool get tieneMultiplicadorActivo =>
      multiplicadorVenceTs != null &&
      multiplicadorVenceTs!.isAfter(DateTime.now()) &&
      multiplicadorValor > 1;

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
      ultimaConexion: DateTime.parse(map['ultima_conexion'] as String),
      rachaDias: map['racha_dias'] as int? ?? 1,
      partidasJugadas: map['partidas_jugadas'] as int? ?? 0,
      partidasGanadas: map['partidas_ganadas'] as int? ?? 0,
      campanasCompletadas: map['campanas_completadas'] as int? ?? 0,
      mejorTiempoCampanaMs: map['mejor_tiempo_campana_ms'] as int?,
      monedas: map['monedas'] as int? ?? 0,
      onesignalPlayerId: map['onesignal_player_id'] as String?,
      multiplicadorValor:
          (map['multiplicador_valor'] as num?)?.toDouble() ?? 1.0,
      multiplicadorVenceTs: map['multiplicador_vence_ts'] != null
          ? DateTime.parse(map['multiplicador_vence_ts'] as String)
          : null,
      ultimaRuletaBonus: map['ultima_ruleta_bonus'] != null
          ? DateTime.parse(map['ultima_ruleta_bonus'] as String)
          : null,
      ultimoShareApp: map['ultimo_share_app'] != null
          ? DateTime.parse(map['ultimo_share_app'] as String)
          : null,
      minutosActivosHoy: map['minutos_activos_hoy'] as int? ?? 0,
      fechaActividad: map['fecha_actividad'] != null
          ? DateTime.parse(map['fecha_actividad'] as String)
          : null,
      codigoReferido: map['codigo_referido'] as String?,
      referidoPor: map['referido_por'] as String?,
      amigosInvitados: map['amigos_invitados'] as int? ?? 0,
    );
  }
}
