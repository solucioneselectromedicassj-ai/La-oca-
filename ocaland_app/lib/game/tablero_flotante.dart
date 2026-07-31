import 'dart:math';
import 'dart:ui';

/// Posiciones "sueltas" (sin sendero) para los bloques Tensión y Cima
/// (sección 1 de la spec visual): el usuario pidió casillas flotando,
/// que cambian de lugar en cada etapa, sin un camino de tierra
/// dibujado conectándolas — a diferencia de [CaminoTablero], que arma
/// una curva continua, acá cada punto se sortea independiente con una
/// separación mínima real (en píxeles) para que no se superpongan.
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

    for (var i = 1; i < cantidad - 1; i++) {
      final objetivoY = 0.22 + 0.62 * (i / (cantidad - 1));
      Offset? elegido;
      for (var intento = 0; intento < maxIntentosPorPunto; intento++) {
        final candidato = Offset(
          0.08 + rng.nextDouble() * 0.84,
          (objetivoY + (rng.nextDouble() - 0.5) * 0.09).clamp(0.02, 0.98),
        );
        final lejos = puntos.every((p) => _distanciaPseudo(p, candidato) >= separacionMinima);
        if (lejos) {
          elegido = candidato;
          break;
        }
      }
      // Si no encontró lugar libre en el máximo de intentos (tablero
      // muy apretado), usa el último candidato igual antes que romper
      // el generador — mejor una casilla un poco cerca que faltante.
      puntos.add(elegido ?? Offset(0.08 + rng.nextDouble() * 0.84, objetivoY));
    }

    puntos.add(const Offset(0.5, 0.90)); // META fija abajo
    return puntos;
  }

  static double _distanciaPseudo(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = (a.dy - b.dy) / _aspectRatioContenido;
    return sqrt(dx * dx + dy * dy);
  }
}
