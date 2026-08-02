import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sesion_activa.dart';

/// Lista de partidas/campañas activas guardadas en el dispositivo, para
/// poder tener varias en simultáneo (ej. una campaña solo + una sala con
/// amigos) y volver a entrar a cualquiera desde "Mis partidas".
class SessionService {
  SessionService._();

  static const _key = 'ocaland_sesiones_activas';

  static Future<List<SesionActiva>> leerLista() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final lista = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return lista.map(SesionActiva.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _guardarLista(List<SesionActiva> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lista.map((s) => s.toJson()).toList()));
  }

  static Future<void> guardar(SesionActiva sesion) async {
    final lista = await leerLista();
    lista.removeWhere((s) => s.partidaId == sesion.partidaId);
    lista.add(sesion);
    await _guardarLista(lista);
  }

  static Future<void> borrar(String partidaId) async {
    final lista = await leerLista();
    lista.removeWhere((s) => s.partidaId == partidaId);
    await _guardarLista(lista);
  }
}
