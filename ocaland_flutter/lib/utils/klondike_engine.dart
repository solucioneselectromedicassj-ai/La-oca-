import 'dart:math';

/// Motor puro del Solitario clásico (Klondike, 1 mazo de 52 cartas) —
/// separado de la pantalla para poder testearlo fácil, igual que
/// `sudoku_generator.dart`. El usuario pidió explícitamente este juego
/// ("el que juego... creo es el solitario"), con mazo/descarte
/// (sacar 1 o 3), fundaciones por palo, deshacer y pista.
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

const columnasKlondike = 7;

/// Un movimiento sugerido por `buscarPista()`.
class PistaMovimiento {
  final String tipo; // 'tableauAFundacion' | 'descarteAFundacion' | 'descarteAColumna' | 'tableauATableau' | 'robar'
  final int? columnaOrigen;
  final int? indice;
  final int? columnaDestino;
  const PistaMovimiento({required this.tipo, this.columnaOrigen, this.indice, this.columnaDestino});
}

class KlondikeGame {
  final List<List<Carta>> columnas;
  final List<Carta> stock;
  final List<Carta> descarte;
  final Map<Palo, int> fundaciones; // rango tope por palo, 0 = vacía
  int drawCount; // 1 | 3
  int puntos;
  int movimientos;

  KlondikeGame({
    required this.columnas,
    required this.stock,
    required this.descarte,
    required this.fundaciones,
    this.drawCount = 1,
    this.puntos = 0,
    this.movimientos = 0,
  });

  factory KlondikeGame.nuevo({int drawCount = 1, Random? random}) {
    final mazo = _crearMazo(random ?? Random());
    final columnas = List.generate(columnasKlondike, (_) => <Carta>[]);
    var idx = 0;
    for (var c = 0; c < columnasKlondike; c++) {
      for (var i = 0; i <= c; i++) {
        columnas[c].add(mazo[idx++]);
      }
      columnas[c].last.bocaArriba = true;
    }
    final stock = mazo.sublist(idx);
    return KlondikeGame(
      columnas: columnas,
      stock: stock,
      descarte: [],
      fundaciones: {for (final p in Palo.values) p: 0},
      drawCount: drawCount,
    );
  }

  static List<Carta> _crearMazo(Random rnd) {
    final mazo = <Carta>[];
    for (final palo in Palo.values) {
      for (var rango = 1; rango <= 13; rango++) {
        mazo.add(Carta(rango, palo));
      }
    }
    mazo.shuffle(rnd);
    return mazo;
  }

  bool get gano => fundaciones.values.every((v) => v == 13);

  /// Índice donde empieza la secuencia movible (alternando color,
  /// descendente, boca arriba) que termina al final de la columna.
  int? inicioSecuenciaMovible(int columna) {
    final col = columnas[columna];
    if (col.isEmpty) return null;
    var inicio = col.length - 1;
    while (inicio > 0) {
      final actual = col[inicio];
      final anterior = col[inicio - 1];
      if (!anterior.bocaArriba) break;
      if (anterior.esRoja == actual.esRoja) break;
      if (anterior.rango != actual.rango + 1) break;
      inicio--;
    }
    return inicio;
  }

  List<Carta>? grupoSeleccionable(int columna, int indice) {
    final col = columnas[columna];
    if (indice < 0 || indice >= col.length || !col[indice].bocaArriba) return null;
    final inicio = inicioSecuenciaMovible(columna);
    if (inicio == null || indice < inicio) return null;
    return col.sublist(indice);
  }

  /// Regla clásica: una columna vacía solo admite un Rey (con lo que
  /// venga apilado debajo de él en el grupo que se está moviendo).
  bool puedeSoltarEnColumna(int columnaDestino, List<Carta> grupo) {
    final destino = columnas[columnaDestino];
    if (destino.isEmpty) return grupo.first.rango == 13;
    final tope = destino.last;
    return tope.esRoja != grupo.first.esRoja && tope.rango == grupo.first.rango + 1;
  }

  bool puedeApilarEnFundacion(Carta carta) {
    final actual = fundaciones[carta.palo] ?? 0;
    return carta.rango == actual + 1;
  }

  bool mover(int colOrigen, int indice, int colDestino) {
    if (colOrigen == colDestino) return false;
    final grupo = grupoSeleccionable(colOrigen, indice);
    if (grupo == null || !puedeSoltarEnColumna(colDestino, grupo)) return false;
    final origen = columnas[colOrigen];
    final reveloCarta = indice > 0 && !origen[indice - 1].bocaArriba;
    origen.removeRange(indice, origen.length);
    columnas[colDestino].addAll(grupo);
    if (origen.isNotEmpty) origen.last.bocaArriba = true;
    movimientos++;
    if (reveloCarta) puntos += 5;
    return true;
  }

  bool moverTableauAFundacion(int columna) {
    final col = columnas[columna];
    if (col.isEmpty || !col.last.bocaArriba || !puedeApilarEnFundacion(col.last)) return false;
    final carta = col.removeLast();
    fundaciones[carta.palo] = carta.rango;
    if (col.isNotEmpty) col.last.bocaArriba = true;
    movimientos++;
    puntos += 10;
    return true;
  }

