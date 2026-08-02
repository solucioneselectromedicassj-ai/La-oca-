import 'supabase_service.dart';

class RuletaBonusResultado {
  final bool yaUsado;
  final double valor;
  final int? minutosDuracion;
  final String? venceTs;
  RuletaBonusResultado({required this.yaUsado, required this.valor, this.minutosDuracion, this.venceTs});
}

class RecompensaCompartirResultado {
  final bool yaReclamado;
  final int monedasGanadas;
  final int monedasTotal;
  RecompensaCompartirResultado({required this.yaReclamado, required this.monedasGanadas, required this.monedasTotal});
}

class GastarMonedasResultado {
  final bool exito;
  final int monedasRestantes;
  GastarMonedasResultado({required this.exito, required this.monedasRestantes});
}

class MinutoActivoResultado {
  final int monedasTotal;
  final bool huboPremio;
  final int monedasGanadas;
  final int minutosHoy;
  MinutoActivoResultado({required this.monedasTotal, required this.huboPremio, required this.monedasGanadas, required this.minutosHoy});
}

/// Wrappers finitos sobre las funciones RPC `SECURITY DEFINER` de economía
/// (todas ya probadas en producción por el prototipo HTML) — el cliente
/// nunca calcula ni escribe monedas directamente.
class EconomyService {
  EconomyService._();

  static Map<String, dynamic>? _asRow(dynamic data) {
    if (data == null) return null;
    if (data is List) return data.isNotEmpty ? data.first as Map<String, dynamic> : null;
    return data as Map<String, dynamic>;
  }

  static Future<RuletaBonusResultado?> girarRuletaBonus(String usuarioId) async {
    final data = await SupabaseService.client.schema('la_vuelta').rpc('girar_ruleta_bonus', params: {'p_usuario_id': usuarioId});
    final fila = _asRow(data);
    if (fila == null) return null;
    return RuletaBonusResultado(
      yaUsado: fila['ya_usado'] == true,
      valor: (fila['valor'] as num?)?.toDouble() ?? 1,
      minutosDuracion: (fila['minutos_duracion'] as num?)?.toInt(),
      venceTs: fila['vence_ts'] as String?,
    );
  }

  static Future<RecompensaCompartirResultado?> recompensaPorCompartir(String usuarioId) async {
    final data = await SupabaseService.client.schema('la_vuelta').rpc('recompensa_por_compartir', params: {'p_usuario_id': usuarioId});
    final fila = _asRow(data);
    if (fila == null) return null;
    return RecompensaCompartirResultado(
      yaReclamado: fila['ya_reclamado'] == true,
      monedasGanadas: (fila['monedas_ganadas'] as num?)?.toInt() ?? 0,
      monedasTotal: (fila['monedas_total'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<GastarMonedasResultado?> gastarMonedas(String usuarioId, int cantidad) async {
    final data = await SupabaseService.client.schema('la_vuelta').rpc('gastar_monedas', params: {'p_usuario_id': usuarioId, 'p_cantidad': cantidad});
    final fila = _asRow(data);
    if (fila == null) return null;
    return GastarMonedasResultado(exito: fila['exito'] == true, monedasRestantes: (fila['monedas_restantes'] as num?)?.toInt() ?? 0);
  }

  static Future<int?> agregarMonedas(String usuarioId, int cantidad) async {
    final data = await SupabaseService.client.schema('la_vuelta').rpc('agregar_monedas', params: {'p_usuario_id': usuarioId, 'p_cantidad': cantidad});
    if (data == null) return null;
    return (data as num).toInt();
  }

  static Future<MinutoActivoResultado?> registrarMinutoActivo(String usuarioId) async {
    final data = await SupabaseService.client.schema('la_vuelta').rpc('registrar_minuto_activo', params: {'p_usuario_id': usuarioId});
    final fila = _asRow(data);
    if (fila == null) return null;
    return MinutoActivoResultado(
      monedasTotal: (fila['monedas_total'] as num?)?.toInt() ?? 0,
      huboPremio: fila['hubo_premio'] == true,
      monedasGanadas: (fila['monedas_ganadas'] as num?)?.toInt() ?? 0,
      minutosHoy: (fila['minutos_hoy'] as num?)?.toInt() ?? 0,
    );
  }
}
