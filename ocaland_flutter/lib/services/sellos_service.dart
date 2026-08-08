import 'package:shared_preferences/shared_preferences.dart';

/// "Sellos": coleccionable nuevo (no existía en el prototipo HTML) que se
/// gana al caer en una casilla trampa (cárcel/calavera). Funciona como una
/// moneda alternativa: se puede canjear por monedas normales, conseguir
/// viendo un video, o gastar directamente para pedir una pista en
/// Cuestionados o para intentar de nuevo antes de la penitencia.
///
/// Se guarda localmente (por dispositivo, igual que la identidad del
/// jugador) en vez de en Supabase — así no hace falta tocar el esquema de
/// la base de datos en producción para esta funcionalidad.
class SellosService {
  SellosService._();

  static const _key = 'sellos_count';

  static Future<int> obtener() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  /// [cantidad] puede ser negativa para gastar sellos. Nunca queda debajo de 0.
  static Future<int> agregar(int cantidad) async {
    final prefs = await SharedPreferences.getInstance();
    final actual = ((prefs.getInt(_key) ?? 0) + cantidad).clamp(0, 1 << 30);
    await prefs.setInt(_key, actual);
    return actual;
  }
}
