import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Inventario de comodines (ventaja3, doble_tiempo, tirada_extra,
/// inmunidad) ganados en la ruleta de premio de etapa del modo solo.
///
/// Antes, un comodín ganado se guardaba en un solo "cupo" en el jugador de
/// la partida y se consumía automáticamente en la etapa siguiente — si
/// ganabas otro antes de usarlo, se perdía el anterior. Ahora se acumulan
/// acá (localmente, por dispositivo, igual que los sellos) y se pueden ver
/// en el perfil y elegir cuál usar al empezar cada etapa.
///
/// Solo aplica al modo solo: en multijugador el comodín pertenece al
/// jugador que ganó la ronda y tiene que verse igual desde cualquier
/// dispositivo, así que ahí se sigue sincronizando por Supabase como
/// antes (un cambio a un inventario compartido por red queda fuera de
/// alcance de esto).
class ComodinesService {
  ComodinesService._();

  static const _key = 'comodines_inventario';

  static Future<Map<String, int>> obtener() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// [cantidad] puede ser negativa para gastar un comodín del inventario.
  static Future<Map<String, int>> agregar(String tipo, int cantidad) async {
    final prefs = await SharedPreferences.getInstance();
    final actual = await obtener();
    final nuevo = (actual[tipo] ?? 0) + cantidad;
    if (nuevo <= 0) {
      actual.remove(tipo);
    } else {
      actual[tipo] = nuevo;
    }
    await prefs.setString(_key, jsonEncode(actual));
    return actual;
  }
}
