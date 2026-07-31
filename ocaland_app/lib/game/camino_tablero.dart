import 'dart:math';
import 'dart:ui';

/// Genera las posiciones (normalizadas 0..1) de las 30 casillas en un
/// camino serpenteante tipo "mapa de Candy Crush", en vez de una grilla
/// recta. Es una curva paramétrica (no calca ningún mapa puntual) para
/// que cualquier cantidad de casillas quede prolija automáticamente.
///
/// La forma exacta (amplitud, cantidad de curvas, hacia qué lado arranca)
/// varía cada vez que se genera, para que el camino no se vea siempre
/// igual entre partidas/etapas — igual que el layout de trampas.
class CaminoTablero {
  CaminoTablero._();

  static List<Offset> generar(int cantidad, {Random? random}) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];
    final rng = random ?? Random();

    final amplitud = 0.34 + rng.nextDouble() * 0.09; // 0.34 - 0.43
    final frecuencia = 6.0 + rng.nextDouble() * 2.5; // 6.0 - 8.5 curvas: muchas vueltas apretadas
    // (tipo mapa de nivel), para acumular suficiente longitud de
    // camino en un tablero bajo y que quepa en una pantalla de
    // celular sin necesitar tanto scroll.
    final direccion = rng.nextBool() ? 1 : -1;
    final faseInicial = rng.nextDouble() * 0.3;

    Offset punto(double t) {
      final x = 0.5 + direccion * amplitud * sin((t + faseInicial) * frecuencia * pi);
      // Arranca un poco más abajo (0.11 en vez de 0.06) para dejarle
      // aire al cartel de INICIO y al cielo/sol/nubes sin que se pisen.
      final y = 0.11 + 0.85 * t;
      return Offset(x, y);
    }

    // Repartir los puntos por LONGITUD DE ARCO, no por `t` parejo: con
    // `t` parejo las casillas quedaban amontonadas en los picos de la
    // curva (ahí `dx/dt≈0`, así que el recorrido real entre dos `t`
    // consecutivos es más corto) y separadas en los tramos rectos. Se
    // muestrea la curva fino y se eligen los 30 puntos que reparten la
    // longitud total en partes iguales.
    const muestras = 400;
    final finos = List.generate(muestras + 1, (i) => punto(i / muestras));
    final longitudAcumulada = List<double>.filled(muestras + 1, 0);
    for (var i = 1; i <= muestras; i++) {
      longitudAcumulada[i] =
          longitudAcumulada[i - 1] + (finos[i] - finos[i - 1]).distance;
    }
    final longitudTotal = longitudAcumulada.last;

    Offset puntoALongitud(double objetivo) {
      var lo = 0, hi = muestras;
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
