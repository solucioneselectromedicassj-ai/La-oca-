import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/utils/klondike_engine.dart';

void main() {
  group('KlondikeGame.nuevo', () {
    test('arma un mazo de 52 cartas repartidas 1..7 por columna', () {
      final juego = KlondikeGame.nuevo(random: Random(1));
      final totalEnColumnas = juego.columnas.fold<int>(0, (s, c) => s + c.length);
      expect(totalEnColumnas + juego.stock.length, 52);
      for (var c = 0; c < columnasKlondike; c++) {
        expect(juego.columnas[c].length, c + 1);
      }
      expect(totalEnColumnas, 28);
      expect(juego.stock.length, 24);
      for (final col in juego.columnas) {
        for (var i = 0; i < col.length; i++) {
          expect(col[i].bocaArriba, i == col.length - 1);
        }
      }
      expect(juego.descarte, isEmpty);
      expect(juego.fundaciones.values.every((v) => v == 0), isTrue);

      // Sin cartas repetidas.
      final vistas = <String>{};
      for (final col in juego.columnas) {
        for (final c in col) {
          expect(vistas.add('${c.rango}-${c.palo}'), isTrue);
        }
      }
      for (final c in juego.stock) {
        expect(vistas.add('${c.rango}-${c.palo}'), isTrue);
      }
      expect(vistas.length, 52);
    });
  });

  group('KlondikeGame movimientos de tablero', () {
    test('grupoSeleccionable exige alternar color y descender', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].addAll([
        Carta(10, Palo.picas, bocaArriba: false),
        Carta(9, Palo.corazones, bocaArriba: true),
        Carta(8, Palo.picas, bocaArriba: true), // sigue alternando (rojo->negro)
        Carta(7, Palo.picas, bocaArriba: true), // mismo color que la anterior: rompe la secuencia
        Carta(6, Palo.corazones, bocaArriba: true),
      ]);
      final grupo = juego.grupoSeleccionable(0, 3);
      expect(grupo!.map((c) => c.rango), [7, 6]);
      expect(juego.grupoSeleccionable(0, 2), isNull); // el 8♠ no es parte de la cola movible
      expect(juego.grupoSeleccionable(0, 0), isNull); // boca abajo
    });

    test('mover traslada el grupo y destapa la carta que queda arriba', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].addAll([Carta(5, Palo.picas, bocaArriba: false), Carta(9, Palo.corazones, bocaArriba: true)]);
      juego.columnas[1].add(Carta(10, Palo.picas, bocaArriba: true));

      final ok = juego.mover(0, 1, 1);
      expect(ok, isTrue);
      expect(juego.columnas[0].single.bocaArriba, isTrue);
      expect(juego.columnas[1].map((c) => c.rango), [10, 9]);
      expect(juego.puntos, 5, reason: 'destapó una carta oculta');
    });

    test('mover rechaza mismo color o rango que no baja en exactamente uno', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].add(Carta(9, Palo.picas, bocaArriba: true));
      juego.columnas[1].add(Carta(10, Palo.treboles, bocaArriba: true)); // mismo color (negro)
      juego.columnas[2].add(Carta(5, Palo.corazones, bocaArriba: true)); // no es 9+1
      expect(juego.mover(0, 0, 1), isFalse);
      expect(juego.mover(0, 0, 2), isFalse);
    });

    test('solo un Rey puede iniciar una columna vacía', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].add(Carta(9, Palo.picas, bocaArriba: true));
      juego.columnas[1].add(Carta(13, Palo.corazones, bocaArriba: true));
      expect(juego.mover(0, 0, 3), isFalse);
      expect(juego.mover(1, 0, 3), isTrue);
      expect(juego.columnas[3].single.rango, 13);
    });
  });

  group('KlondikeGame fundaciones', () {
    test('solo acepta la carta siguiente del mismo palo', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].add(Carta(2, Palo.picas, bocaArriba: true));
      expect(juego.moverTableauAFundacion(0), isFalse, reason: 'todavía no hay un As de picas en la fundación');

      juego.columnas[1].add(Carta(1, Palo.picas, bocaArriba: true));
      expect(juego.moverTableauAFundacion(1), isTrue);
      expect(juego.fundaciones[Palo.picas], 1);
      expect(juego.puntos, 10);

      expect(juego.moverTableauAFundacion(0), isTrue);
      expect(juego.fundaciones[Palo.picas], 2);
    });

    test('moverDescarteAFundacion consume la carta de arriba del descarte', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [Carta(1, Palo.corazones, bocaArriba: true)],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      expect(juego.moverDescarteAFundacion(), isTrue);
      expect(juego.descarte, isEmpty);
      expect(juego.fundaciones[Palo.corazones], 1);
    });

    test('gano es true solo cuando las 4 fundaciones llegan a K', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 13},
      );
      expect(juego.gano, isTrue);
      juego.fundaciones[Palo.picas] = 12;
      expect(juego.gano, isFalse);
    });
  });

  group('KlondikeGame mazo y descarte', () {
    test('robarDelMazo saca drawCount cartas boca arriba al descarte', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: List.generate(10, (i) => Carta(i % 13 + 1, Palo.picas)),
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
        drawCount: 3,
      );
      juego.robarDelMazo();
      expect(juego.descarte.length, 3);
      expect(juego.stock.length, 7);
      expect(juego.descarte.every((c) => c.bocaArriba), isTrue);
    });

    test('robarDelMazo con el mazo vacío recicla el descarte', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [Carta(1, Palo.picas, bocaArriba: true), Carta(2, Palo.picas, bocaArriba: true)],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.robarDelMazo();
      expect(juego.descarte, isEmpty);
      expect(juego.stock.length, 2);
      expect(juego.stock.every((c) => !c.bocaArriba), isTrue);
    });

    test('robarDelMazo no hace nada si mazo y descarte están vacíos', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      expect(juego.puedeRobar, isFalse);
      juego.robarDelMazo();
      expect(juego.movimientos, 0);
    });
  });

  group('KlondikeGame.buscarPista y serialización', () {
    test('prioriza mandar una carta a la fundación', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      juego.columnas[0].add(Carta(1, Palo.picas, bocaArriba: true));
      final pista = juego.buscarPista();
      expect(pista, isNotNull);
      expect(pista!.tipo, 'tableauAFundacion');
      expect(pista.columnaOrigen, 0);
    });

    test('sugiere robar cuando no hay otro movimiento posible', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [Carta(5, Palo.picas)],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      final pista = juego.buscarPista();
      expect(pista!.tipo, 'robar');
    });

    test('devuelve null cuando no hay ningún movimiento posible', () {
      final juego = KlondikeGame(
        columnas: List.generate(columnasKlondike, (_) => <Carta>[]),
        stock: [],
        descarte: [],
        fundaciones: {for (final p in Palo.values) p: 0},
      );
      expect(juego.buscarPista(), isNull);
    });

    test('aJson/desdeJson conserva el estado completo', () {
      final original = KlondikeGame.nuevo(drawCount: 3, random: Random(9));
      original.robarDelMazo();
      original.puntos = 45;
      original.movimientos = 7;
      final restaurado = KlondikeGame.desdeJson(original.aJson());
      expect(restaurado.drawCount, 3);
      expect(restaurado.puntos, 45);
      expect(restaurado.movimientos, 7);
      expect(restaurado.stock.length, original.stock.length);
      expect(restaurado.descarte.length, original.descarte.length);
      for (final palo in Palo.values) {
        expect(restaurado.fundaciones[palo], original.fundaciones[palo]);
      }
      for (var c = 0; c < columnasKlondike; c++) {
        expect(restaurado.columnas[c].length, original.columnas[c].length);
        for (var i = 0; i < original.columnas[c].length; i++) {
          expect(restaurado.columnas[c][i].rango, original.columnas[c][i].rango);
          expect(restaurado.columnas[c][i].palo, original.columnas[c][i].palo);
          expect(restaurado.columnas[c][i].bocaArriba, original.columnas[c][i].bocaArriba);
        }
      }
    });
  });
}
