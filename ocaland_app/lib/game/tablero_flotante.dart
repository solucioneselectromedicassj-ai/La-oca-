import 'dart:math';
import 'dart:ui';

/// Posiciones "sueltas" (sin sendero) para los bloques Tensión y Cima
/// (sección 1 de la spec visual): el usuario pidió casillas flotando,
/// que cambian de lugar en cada etapa, sin un camino de tierra
/// dibujado conectándolas.
///
/// No son del todo independientes entre sí: cada punto camina un paso
/// acotado desde el anterior (en vez de sortear X totalmente al azar)
/// para que la sucesión 1→2→3... se sienta consecutiva, como si
/// seguyera un sendero invisible, aunque no haya ninguna línea
/// dibujada — el usuario lo pidió explícitamente ("casillas sueltas
/// pero con un sentido de sendero... que sean consecutivas").
class TableroFlotante {
  TableroFlotante._();

  /// Misma proporción ancho/alto de contenido que usa el tablero
  /// (`TableroWidget._aspectRatioContenido`): hace falta para medir la
  /// separación mínima en píxeles reales y no en coordenadas
  /// fraccionales (el canvas es mucho más alto que ancho, así que 0.05
  /// de Y es mucho más lejos en píxeles que 0.05 de X).
  static const double _aspectRatioContenido = 0.62;

  static List<Offset> generar(int cantidad, {Random? random}) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];
    final rng = random ?? Random();

    // Mismo margen arriba/abajo que `CaminoTablero` (0.14 - 0.90): el
    // cartel de INICIO/META necesita ese aire o le queda la punta
    // cortada fuera del área scrolleable.
    final puntos = <Offset>[const Offset(0.5, 0.14)]; // INICIO fijo arriba
    const separacionMinima = 0.17;
    const maxIntentosPorPunto = 400;
    const pasoMaximoX = 0.30;

    for (var i = 1; i < cantidad - 1; i++) {
      final objetivoY = 0.22 + 0.62 * (i / (cantidad - 1));
      final xAnterior = puntos.last.dx;
      Offset? elegido;
      for (var intento = 0; intento < maxIntentosPorPunto; intento++) {
        final candidato = Offset(
          (xAnterior + (rng.nextDouble() - 0.5) * 2 * pasoMaximoX).clamp(0.08, 0.92),
          (objetivoY + (rng.nextDouble() - 0.5) * 0.09).clamp(0.02, 0.98),
        );
        final lejos = puntos.every((p) => _distanciaPseudo(p, candidato) >= separacionMinima);
        if (lejos) {
          elegido = candidato;
          break;
        }
      }
      // Si no encontró lugar que cumpla la separación mínima completa
      // (tablero muy apretado), se queda con el mejor candidato visto
      // — el de mayor distancia mínima a las casillas ya puestas — en
      // vez de una posición ciega sin ningún chequeo.
      elegido ??= _mejorCandidato(puntos, xAnterior, objetivoY, rng);
      puntos.add(elegido);
    }

    puntos.add(const Offset(0.5, 0.90)); // META fija abajo
    return puntos;
  }

  static Offset _mejorCandidato(
    List<Offset> puntos,
    double xAnterior,
    double objetivoY,
    Random rng,
  ) {
    var mejor = Offset(0.08 + rng.nextDouble() * 0.84, objetivoY);
    var mejorDistancia = -1.0;
    for (var i = 0; i < 60; i++) {
      final candidato = Offset(
        (xAnterior + (rng.nextDouble() - 0.5) * 1.6).clamp(0.08, 0.92),
        (objetivoY + (rng.nextDouble() - 0.5) * 0.09).clamp(0.02, 0.98),
      );
      final distanciaMinima =
          puntos.map((p) => _distanciaPseudo(p, candidato)).reduce(min);
      if (distanciaMinima > mejorDistancia) {
        mejorDistancia = distanciaMinima;
        mejor = candidato;
      }
    }
    return mejor;
  }

  static double _distanciaPseudo(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = (a.dy - b.dy) / _aspectRatioContenido;
    return sqrt(dx * dx + dy * dy);
  }
}
