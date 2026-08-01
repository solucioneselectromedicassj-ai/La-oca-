import 'dart:math';
import 'dart:ui';

/// Forma del sendero de una etapa (sección 1 de la spec visual): las
/// primeras 6 etapas (con sendero dibujado) rotan entre estas 3 formas,
/// una por etapa, para que el tablero no se sienta siempre igual.
enum FormaCamino {
  serpiente,
  interrogacion,
  espiral;

  /// Rota serpiente → interrogación → espiral → serpiente... por etapa
  /// (1-indexada), pedido explícitamente por el usuario.
  static FormaCamino deEtapa(int etapa) {
    const ciclo = [FormaCamino.serpiente, FormaCamino.interrogacion, FormaCamino.espiral];
    return ciclo[(etapa - 1) % ciclo.length];
  }
}

/// Genera las posiciones (normalizadas 0..1) de las 30 casillas sobre
/// una curva paramétrica — no una grilla recta — para que cualquier
/// cantidad de casillas quede prolija automáticamente. La forma exacta
/// (amplitud, fase, hacia qué lado arranca) varía cada vez que se
/// genera dentro de la [FormaCamino] pedida, igual que el layout de
/// trampas.
class CaminoTablero {
  CaminoTablero._();

  static List<Offset> generar(
    int cantidad, {
    Random? random,
    FormaCamino forma = FormaCamino.serpiente,
  }) {
    if (cantidad <= 1) return [const Offset(0.5, 0.5)];
    final rng = random ?? Random();

    final Offset Function(double t) puntoCrudo;
    switch (forma) {
      case FormaCamino.serpiente:
        puntoCrudo = _generarSerpiente(rng);
      case FormaCamino.interrogacion:
        puntoCrudo = _generarInterrogacion(rng);
      case FormaCamino.espiral:
        puntoCrudo = _generarEspiral(rng);
    }

    // Todas las formas se acotan al mismo rango: deja aire para el
    // cartel de INICIO (arriba) y el de META (abajo), y nunca se van
    // tan al costado que las casillas queden pegadas al borde.
    Offset punto(double t) {
      final p = puntoCrudo(t);
      return Offset(p.dx.clamp(0.05, 0.95), p.dy.clamp(0.02, 0.98));
    }

    // Repartir los puntos por LONGITUD DE ARCO, no por `t` parejo: con
    // `t` parejo las casillas quedaban amontonadas en los picos de la
    // curva (ahí `dx/dt≈0`, así que el recorrido real entre dos `t`
    // consecutivos es más corto) y separadas en los tramos rectos. Se
    // muestrea la curva fino y se eligen los N puntos que reparten la
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

  /// Zigzag tipo mapa de Candy Crush (la forma original): muchas vueltas
  /// apretadas para acumular longitud de recorrido en un tablero bajo.
  static Offset Function(double) _generarSerpiente(Random rng) {
    final amplitud = 0.34 + rng.nextDouble() * 0.09; // 0.34 - 0.43
    final frecuencia = 6.0 + rng.nextDouble() * 2.5; // 6.0 - 8.5 curvas
    final direccion = rng.nextBool() ? 1 : -1;
    final faseInicial = rng.nextDouble() * 0.3;
    return (double t) {
      final x = 0.5 + direccion * amplitud * sin((t + faseInicial) * frecuencia * pi);
      final y = 0.14 + 0.76 * t;
      return Offset(x, y);
    };
  }

  /// Forma de signo de pregunta: un arco/gancho arriba (el "rulo" de la
  /// ?) seguido de un tallo largo y ondulado hacia abajo (la parte
  /// recta de la ?). La primera versión barría ~260° (casi una vuelta
  /// completa) y con el ancho real del camino pintado se veía
  /// cruzada/enredada sobre sí misma — el usuario lo marcó
  /// explícitamente ("es un rulo y el sendero se entrecruza"). Este
  /// arco barre solo 180° (medio círculo, de un lado al otro pasando
  /// por arriba), así que geométricamente no puede volver a pasar por
  /// donde ya pasó.
  static Offset Function(double) _generarInterrogacion(Random rng) {
    final direccion = rng.nextBool() ? 1 : -1;
    final faseX = (rng.nextDouble() - 0.5) * 0.04;
    const centroX = 0.5;
    const centroYGancho = 0.19;
    const radioXGancho = 0.23;
    const radioYGancho = 0.11;
    const anguloInicio = pi; // apunta a la izquierda
    const anguloFin = 2 * pi; // medio giro después, apunta a la derecha
    const finGancho = 0.30;

    final anguloFinX = centroX + radioXGancho * cos(anguloFin) * direccion + faseX;
    final anguloFinY = centroYGancho + radioYGancho * sin(anguloFin);

    return (double t) {
      if (t <= finGancho) {
        final tt = t / finGancho;
        final angulo = anguloInicio + tt * (anguloFin - anguloInicio);
        final x = centroX + radioXGancho * cos(angulo) * direccion + faseX;
        final y = centroYGancho + radioYGancho * sin(angulo);
        return Offset(x, y);
      }
      // El tallo arranca donde termina el arco y deriva de vuelta hacia
      // el centro mientras baja, con una ondulación suave — nunca
      // vuelve a subir a la altura del arco, así que tampoco se cruza
      // con él.
      final tt = (t - finGancho) / (1 - finGancho);
      final x = anguloFinX + (centroX - anguloFinX) * tt + sin(tt * pi * 1.3) * 0.08 * direccion;
      final y = anguloFinY + tt * (0.92 - anguloFinY);
      return Offset(x, y);
    };
  }

  /// Espiral que además baja: como un resorte visto de costado, el
  /// radio crece de adentro hacia afuera a medida que avanza el
  /// recorrido en vez de mantenerse constante como la serpiente. Con
  /// más vueltas y arrancando casi en un punto (en vez de ya bastante
  /// abierta) se nota más el "enrulado" y no se confunde con la
  /// serpiente de amplitud pareja.
  static Offset Function(double) _generarEspiral(Random rng) {
    final direccion = rng.nextBool() ? 1 : -1;
    final vueltas = 3.4 + rng.nextDouble() * 0.7; // 3.4 - 4.1 vueltas
    final faseInicial = rng.nextDouble() * 0.3;
    return (double t) {
      final angulo = (t + faseInicial) * vueltas * 2 * pi;
      final radio = 0.03 + 0.42 * t;
      final x = 0.5 + direccion * radio * cos(angulo);
      final y = 0.12 + 0.80 * t;
      return Offset(x, y);
    };
  }
}
