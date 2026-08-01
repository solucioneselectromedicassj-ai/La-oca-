import 'dart:ui';

/// Posiciones de las 30 casillas de la etapa 10 (Cima) siguiendo el
/// camino de mosaico ya dibujado en `fondo_carnaval.png`, en vez de
/// sortearlas sueltas por el canvas como el resto del bloque Tensión —
/// el usuario pidió específicamente usar ese camino ya pintado en la
/// imagen ("hay casillas ahí... podés usarlas para poner las
/// nuestras... que dé sensación de terminación").
///
/// Los puntos de control se midieron a mano sobre la imagen (con una
/// grilla superpuesta) siguiendo el centro del camino de mosaico,
/// arrancando en la entrada de la calle (abajo) y terminando junto al
/// escenario con los fuegos artificiales (arriba) — así la META cae
/// justo ahí, dando la sensación de cierre/triunfo que pidió el
/// usuario. Sigue sin haber un camino DIBUJADO por el juego (no hay
/// `_CaminoPainter`): las casillas quedan flotando sobre el que ya
/// trae la imagen.
class TableroCarnaval {
  TableroCarnaval._();

  /// Fracción del alto del tablero que ocupa `fondo_carnaval.png` en
  /// este bloque (`PaletaBloque.fondoAlturaMinima` de Cima) — hace
  /// falta para convertir los puntos, medidos en fracción de la
  /// IMAGEN, a fracción del CANVAS completo del tablero.
  static const double _fraccionAlturaFondo = 0.85;

  /// Puntos de control (fracción 0..1 del recorte de imagen realmente
  /// visible, no de la imagen original completa — `BoxFit.cover` con
  /// una caja más angosta que la imagen recorta los costados).
  static const List<Offset> _puntosControl = [
    Offset(0.202, 0.993),
    Offset(0.032, 0.887),
    Offset(0.227, 0.807),
    Offset(0.470, 0.725),
    Offset(0.544, 0.654),
    Offset(0.373, 0.582),
    Offset(0.202, 0.520),
    Offset(0.141, 0.457),
    Offset(0.227, 0.403),
    Offset(0.397, 0.368),
    Offset(0.483, 0.349),
  ];

  static List<Offset> generar(int cantidad) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];

    // Reescala los puntos de control (fracción de imagen) a fracción
    // del canvas completo del tablero.
    final controlEnCanvas = _puntosControl
        .map((p) => Offset(p.dx, p.dy * _fraccionAlturaFondo))
        .toList();

    // Interpolación lineal fina entre puntos de control + reparto por
    // longitud de arco (mismo criterio que `CaminoTablero`): no hace
    // falta una curva suave porque acá no se dibuja ningún camino, solo
    // importa que las N casillas queden bien distribuidas siguiendo la
    // forma real del mosaico.
    const muestrasPorTramo = 40;
    final finos = <Offset>[];
    for (var i = 0; i < controlEnCanvas.length - 1; i++) {
      final a = controlEnCanvas[i];
      final b = controlEnCanvas[i + 1];
      for (var j = 0; j < muestrasPorTramo; j++) {
        finos.add(Offset.lerp(a, b, j / muestrasPorTramo)!);
      }
    }
    finos.add(controlEnCanvas.last);

    final longitudAcumulada = List<double>.filled(finos.length, 0);
    for (var i = 1; i < finos.length; i++) {
      longitudAcumulada[i] = longitudAcumulada[i - 1] + (finos[i] - finos[i - 1]).distance;
    }
    final longitudTotal = longitudAcumulada.last;

    Offset puntoALongitud(double objetivo) {
      var lo = 0, hi = finos.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (longitudAcumulada[mid] < objetivo) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      if (lo == 0) return finos[0];
      final l0 = longitudAcumulada[lo - 1];
      final l1 = longitudAcumulada[lo];
      final f = l1 > l0 ? (objetivo - l0) / (l1 - l0) : 0.0;
      return Offset.lerp(finos[lo - 1], finos[lo], f)!;
    }

    return List.generate(cantidad, (i) {
      final objetivo = longitudTotal * i / (cantidad - 1);
      return puntoALongitud(objetivo);
    });
  }
}
