import '../models/amigo.dart';
import 'supabase_service.dart';

class AmigoYaExisteException implements Exception {}

class CodigoInvalidoException implements Exception {}

class AmigoEsUnoMismoException implements Exception {}

/// Lista de amigos guardados: agenda propia, asimétrica (no hace falta que
/// el otro te agregue de vuelta), buscando por el mismo "código de perfil"
/// que ya se usa para invitar (`usuarios.codigo_referido`).
class AmigosService {
  AmigosService._();

  static Future<List<Amigo>> listar(String usuarioId) async {
    final rows = await SupabaseService.from('amigos').select().eq('usuario_id', usuarioId).order('apodo');
    return (rows as List).map((r) => Amigo.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Busca un usuario por su código de perfil y lo agrega a la lista.
  static Future<Amigo> agregarPorCodigo(String usuarioId, String codigo) async {
    final encontrado = await SupabaseService.from('usuarios').select('id, nombre').eq('codigo_referido', codigo.trim().toUpperCase()).maybeSingle();
    if (encontrado == null) throw CodigoInvalidoException();
    final amigoId = encontrado['id'] as String;
    if (amigoId == usuarioId) throw AmigoEsUnoMismoException();
    try {
      final fila = await SupabaseService.from('amigos').insert({
        'usuario_id': usuarioId,
        'amigo_usuario_id': amigoId,
        'apodo': encontrado['nombre'] as String,
      }).select().single();
      return Amigo.fromJson(fila);
    } on Object catch (e) {
      if (e.toString().contains('amigos_unico')) throw AmigoYaExisteException();
      rethrow;
    }
  }

  static Future<void> eliminar(String amigoId) async {
    await SupabaseService.from('amigos').delete().eq('id', amigoId);
  }
}
