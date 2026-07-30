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
    TipoCasilla.carcel: '$_base/carcel.png',
    TipoCasilla.minijuego: '$_base/minijuego.png',
  };

  /// La oca y la calavera tienen animación propia (varios frames) en vez
  /// de ícono estático + transform genérico.
  static const List<String> framesOca = [
    '$_base/oca_vuelo_1.png',
    '$_base/oca_vuelo_2.png',
    '$_base/oca_vuelo_3.png',
  ];

  static const List<String> framesCalavera = [
    '$_base/calavera_1.png',
    '$_base/calavera_2.png',
    '$_base/calavera_3.png',
  ];
}
