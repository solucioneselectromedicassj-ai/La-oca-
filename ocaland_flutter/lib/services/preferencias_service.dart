import 'package:shared_preferences/shared_preferences.dart';

/// Franja de edad y país elegidos para Cuestionados — no son parte de la
/// identidad del usuario en Supabase (esa tabla no tiene esas columnas),
/// así que se guardan localmente por dispositivo para no tener que
/// preguntarlos de nuevo cada vez que se abre la app.
class PreferenciasService {
  PreferenciasService._();

  static const _kEdad = 'pref_edad_bracket';
  static const _kPais = 'pref_pais';

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
}
