/// Fila de la tabla `usuarios`. Identidad persistente por dispositivo
/// (sin autenticación real todavía — eso queda para una etapa posterior).
class Usuario {
  final String id;
  final String nombre;
  final int rachaDias;
  final int partidasJugadas;
  final int partidasGanadas;
  final int campanasCompletadas;
  final int? mejorTiempoCampanaMs;
  final String? onesignalPlayerId;
  final int monedas;
  final double? multiplicadorValor;
  final DateTime? multiplicadorVenceTs;
  final DateTime? ultimaRuletaBonus;
  final DateTime? ultimoShareApp;
  final int minutosActivosHoy;
  final String? codigoReferido;
  final int amigosInvitados;

  Usuario({
    required this.id,
    required this.nombre,
    required this.rachaDias,
    required this.partidasJugadas,
    required this.partidasGanadas,
    required this.campanasCompletadas,
    this.mejorTiempoCampanaMs,
    this.onesignalPlayerId,
    required this.monedas,
    this.multiplicadorValor,
    this.multiplicadorVenceTs,
    this.ultimaRuletaBonus,
    this.ultimoShareApp,
    required this.minutosActivosHoy,
    this.codigoReferido,
    required this.amigosInvitados,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as String,
        nombre: j['nombre'] as String? ?? '',
        rachaDias: (j['racha_dias'] as num?)?.toInt() ?? 1,
        partidasJugadas: (j['partidas_jugadas'] as num?)?.toInt() ?? 0,
        partidasGanadas: (j['partidas_ganadas'] as num?)?.toInt() ?? 0,
        campanasCompletadas: (j['campanas_completadas'] as num?)?.toInt() ?? 0,
        mejorTiempoCampanaMs: (j['mejor_tiempo_campana_ms'] as num?)?.toInt(),
        onesignalPlayerId: j['onesignal_player_id'] as String?,
        monedas: (j['monedas'] as num?)?.toInt() ?? 0,
        multiplicadorValor: (j['multiplicador_valor'] as num?)?.toDouble(),
        multiplicadorVenceTs: j['multiplicador_vence_ts'] != null ? DateTime.tryParse(j['multiplicador_vence_ts'] as String) : null,
        ultimaRuletaBonus: j['ultima_ruleta_bonus'] != null ? DateTime.tryParse(j['ultima_ruleta_bonus'] as String) : null,
        ultimoShareApp: j['ultimo_share_app'] != null ? DateTime.tryParse(j['ultimo_share_app'] as String) : null,
        minutosActivosHoy: (j['minutos_activos_hoy'] as num?)?.toInt() ?? 0,
        codigoReferido: j['codigo_referido'] as String?,
        amigosInvitados: (j['amigos_invitados'] as num?)?.toInt() ?? 0,
      );

  Usuario copyWith({
    int? monedas,
    int? rachaDias,
    int? partidasJugadas,
    int? partidasGanadas,
    int? campanasCompletadas,
    int? mejorTiempoCampanaMs,
    double? multiplicadorValor,
    DateTime? multiplicadorVenceTs,
    String? onesignalPlayerId,
  }) {
    return Usuario(
      id: id,
      nombre: nombre,
      rachaDias: rachaDias ?? this.rachaDias,
      partidasJugadas: partidasJugadas ?? this.partidasJugadas,
      partidasGanadas: partidasGanadas ?? this.partidasGanadas,
      campanasCompletadas: campanasCompletadas ?? this.campanasCompletadas,
      mejorTiempoCampanaMs: mejorTiempoCampanaMs ?? this.mejorTiempoCampanaMs,
      onesignalPlayerId: onesignalPlayerId ?? this.onesignalPlayerId,
      monedas: monedas ?? this.monedas,
      multiplicadorValor: multiplicadorValor ?? this.multiplicadorValor,
      multiplicadorVenceTs: multiplicadorVenceTs ?? this.multiplicadorVenceTs,
      ultimaRuletaBonus: ultimaRuletaBonus,
      ultimoShareApp: ultimoShareApp,
      minutosActivosHoy: minutosActivosHoy,
      codigoReferido: codigoReferido,
      amigosInvitados: amigosInvitados,
    );
  }
}
