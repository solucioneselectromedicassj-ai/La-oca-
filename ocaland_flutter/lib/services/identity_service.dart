import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'supabase_service.dart';

class PremioDiario {
  final int monedasGanadas;
  final int nuevaRacha;
  final int diaDelCiclo;
  PremioDiario({required this.monedasGanadas, required this.nuevaRacha, required this.diaDelCiclo});
}

class RestaurarIdentidadResult {
  final Usuario usuario;
  final PremioDiario? premio;
  final bool offline;
  RestaurarIdentidadResult(this.usuario, this.premio, {this.offline = false});
}

/// Identidad persistente por dispositivo: equivalente a `localStorage` del
/// prototipo, usando `shared_preferences`. Sin autenticación real todavía
/// (queda documentado como pendiente para una etapa posterior).
class IdentityService {
  IdentityService._();

  static const _kUsuarioId = 'ocaland_usuario_id';
  static const _kUsuarioCache = 'ocaland_usuario_cache';

  static String genCodeReferido() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(5, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static Future<String?> usuarioIdGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsuarioId);
  }

  static Future<void> _guardarUsuarioId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsuarioId, id);
  }

  /// Copia local del usuario (monedas/estadísticas la última vez que hubo
  /// conexión) — para que una persona que ya tenía cuenta pueda seguir
  /// jugando el modo solo aunque abra la app sin internet.
  static Future<void> _guardarUsuarioCache(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsuarioCache, jsonEncode({
          'id': u.id,
          'nombre': u.nombre,
          'racha_dias': u.rachaDias,
          'partidas_jugadas': u.partidasJugadas,
          'partidas_ganadas': u.partidasGanadas,
          'campanas_completadas': u.campanasCompletadas,
          'mejor_tiempo_campana_ms': u.mejorTiempoCampanaMs,
          'monedas': u.monedas,
          'codigo_referido': u.codigoReferido,
          'amigos_invitados': u.amigosInvitados,
          'minutos_activos_hoy': u.minutosActivosHoy,
        }));
  }

  static Future<Usuario?> _leerUsuarioCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsuarioCache);
    if (raw == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Crea un usuario nuevo (pantalla de nombre) con el premio del día 1.
  /// Necesita conexión — no se puede dar de alta un usuario nuevo offline.
  static Future<Usuario> crearUsuario(String nombre, {String? codigoReferido}) async {
    const monedasIniciales = 10;
    final data = await SupabaseService.from('usuarios').insert({
      'nombre': nombre,
      'monedas': monedasIniciales,
      'codigo_referido': genCodeReferido(),
    }).select().single();
    final usuario = Usuario.fromJson(data);
    await _guardarUsuarioId(usuario.id);
    await _guardarUsuarioCache(usuario);
    if (codigoReferido != null && codigoReferido.trim().isNotEmpty) {
      try {
        await SupabaseService.client.schema('la_vuelta').rpc('aplicar_codigo_referido', params: {
          'p_usuario_nuevo_id': usuario.id,
          'p_codigo': codigoReferido.trim(),
        });
      } catch (_) {
        // código inválido o ya usado: no bloquea el alta del usuario
      }
    }
    return usuario;
  }

  /// Al volver a abrir la app: recupera el usuario guardado y reclama la
  /// recompensa diaria (día 1 = 10 monedas, escala +5/día hasta el día 7).
  /// Si no hay conexión pero ya había una cuenta guardada en este
  /// dispositivo, sigue andando con la última copia local conocida
  /// (`offline: true`) — solo el modo solo funciona en ese caso, y las
  /// monedas/estadísticas se ponen al día cuando vuelva la conexión.
  static Future<RestaurarIdentidadResult?> restaurarIdentidad() async {
    final usuarioId = await usuarioIdGuardado();
    if (usuarioId == null) return null;

    Map<String, dynamic> row;
    try {
      row = await SupabaseService.from('usuarios').select().eq('id', usuarioId).single();
    } catch (_) {
      final cache = await _leerUsuarioCache();
      if (cache != null) return RestaurarIdentidadResult(cache, null, offline: true);
      // sin caché local tampoco (primera vez en este dispositivo sin red): no bloqueamos, pero no hay con qué entrar
      return null;
    }
    var usuario = Usuario.fromJson(row);

    PremioDiario? premio;
    try {
      final data = await SupabaseService.client.schema('la_vuelta').rpc('reclamar_recompensa_diaria', params: {
        'p_usuario_id': usuarioId,
      });
      final fila = data is List ? (data.isNotEmpty ? data.first as Map<String, dynamic> : null) : data as Map<String, dynamic>?;
      if (fila != null) {
        usuario = usuario.copyWith(rachaDias: fila['nueva_racha'] as int?, monedas: fila['monedas_total'] as int?);
        if (fila['ya_reclamado'] != true) {
          premio = PremioDiario(
            monedasGanadas: (fila['monedas_ganadas'] as num).toInt(),
            nuevaRacha: (fila['nueva_racha'] as num).toInt(),
            diaDelCiclo: (fila['dia_del_ciclo'] as num).toInt(),
          );
        }
      }
    } catch (_) {
      // si falla la RPC seguimos con los datos que ya teníamos del usuario
    }
    await _guardarUsuarioCache(usuario);
    return RestaurarIdentidadResult(usuario, premio);
  }

  /// Actualiza la copia local del usuario (para que el próximo arranque
  /// offline ya refleje las monedas/estadísticas más recientes).
  static Future<void> actualizarCache(Usuario u) => _guardarUsuarioCache(u);
}
