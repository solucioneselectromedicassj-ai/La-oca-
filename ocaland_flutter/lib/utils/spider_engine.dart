import 'dart:math';

/// Motor puro del Spider (sin nada de Flutter) — separado de la pantalla
/// para poder testearlo fácil, igual que `sudoku_generator.dart`.
enum Palo { picas, corazones, diamantes, treboles }

const _simboloPorPalo = {
  Palo.picas: '♠',
  Palo.corazones: '♥',
  Palo.diamantes: '♦',
  Palo.treboles: '♣',
};

const _palosRojos = {Palo.corazones, Palo.diamantes};

class Carta {
  final int rango; // 1 (As) .. 13 (K)
  final Palo palo;
  bool bocaArriba;
  Carta(this.rango, this.palo, {this.bocaArriba = false});

  bool get esRoja => _palosRojos.contains(palo);
  String get simboloPalo => _simboloPorPalo[palo]!;
  String get textoRango => switch (rango) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rango',
      };

  Map<String, dynamic> aJson() => {'r': rango, 'p': palo.index, 'b': bocaArriba};
  static Carta desdeJson(Map<String, dynamic> j) => Carta(j['r'] as int, Palo.values[j['p'] as int], bocaArriba: j['b'] as bool);
}

const columnasSpider = 10;
const secuenciasParaGanar = 8;

/// Spider clásico de 2 mazos (104 cartas siempre) — la dificultad la da
/// la cantidad de PALOS distintos en juego (1, 2 o 4), no la cantidad de
/// mazos, que es la variante más común del juego.
class SpiderGame {
  final int nPalos; // 1 | 2 | 4
  final List<List<Carta>> columnas;
  final List<Carta> stock;
  int secuenciasCompletas;

  SpiderGame({required this.nPalos, required this.columnas, required this.stock, this.secuenciasCompletas = 0});

  factory SpiderGame.nuevo(int nPalos, {Random? random}) {
    final mazo = _crearMazo(nPalos, random ?? Random());
    final columnas = List.generate(columnasSpider, (_) => <Carta>[]);
    var idx = 0;
    for (var c = 0; c < columnasSpider; c++) {
      final cantidad = c < 4 ? 6 : 5;
      for (var i = 0; i < cantidad; i++) {
        columnas[c].add(mazo[idx++]);
      }
      columnas[c].last.bocaArriba = true;
    }
    final stock = mazo.sublist(idx);
    return SpiderGame(nPalos: nPalos, columnas: columnas, stock: stock);
  }

  static List<Carta> _crearMazo(int nPalos, Random rnd) {
    final palos = switch (nPalos) {
      1 => [Palo.picas],
      2 => [Palo.picas, Palo.corazones],
      _ => Palo.values,
    };
    final copiasPorPalo = 8 ~/ palos.length;
    final mazo = <Carta>[];
    for (final palo in palos) {
      for (var copia = 0; copia < copiasPorPalo; copia++) {
        for (var rango = 1; rango <= 13; rango++) {
          mazo.add(Carta(rango, palo));
        }
      }
    }
    mazo.shuffle(rnd);
    return mazo;
  }

  bool get gano => secuenciasCompletas >= secuenciasParaGanar;

  /// Índice donde empieza la secuencia movible (misma pinta, descendente,
  /// boca arriba) que termina al final de la columna. Null si está vacía.
  int? inicioSecuenciaMovible(int columna) {
    final col = columnas[columna];
    if (col.isEmpty) return null;
    var inicio = col.length - 1;
    while (inicio > 0) {
      final actual = col[inicio];
      final anterior = col[inicio - 1];
      if (!anterior.bocaArriba) break;
      if (anterior.palo != actual.palo || anterior.rango != actual.rango + 1) break;
      inicio--;
    }
    return inicio;
  }

  /// El grupo de cartas que se seleccionaría si tocás (columna, indice),
  /// o null si esa carta no es parte de la secuencia movible final.
  List<Carta>? grupoSeleccionable(int columna, int indice) {
    final col = columnas[columna];
    if (indice < 0 || indice >= col.length || !col[indice].bocaArriba) return null;
    final inicio = inicioSecuenciaMovible(columna);
    if (inicio == null || indice < inicio) return null;
    return col.sublist(indice);
  }

  bool puedeSoltarEn(int columnaDestino, List<Carta> grupo) {
    final destino = columnas[columnaDestino];
    if (destino.isEmpty) return true;
    return destino.last.rango == grupo.first.rango + 1;
  }

