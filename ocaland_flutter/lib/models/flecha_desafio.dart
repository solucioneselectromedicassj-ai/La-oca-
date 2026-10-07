import 'dart:math';

/// Desafío rápido de "sacar la flecha" — pedido explícito del usuario
/// para reemplazar a Cuestionados en los juegos de espera (medidor y
/// chequeo de turno), para que no sea siempre lo mismo. Mostrá una
/// flecha apuntando a una dirección al azar; el jugador toca el botón
/// de esa misma dirección antes de que se acabe el tiempo.
enum Direccion { arriba, abajo, izquierda, derecha }

const _emojiPorDireccion = {
  Direccion.arriba: '⬆️',
  Direccion.abajo: '⬇️',
  Direccion.izquierda: '⬅️',
  Direccion.derecha: '➡️',
};

class FlechaDesafio {
  final Direccion direccion;
  const FlechaDesafio(this.direccion);

  String get emoji => _emojiPorDireccion[direccion]!;

  factory FlechaDesafio.aleatoria([Random? random]) {
    final rnd = random ?? Random();
    return FlechaDesafio(Direccion.values[rnd.nextInt(Direccion.values.length)]);
  }
}
