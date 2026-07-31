import '../../game/casilla.dart';

/// Arte real de las casillas de trampa (spec visual v2, sección 4),
/// reemplazando los emojis de `TipoCasillaEmoji`. Lo que no está acá
/// (normal, meta) sigue usando el emoji como antes.
class CasillaIconos {
  CasillaIconos._();

  static const String _base = 'assets/casillas';

  static const Map<TipoCasilla, String> iconoEstatico = {
    // El archivo sigue llamándose puente.png (arte sin cambios); lo que
    // se renombró fue el tipo de casilla, de "puente" a "trampolín".
    TipoCasilla.trampolin: '$_base/puente.png',
    // Reemplazadas por el arte que mandó el usuario (torre de piedra
    // con celda, no la gema brillante genérica de antes).
    TipoCasilla.carcel: '$_base/carcel.png',
    // La estrella con cara reemplaza el ícono de gema genérico.
    TipoCasilla.minijuego: '$_base/minijuego.png',
    // La calavera nueva es una sola imagen (sin frames de mandíbula
    // animada como la anterior), reemplazada por el arte "amigable"
    // que mandó el usuario.
    TipoCasilla.calavera: '$_base/calavera.png',
  };

  /// La oca tiene animación propia (varios frames) en vez de ícono
  /// estático + transform genérico.
  static const List<String> framesOca = [
    '$_base/oca_vuelo_1.png',
    '$_base/oca_vuelo_2.png',
    '$_base/oca_vuelo_3.png',
  ];
}
