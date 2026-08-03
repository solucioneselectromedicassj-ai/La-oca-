import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Recompensa pendiente de sincronizar (monedas/estadísticas de una
/// partida o campaña jugada offline) — se guarda localmente si no hay
/// conexión y se reintenta más adelante, sin bloquear el juego.
class PendingReward {
  final String tipo; // 'partida_jugada' | 'campana_completada' | 'desafio_resultado'
  final Map<String, dynamic> params;

  const PendingReward(this.tipo, this.params);

  Map<String, dynamic> toJson() => {'tipo': tipo, 'params': params};
  factory PendingReward.fromJson(Map<String, dynamic> j) => PendingReward(j['tipo'] as String, (j['params'] as Map).cast<String, dynamic>());
}

/// Cola de recompensas pendientes de sincronizar con Supabase. El modo
/// solo sigue funcionando aunque no haya conexión: las monedas y
/// estadísticas de esa jugada quedan encoladas acá y se intentan de nuevo
/// la próxima vez que haya red (ver [flush], llamado al volver al lobby).
class PendingRewardsService {
  PendingRewardsService._();

  static const _key = 'ocaland_recompensas_pendientes';
  static bool _flushing = false;

  static Future<List<PendingReward>> _leer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(PendingReward.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _guardar(List<PendingReward> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lista.map((r) => r.toJson()).toList()));
  }

  static Future<void> encolar(PendingReward reward) async {
    final lista = await _leer();
    lista.add(reward);
    await _guardar(lista);
  }

  /// Intenta despachar cada recompensa pendiente contra Supabase; las que
  /// tienen éxito se sacan de la cola, las que fallan (sin conexión, etc.)
  /// se quedan para el próximo intento. Nunca lanza excepciones.
  static Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final lista = await _leer();
      if (lista.isEmpty) return;
      final restantes = <PendingReward>[];
      for (final r in lista) {
        final ok = await _despachar(r);
        if (!ok) restantes.add(r);
      }
      await _guardar(restantes);
    } finally {
      _flushing = false;
    }
  }

  static Future<bool> _despachar(PendingReward r) async {
    try {
      switch (r.tipo) {
        case 'partida_jugada':
          await SupabaseService.client.schema('la_vuelta').rpc('registrar_resultado_partida', params: {
            'p_usuario_id': r.params['usuario_id'],
            'p_gano': r.params['gano'],
          });
          return true;
        case 'campana_completada':
          await SupabaseService.client.schema('la_vuelta').rpc('registrar_campana_completada', params: {
            'p_usuario_id': r.params['usuario_id'],
            'p_ms_total': r.params['ms_total'],
          });
          return true;
        case 'desafio_resultado':
          await SupabaseService.from('desafios_resultados').insert(r.params);
          return true;
        default:
          return true; // tipo desconocido: lo descartamos en vez de reintentar para siempre
      }
    } catch (_) {
      return false;
    }
  }
}