  bool moverDescarteAFundacion() {
    if (descarte.isEmpty || !puedeApilarEnFundacion(descarte.last)) return false;
    final carta = descarte.removeLast();
    fundaciones[carta.palo] = carta.rango;
    movimientos++;
    puntos += 10;
    return true;
  }

  bool moverDescarteAColumna(int columnaDestino) {
    if (descarte.isEmpty || !puedeSoltarEnColumna(columnaDestino, [descarte.last])) return false;
    final carta = descarte.removeLast();
    columnas[columnaDestino].add(carta);
    movimientos++;
    return true;
  }

  bool get puedeRobar => stock.isNotEmpty || descarte.isNotEmpty;

  /// Roba `drawCount` cartas del mazo al descarte; si el mazo está
  /// vacío, recicla el descarte de vuelta boca abajo (regla clásica).
  void robarDelMazo() {
    if (stock.isEmpty) {
      if (descarte.isEmpty) return;
      for (final c in descarte) {
        c.bocaArriba = false;
      }
      stock.addAll(descarte.reversed);
      descarte.clear();
      movimientos++;
      return;
    }
    final n = min(drawCount, stock.length);
    for (var i = 0; i < n; i++) {
      final c = stock.removeLast();
      c.bocaArriba = true;
      descarte.add(c);
    }
    movimientos++;
  }

  /// Ayuda: busca un movimiento posible, priorizando fundaciones y
  /// movidas que destapen una carta oculta.
  PistaMovimiento? buscarPista() {
    for (var c = 0; c < columnasKlondike; c++) {
      final col = columnas[c];
      if (col.isNotEmpty && col.last.bocaArriba && puedeApilarEnFundacion(col.last)) {
        return PistaMovimiento(tipo: 'tableauAFundacion', columnaOrigen: c);
      }
    }
    if (descarte.isNotEmpty && puedeApilarEnFundacion(descarte.last)) {
      return const PistaMovimiento(tipo: 'descarteAFundacion');
    }
    for (var origen = 0; origen < columnasKlondike; origen++) {
      final inicio = inicioSecuenciaMovible(origen);
      if (inicio == null || inicio == 0) continue;
      final grupo = columnas[origen].sublist(inicio);
      for (var destino = 0; destino < columnasKlondike; destino++) {
        if (destino == origen) continue;
        if (puedeSoltarEnColumna(destino, grupo)) {
          return PistaMovimiento(tipo: 'tableauATableau', columnaOrigen: origen, indice: inicio, columnaDestino: destino);
        }
      }
    }
    if (descarte.isNotEmpty) {
      for (var destino = 0; destino < columnasKlondike; destino++) {
        if (puedeSoltarEnColumna(destino, [descarte.last])) {
          return PistaMovimiento(tipo: 'descarteAColumna', columnaDestino: destino);
        }
      }
    }
    for (var origen = 0; origen < columnasKlondike; origen++) {
      final inicio = inicioSecuenciaMovible(origen);
      if (inicio == null) continue;
      final grupo = columnas[origen].sublist(inicio);
      for (var destino = 0; destino < columnasKlondike; destino++) {
        if (destino == origen) continue;
        if (columnas[destino].isEmpty && inicio == 0) continue; // no cambia nada
        if (puedeSoltarEnColumna(destino, grupo)) {
          return PistaMovimiento(tipo: 'tableauATableau', columnaOrigen: origen, indice: inicio, columnaDestino: destino);
        }
      }
    }
    if (puedeRobar) return const PistaMovimiento(tipo: 'robar');
    return null;
  }

  Map<String, dynamic> aJson() => {
        'columnas': columnas.map((c) => c.map((carta) => carta.aJson()).toList()).toList(),
        'stock': stock.map((c) => c.aJson()).toList(),
        'descarte': descarte.map((c) => c.aJson()).toList(),
        'fundaciones': {for (final e in fundaciones.entries) '${e.key.index}': e.value},
        'drawCount': drawCount,
        'puntos': puntos,
        'movimientos': movimientos,
      };

  static KlondikeGame desdeJson(Map<String, dynamic> j) {
    List<Carta> aCartas(dynamic v) => (v as List).map((x) => Carta.desdeJson(x as Map<String, dynamic>)).toList();
    final fundacionesJson = j['fundaciones'] as Map<String, dynamic>;
    return KlondikeGame(
      columnas: (j['columnas'] as List).map((c) => aCartas(c)).toList(),
      stock: aCartas(j['stock']),
      descarte: aCartas(j['descarte']),
      fundaciones: {for (final p in Palo.values) p: fundacionesJson['${p.index}'] as int? ?? 0},
      drawCount: j['drawCount'] as int? ?? 1,
      puntos: j['puntos'] as int? ?? 0,
      movimientos: j['movimientos'] as int? ?? 0,
    );
  }
}
