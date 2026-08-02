/// Duraciones de animación. Más lentas que el prototipo HTML a pedido
/// del usuario: quiere poder ver bien el turno del bot, el sorteo de
/// quién empieza y la tirada de dado en cada turno.
class Pacing {
  Pacing._();

  /// Cuánto "piensa" el bot antes de tirar el dado (antes: 1100ms).
  static const botThink = Duration(milliseconds: 2200);

  /// Intervalo entre cada casillero de la caminata de la ficha (antes: 220ms).
  static const walkStep = Duration(milliseconds: 320);

  /// Duración del "giro" visual del dado antes de mostrar el resultado
  /// (el prototipo no tenía esta animación, mostraba el resultado al toque).
  static const diceRoll = Duration(milliseconds: 900);

  /// Cuánto se queda visible la cara final del dado antes de volver al ícono neutro.
  static const diceResultHold = Duration(milliseconds: 1800);

  /// Cuánto se muestra el panel de sorteo de turno inicial (antes: 2500ms).
  static const sorteoDisplay = Duration(milliseconds: 4000);

  /// Espera total antes de continuar tras el sorteo (antes: 2600ms).
  static const sorteoWaitTotal = Duration(milliseconds: 4200);
}
