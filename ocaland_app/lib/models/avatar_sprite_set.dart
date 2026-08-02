/// Set de frames de animación de un avatar (spec visual v2, sección 3):
/// ciclo de caminata, festejo al ganar y reacción al fallar Cuestionados.
class AvatarSpriteSet {
  const AvatarSpriteSet({
    required this.caminata,
    required this.festejo,
    required this.reaccion,
  });

  /// Al menos 4 poses para animar el paso por el tablero.
  final List<String> caminata;

  /// 2-3 cuadros: agachado, salto con brazos arriba, aterrizaje.
  final List<String> festejo;

  /// 1-2 cuadros de sorpresa/susto leve.
  final List<String> reaccion;
}
