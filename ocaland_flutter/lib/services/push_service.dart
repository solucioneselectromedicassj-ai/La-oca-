import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../app_config.dart';
import 'supabase_service.dart';

/// Notificaciones push (Android/iOS, vía OneSignal). El paquete oficial de
/// Flutter no soporta Web, así que en la versión de navegador (GitHub
/// Pages) esto queda desactivado sin hacer nada — el resto del juego no
/// depende de esto para funcionar.
///
/// El envío real de los push pasa por una Edge Function de Supabase
/// (`enviar_push`), que usa la REST API Key de OneSignal — esa clave es
/// secreta y nunca vive acá ni en ningún otro lugar del cliente.
class PushService {
  PushService._();

  static bool get _configurado => AppConfig.oneSignalAppId.isNotEmpty;

  /// Inicializa el SDK, pide permiso de notificaciones, y guarda el
  /// player_id del dispositivo en `usuarios.onesignal_player_id` para que
  /// la Edge Function sepa a quién mandarle el push.
  static Future<void> iniciar({required String usuarioId}) async {
    if (kIsWeb || !_configurado) return;
    try {
      OneSignal.initialize(AppConfig.oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
      await _guardarPlayerId(usuarioId);
      OneSignal.User.pushSubscription.addObserver((state) {
        _guardarPlayerId(usuarioId);
      });
    } catch (_) {
      // Sin OneSignal disponible (permiso denegado, SDK no inicializado,
      // etc.): el juego sigue igual, solo sin push.
    }
  }

  static Future<void> _guardarPlayerId(String usuarioId) async {
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId == null) return;
    try {
      await SupabaseService.from('usuarios').update({'onesignal_player_id': playerId}).eq('id', usuarioId);
    } catch (_) {}
  }
}
