/// Explicación corta de qué hace cada tipo de casilla especial, mostrada
/// como aviso contextual justo cuando el jugador cae ahí (en vez de una
/// leyenda fija siempre visible debajo del tablero).
const Map<String, String> cellDescriptions = {
  'oca': 'Acertá la pregunta y tirás de nuevo. Si fallás, te quedás en esta casilla.',
  'carcel': 'Acertá y seguís libre. Si fallás, perdés tu próximo turno.',
  'calavera': 'Pregunta difícil: si acertás no pasa nada, si fallás volvés a la salida.',
  'minijuego': 'Superalo y avanzás 2 casillas extra. Si fallás, no pasa nada.',
  'puente': 'Te lleva directo a otra casilla, sin pregunta.',
  'sello': '¡Casilla de suerte! Ganás un sello para safar en Cuestionados.',
};
