import 'dart:math';

/// Motor de tablero: mismo diseño que el prototipo HTML.
/// 30 casillas (0 = salida, 29 = meta), layout de casillas especiales
/// aleatorio por partida/etapa, sincronizado entre jugadores vía
/// las columnas `layout_casillas` / `layout_puentes` de la tabla `partidas`.
class BoardEngine {
  BoardEngine._();

  static const int totalCells = 30;
  static const int meta = totalCells - 1;
  static const int cantidadTrampas = 20;

  /// Cantidad de cada tipo de trampa por partida (20 de 30 casillas).
  static const Map<String, int> reparto = {
    'oca': 6,
    'puente': 3,
    'carcel': 3,
    'calavera': 2,
    'minijuego': 6,
  };

  /// Genera un layout aleatorio nuevo: qué casillas son de qué tipo,
  /// y a dónde salta cada puente. Nunca toca la salida (0) ni la meta (29).
  static ({Map<int, String> layoutCasillas, Map<int, int> layoutPuentes}) generarLayoutAleatorio() {
    final rnd = Random();
    final disponibles = <int>[for (var i = 1; i < totalCells - 1; i++) i];
    for (var i = disponibles.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = disponibles[i];
      disponibles[i] = disponibles[j];
      disponibles[j] = tmp;
    }
    final elegidas = disponibles.take(cantidadTrampas).toList();

    final tipos = <String>[];
    reparto.forEach((tipo, cant) {
      for (var k = 0; k < cant; k++) {
        tipos.add(tipo);
      }
    });
    for (var i = tipos.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = tipos[i];
      tipos[i] = tipos[j];
      tipos[j] = tmp;
    }

    final layoutCasillas = <int, String>{};
    final layoutPuentes = <int, int>{};
    for (var k = 0; k < elegidas.length; k++) {
      final idx = elegidas[k];
      final tipo = tipos[k];
      layoutCasillas[idx] = tipo;
      if (tipo == 'puente') {
        final salto = 2 + rnd.nextInt(3); // avanza entre 2 y 4 casillas
        layoutPuentes[idx] = min(idx + salto, totalCells - 2);
      }
    }
    return (layoutCasillas: layoutCasillas, layoutPuentes: layoutPuentes);
  }

  static String? tipoCasilla(int idx, Map<int, String> layoutCasillas) {
    if (idx >= meta) return 'meta';
    return layoutCasillas[idx];
  }

  static int? destinoPuente(int idx, Map<int, int> layoutPuentes) => layoutPuentes[idx];

  /// Regla real de la oca: si el dado te pasa de la meta, rebotás hacia
  /// atrás la diferencia. Devuelve (posicionFinal, huboRebote).
  static (int, bool) resolverPosicion(int posActual, int valorDado) {
    var rawNewPos = posActual + valorDado;
    if (rawNewPos > meta) {
      rawNewPos = max(0, (2 * meta) - posActual - valorDado);
      return (rawNewPos, true);
    }
    return (rawNewPos, false);
  }

  /// Convierte un layout guardado en jsonb (claves string) a un Map indexado por int.
  static Map<int, String> parseLayoutCasillas(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  static Map<int, int> parseLayoutPuentes(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(int.parse(k), v as int));
  }
}
