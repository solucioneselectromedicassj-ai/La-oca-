import '../models/mensaje.dart';
import 'supabase_service.dart';

/// Buzón de mensajes/avisos entre usuarios: invitaciones a desafíos
/// grupales, avisos de la mascota (el cazador), etc. A diferencia de
/// sellos/comodines (locales), esto necesita llegar de un dispositivo a
/// otro, así que vive en Supabase (tabla `mensajes`, agregada para esta
/// funcionalidad).
class MensajesService {
  MensajesService._();

  static Future<List<Mensaje>> listar(String usuarioId) async {
    final rows = await SupabaseService.from('mensajes').select().eq('destinatario_usuario_id', usuarioId).order('creado_en', ascending: false);
    return (rows as List).map((r) => Mensaje.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<int> contarNoLeidos(String usuarioId) async {
    final rows = await SupabaseService.from('mensajes').select('id').eq('destinatario_usuario_id', usuarioId).eq('leido', false);
    return (rows as List).length;
  }

  static Future<void> marcarLeido(String mensajeId) async {
    await SupabaseService.from('mensajes').update({'leido': true}).eq('id', mensajeId);
  }

  static Future<void> marcarTodosLeidos(String usuarioId) async {
    await SupabaseService.from('mensajes').update({'leido': true}).eq('destinatario_usuario_id', usuarioId).eq('leido', false);
  }

  static Future<void> eliminar(String mensajeId) async {
    await SupabaseService.from('mensajes').delete().eq('id', mensajeId);
  }

  /// Avisa al sistema (a la Oca): tipo 'cazador' es del sistema, no tiene remitente.
  static Future<void> enviarDelSistema(String destinatarioUsuarioId, String tipo, String texto, {Map<String, dynamic>? payload}) async {
    await SupabaseService.from('mensajes').insert({
      'destinatario_usuario_id': destinatarioUsuarioId,
      'tipo': tipo,
      'texto': texto,
      'payload': payload,
    });
  }

  /// Invitación de un usuario a otro (ej: a un desafío grupal).
  static Future<void> enviarInvitacion({
    required String destinatarioUsuarioId,
    required String remitenteUsuarioId,
    required String remitenteNombre,
    required String texto,
    Map<String, dynamic>? payload,
  }) async {
    await SupabaseService.from('mensajes').insert({
      'destinatario_usuario_id': destinatarioUsuarioId,
      'remitente_usuario_id': remitenteUsuarioId,
      'remitente_nombre': remitenteNombre,
      'tipo': 'invitacion_desafio',
      'texto': texto,
      'payload': payload,
    });
  }
}
