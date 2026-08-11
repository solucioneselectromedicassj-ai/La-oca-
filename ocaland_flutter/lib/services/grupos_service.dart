import '../models/grupo.dart';
import 'supabase_service.dart';

/// Grupos de amigos consolidados, para invitar a varios de una sola vez a
/// un desafío grupal en vez de tener que elegirlos uno por uno cada vez.
class GruposService {
  GruposService._();

  static Future<List<Grupo>> listar(String usuarioId) async {
    final rows = await SupabaseService.from('grupos').select().eq('usuario_id', usuarioId).order('nombre');
    return (rows as List).map((r) => Grupo.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<Grupo> crear(String usuarioId, String nombre) async {
    final fila = await SupabaseService.from('grupos').insert({'usuario_id': usuarioId, 'nombre': nombre}).select().single();
    return Grupo.fromJson(fila);
  }

  static Future<void> eliminar(String grupoId) async {
    await SupabaseService.from('grupos').delete().eq('id', grupoId);
  }

  static Future<List<GrupoMiembro>> miembros(String grupoId) async {
    final rows = await SupabaseService.from('grupo_miembros').select().eq('grupo_id', grupoId).order('apodo');
    return (rows as List).map((r) => GrupoMiembro.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<void> agregarMiembro(String grupoId, String amigoUsuarioId, String apodo) async {
    await SupabaseService.from('grupo_miembros').insert({'grupo_id': grupoId, 'amigo_usuario_id': amigoUsuarioId, 'apodo': apodo});
  }

  static Future<void> quitarMiembro(String miembroId) async {
    await SupabaseService.from('grupo_miembros').delete().eq('id', miembroId);
  }
}
