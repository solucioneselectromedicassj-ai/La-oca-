/// Arte real del dado: 6 caras estáticas + frames de "sensación de
/// movimiento" para animar la tirada (en vez de solo mostrar el número).
class DadoIconos {
  DadoIconos._();

  static const String _base = 'assets/dado';

  /// Índice 0 = cara con el 1, ..., índice 5 = cara con el 6.
  static const List<String> caras = [
    '$_base/estatico_1.png',
    '$_base/estatico_2.png',
    '$_base/estatico_3.png',
    '$_base/estatico_4.png',
    '$_base/estatico_5.png',
    '$_base/estatico_6.png',
  ];

  /// El usuario reemplazó las 6 caras por un set más nítido; no llegó
  /// un set nuevo de frames "con desenfoque de movimiento" a juego, así
  /// que el ciclo rápido de tirada usa las mismas caras limpias (sigue
  /// dando sensación de giro, sin mezclar dos estilos de arte distintos).
  static const List<String> movimiento = caras;
}