  /// Mueve el grupo que arranca en (colOrigen, indice) a colDestino.
  /// Devuelve true si el movimiento se hizo (con o sin secuencia
  /// completada); false si era inválido.
  bool mover(int colOrigen, int indice, int colDestino) {
    if (colDestino == colOrigen) return false;
    final grupo = grupoSeleccionable(colOrigen, indice);
    if (grupo == null || !puedeSoltarEn(colDestino, grupo)) return false;
    columnas[colOrigen].removeRange(indice, columnas[colOrigen].length);
    columnas[colDestino].addAll(grupo);
    if (columnas[colOrigen].isNotEmpty) columnas[colOrigen].last.bocaArriba = true;
    _revisarSecuenciaCompleta(colDestino);
    return true;
  }

  bool _revisarSecuenciaCompleta(int columna) {
    final col = columnas[columna];
    if (col.length < 13) return false;
    final ultimos = col.sublist(col.length - 13);
    if (ultimos.first.rango != 13) return false;
    for (var i = 0; i < 13; i++) {
      final c = ultimos[i];
      if (!c.bocaArriba || c.palo != ultimos.first.palo || c.rango != 13 - i) return false;
    }
    col.removeRange(col.length - 13, col.length);
    if (col.isNotEmpty) col.last.bocaArriba = true;
    secuenciasCompletas++;
    return true;
  }

  bool get puedeRepartir => stock.length >= columnasSpider && columnas.every((c) => c.isNotEmpty);

  /// Reparte una carta boca arriba a cada columna desde el stock (regla
  /// clásica: solo si ninguna columna está vacía). Devuelve la cantidad
  /// de secuencias que se completaron con el reparto.
  int repartir() {
    if (!puedeRepartir) return 0;
    for (var c = 0; c < columnasSpider; c++) {
      final carta = stock.removeLast();
      carta.bocaArriba = true;
      columnas[c].add(carta);
    }
    var completadas = 0;
    for (var c = 0; c < columnasSpider; c++) {
      if (_revisarSecuenciaCompleta(c)) completadas++;
    }
    return completadas;
  }

  /// Ayuda: busca un movimiento posible entre columnas, priorizando el
  /// que destape una carta boca abajo. Devuelve (origen, índice, destino)
  /// o null si no hay ningún movimiento posible.
  (int, int, int)? buscarPista() {
    for (var origen = 0; origen < columnasSpider; origen++) {
      final inicio = inicioSecuenciaMovible(origen);
      if (inicio == null) continue;
      for (var indice = inicio; indice < columnas[origen].length; indice++) {
        final grupo = columnas[origen].sublist(indice);
        for (var destino = 0; destino < columnasSpider; destino++) {
          if (destino == origen) continue;
          if (columnas[destino].isEmpty && indice == 0) continue; // no cambia nada
          if (puedeSoltarEn(destino, grupo) && indice > 0) return (origen, indice, destino);
        }
      }
    }
    // Si no hay ninguna que destape una carta, aceptamos cualquiera válida.
    for (var origen = 0; origen < columnasSpider; origen++) {
      final inicio = inicioSecuenciaMovible(origen);
      if (inicio == null) continue;
      final grupo = columnas[origen].sublist(inicio);
      for (var destino = 0; destino < columnasSpider; destino++) {
        if (destino == origen) continue;
        if (columnas[destino].isEmpty && inicio == 0) continue;
        if (puedeSoltarEn(destino, grupo)) return (origen, inicio, destino);
      }
    }
    return null;
  }

  Map<String, dynamic> aJson() => {
        'nPalos': nPalos,
        'columnas': columnas.map((c) => c.map((carta) => carta.aJson()).toList()).toList(),
        'stock': stock.map((c) => c.aJson()).toList(),
        'secuenciasCompletas': secuenciasCompletas,
      };

  static SpiderGame desdeJson(Map<String, dynamic> j) => SpiderGame(
        nPalos: j['nPalos'] as int,
        columnas: (j['columnas'] as List)
            .map((c) => (c as List).map((x) => Carta.desdeJson(x as Map<String, dynamic>)).toList())
            .toList(),
        stock: (j['stock'] as List).map((x) => Carta.desdeJson(x as Map<String, dynamic>)).toList(),
        secuenciasCompletas: j['secuenciasCompletas'] as int,
      );
}
