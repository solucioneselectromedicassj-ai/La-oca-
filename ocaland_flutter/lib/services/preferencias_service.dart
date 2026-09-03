import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Franja de edad y país elegidos para Cuestionados — no son parte de la
/// identidad del usuario en Supabase (esa tabla no tiene esas columnas),
/// así que se guardan localmente por dispositivo para no tener que
/// preguntarlos de nuevo cada vez que se abre la app.
class PreferenciasService {
  PreferenciasService._();

  static const _kEdad = 'pref_edad_bracket';
  static const _kPais = 'pref_pais';
  static const _kNivelJuegos = 'pref_nivel_juegos';
  static const _kSonido = 'pref_sonido_activado';
  static const _kMostrarTiempo = 'pref_mostrar_tiempo';

  static Future<String?> obtenerEdad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEdad);
  }

  static Future<String?> obtenerPais() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPais);
  }

  static Future<void> guardarEdad(String edad) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEdad, edad);
  }

  static Future<void> guardarPais(String pais) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPais, pais);
  }

  /// Nivel simple ('menor' | 'adolescente' | 'adulto') para elegir la
  /// dificultad de la Zona de juegos — a propósito más sencillo que la
  /// franja de edad de Cuestionados, pedido explícito del usuario.
  static Future<String?> obtenerNivelJuegos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNivelJuegos);
  }

  static Future<void> guardarNivelJuegos(String nivel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNivelJuegos, nivel);
  }

  /// Preferencia de sonido/música, para que el botón de silenciar del
  /// juego se mantenga apagado entre partidas y al volver a abrir la app.
  static Future<bool?> obtenerSonidoActivado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kSonido) ? prefs.getBool(_kSonido) : null;
  }

  static Future<void> guardarSonidoActivado(bool activado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSonido, activado);
  }

  /// Estado guardado de cada juego de la Zona de juegos, para poder
  /// salir y retomarlo más tarde en vez de arrancar de cero siempre
  /// (pedido explícito) — un blob JSON por juego, bajo su propia clave.
  static Future<void> guardarEstadoJuego(String juego, Map<String, dynamic> estado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('juego_estado_$juego', jsonEncode(estado));
  }

  static Future<Map<String, dynamic>?> obtenerEstadoJuego(String juego) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('juego_estado_$juego');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> borrarEstadoJuego(String juego) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('juego_estado_$juego');
  }

  /// Historial simple por juego (jugadas/victorias/mejor tiempo) — pedido
  /// explícito de mostrar un historial en los juegos que más gustan, para
  /// que se sienta el progreso entre partidas.
  static Future<void> registrarPartidaJuego(String juego, {required bool gano, int? tiempoSegundos}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'juego_stats_$juego';
    final raw = prefs.getString(key);
    Map<String, dynamic> stats = {};
    if (raw != null) {
      try {
        stats = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    stats['jugadas'] = (stats['jugadas'] as int? ?? 0) + 1;
    if (gano) stats['victorias'] = (stats['victorias'] as int? ?? 0) + 1;
    if (tiempoSegundos != null) {
      final mejor = stats['mejorTiempo'] as int?;
      if (mejor == null || tiempoSegundos < mejor) stats['mejorTiempo'] = tiempoSegundos;
    }
    await prefs.setString(key, jsonEncode(stats));
  }

  static Future<Map<String, dynamic>> obtenerEstadisticasJuego(String juego) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('juego_stats_$juego');
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Mostrar u ocultar el cronómetro en los juegos que lo tienen (Sudoku,
  /// Solitario) — preferencia compartida entre ambos, pedido explícito de
  /// poder "activar o no" el tiempo. Por defecto activado.
  static Future<bool> obtenerMostrarTiempo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMostrarTiempo) ?? true;
  }

  static Future<void> guardarMostrarTiempo(bool activado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMostrarTiempo, activado);
  }
}
