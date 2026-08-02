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
  RestaurarIdentidadResult(this.usuario, this.premio);
}

/// Identidad persistente por dispositivo: equivalente a `localStorage` del
/// prototipo, usando `shared_preferences`. Sin autenticación real todavía
/// (queda documentado como pendiente para una etapa posterior).
class IdentityService {
  IdentityService._();

  static const _kUsuarioId = 'ocaland_usuario_id';

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

  /// Crea un usuario nuevo (pantalla de nombre) con el premio del día 1.
  static Future<Usuario> crearUsuario(String nombre, {String? codigoReferido}) async {
    const monedasIniciales = 10;
    final data = await SupabaseService.from('usuarios').insert({
      'nombre': nombre,
      'monedas': monedasIniciales,
      'codigo_referido': genCodeReferido(),
    }).select().single();
    final usuario = Usuario.fromJson(data);
    await _guardarUsuarioId(usuario.id);
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
  static Future<RestaurarIdentidadResult?> restaurarIdentidad() async {
    final usuarioId = await usuarioIdGuardado();
    if (usuarioId == null) return null;

    Map<String, dynamic> row;
    try {
      row = await SupabaseService.from('usuarios').select().eq('id', usuarioId).single();
    } catch (_) {
      // usuario borrado, id inválido, o sin conexión: no bloqueamos el arranque de la app
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
    return RestaurarIdentidadResult(usuario, premio);
  }
}
