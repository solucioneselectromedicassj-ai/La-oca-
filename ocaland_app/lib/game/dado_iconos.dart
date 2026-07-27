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

  static const List<String> movimiento = [
    '$_base/movimiento_1.png',
    '$_base/movimiento_2.png',
    '$_base/movimiento_3.png',
    '$_base/movimiento_4.png',
    '$_base/movimiento_5.png',
    '$_base/movimiento_6.png',
  ];
}
