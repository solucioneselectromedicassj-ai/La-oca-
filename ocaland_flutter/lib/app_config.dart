/// Datos de la app que se repiten en varios lugares (por ahora, el link
/// para compartir). Cuando esto pase a tener un dominio propio o salga en
/// Google Play, alcanza con actualizar acá.
class AppConfig {
  AppConfig._();

  static const String appUrl = 'https://solucioneselectromedicassj-ai.github.io/La-oca-/';

  /// App ID de OneSignal (público, no es secreto). Vacío = notificaciones
  /// push desactivadas — `PushService` no hace nada hasta que se complete.
  static const String oneSignalAppId = 'f92eac63-daaf-43e6-a9b2-ef2977fbc853';
}
