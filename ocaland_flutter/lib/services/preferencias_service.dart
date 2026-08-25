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
}
