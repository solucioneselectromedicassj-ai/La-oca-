import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/usuario.dart';
import 'supabase_service.dart';

/// Identidad persistente por dispositivo (sección 8 de la especificación).
///
/// Sin autenticación real todavía: se genera un `usuario_id` y se guarda
/// localmente (equivalente al `localStorage` del prototipo HTML). Al volver
/// a abrir la app se reconoce al usuario automáticamente.
class SessionService {
  SessionService(this._supabase);

  static const _prefsKeyUsuarioId = 'ocaland_usuario_id';

  final SupabaseService _supabase;

  /// Devuelve el usuario guardado en este dispositivo, o `null` si es la
  /// primera vez que se abre la app (todavía no eligió un nombre).
  Future<Usuario?> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getString(_prefsKeyUsuarioId);
    if (usuarioId == null) return null;

    final usuario = await _supabase.obtenerUsuario(usuarioId);
    if (usuario == null) {
      // El id guardado ya no existe en la base (ej. se limpió la DB).
      await prefs.remove(_prefsKeyUsuarioId);
      return null;
    }
    return usuario;
  }

  /// Crea un usuario nuevo en la base y lo vincula a este dispositivo.
  Future<Usuario> crearUsuarioEnEsteDispositivo(String nombre) async {
    final usuario = await _supabase.crearUsuario(nombre);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyUsuarioId, usuario.id);
    await _supabase.inicializarPersonalizacion(usuario.id);
    final usuarioInicializado = await _supabase.obtenerUsuario(usuario.id);
    return usuarioInicializado ?? usuario;
  }

  /// Genera un identificador local sin depender del backend (uso interno /
  /// para escenarios que necesiten un id temporal antes de tener usuario).
  String generarIdLocal() => const Uuid().v4();
}
