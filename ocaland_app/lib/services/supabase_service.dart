import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/usuario.dart';

/// Wrapper fino sobre el cliente de Supabase, fijado al schema `la_vuelta`.
///
/// Todas las escrituras sensibles (monedas, estadísticas) pasan por
/// funciones RPC `SECURITY DEFINER` — nunca por UPDATE directo a `usuarios`,
/// igual que en el prototipo HTML (ver sección 11 de la especificación).
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  SupabaseClient get _client => Supabase.instance.client;

  SupabaseQuerySchema get _db => _client.schema(SupabaseConfig.schema);

  // ---------------------------------------------------------------------
  // Usuarios
  // ---------------------------------------------------------------------

  Future<Usuario?> obtenerUsuario(String usuarioId) async {
    final row = await _db
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .maybeSingle();
    if (row == null) return null;
    return Usuario.fromMap(row);
  }

  Future<Usuario> crearUsuario(String nombre) async {
    final row = await _db
        .from('usuarios')
        .insert({'nombre': nombre})
        .select()
        .single();
    return Usuario.fromMap(row);
  }

  // ---------------------------------------------------------------------
  // RPC (todas SECURITY DEFINER del lado del servidor)
  // ---------------------------------------------------------------------

  Future<void> registrarResultadoPartida({
    required String usuarioId,
    required bool gano,
  }) async {
    await _client.rpc(
      'registrar_resultado_partida',
      params: {'usuario_id': usuarioId, 'gano': gano},
    );
  }

  Future<void> registrarCampanaCompletada({
    required String usuarioId,
    required int msTotal,
  }) async {
    await _client.rpc(
      'registrar_campana_completada',
      params: {'usuario_id': usuarioId, 'ms_total': msTotal},
    );
  }

  Future<Map<String, dynamic>?> reclamarRecompensaDiaria(
    String usuarioId,
  ) async {
    final result = await _client.rpc(
      'reclamar_recompensa_diaria',
      params: {'usuario_id': usuarioId},
    );
    return result as Map<String, dynamic>?;
  }

  Future<void> actualizarOnesignalId({
    required String usuarioId,
    required String onesignalId,
  }) async {
    await _client.rpc(
      'actualizar_onesignal_id',
      params: {'usuario_id': usuarioId, 'onesignal_id': onesignalId},
    );
  }

  Future<void> gastarMonedas({
    required String usuarioId,
    required int cantidad,
  }) async {
    await _client.rpc(
      'gastar_monedas',
      params: {'usuario_id': usuarioId, 'cantidad': cantidad},
    );
  }

  Future<void> agregarMonedas({
    required String usuarioId,
    required int cantidad,
  }) async {
    await _client.rpc(
      'agregar_monedas',
      params: {'usuario_id': usuarioId, 'cantidad': cantidad},
    );
  }

  Future<Map<String, dynamic>?> girarRuletaBonus(String usuarioId) async {
    final result = await _client.rpc(
      'girar_ruleta_bonus',
      params: {'usuario_id': usuarioId},
    );
    return result as Map<String, dynamic>?;
  }

  Future<void> recompensaPorCompartir(String usuarioId) async {
    await _client.rpc(
      'recompensa_por_compartir',
      params: {'usuario_id': usuarioId},
    );
  }

  Future<void> registrarMinutoActivo(String usuarioId) async {
    await _client.rpc(
      'registrar_minuto_activo',
      params: {'usuario_id': usuarioId},
    );
  }

  Future<void> aplicarCodigoReferido({
    required String usuarioNuevoId,
    required String codigo,
  }) async {
    await _client.rpc(
      'aplicar_codigo_referido',
      params: {'usuario_nuevo_id': usuarioNuevoId, 'codigo': codigo},
    );
  }
}
