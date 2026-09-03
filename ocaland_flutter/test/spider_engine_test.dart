import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/utils/spider_engine.dart';

void main() {
  group('SpiderGame.nuevo', () {
    for (final nPalos in [1, 2, 4]) {
      test('con $nPalos palo(s) arma un mazo de 104 cartas repartidas bien', () {
        final juego = SpiderGame.nuevo(nPalos, random: Random(1));
        final totalEnColumnas = juego.columnas.fold<int>(0, (s, c) => s + c.length);
        expect(totalEnColumnas + juego.stock.length, 104);

        // 4 columnas con 6 cartas, 6 columnas con 5 cartas.
        for (var c = 0; c < 4; c++) {
          expect(juego.columnas[c].length, 6);
        }
        for (var c = 4; c < columnasSpider; c++) {
          expect(juego.columnas[c].length, 5);
        }
        // Solo la última carta de cada columna queda boca arriba.
        for (final col in juego.columnas) {
          for (var i = 0; i < col.length; i++) {
            expect(col[i].bocaArriba, i == col.length - 1);
          }
        }
        // El stock alcanza para 5 repartos de 10 cartas.
        expect(juego.stock.length, 50);

        // La cantidad de palos usados coincide con lo pedido.
        final palosUsados = <Palo>{};
        for (final col in juego.columnas) {
          palosUsados.addAll(col.map((c) => c.palo));
        }
        for (final c in juego.stock) {
          palosUsados.add(c.palo);
        }
        expect(palosUsados.length, nPalos);
      });
    }
  });

  group('SpiderGame movimientos', () {
    test('grupoSeleccionable devuelve la secuencia descendente misma pinta del final de la columna', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].addAll([
        Carta(10, Palo.picas, bocaArriba: false),
        Carta(9, Palo.picas, bocaArriba: true),
        Carta(8, Palo.picas, bocaArriba: true),
        Carta(7, Palo.corazones, bocaArriba: true), // rompe la pinta acá
        Carta(6, Palo.corazones, bocaArriba: true),
      ]);
      // Desde el índice 3 (7♥) hacia abajo es una secuencia válida (7♥,6♥).
      final grupo = juego.grupoSeleccionable(0, 3);
      expect(grupo, isNotNull);
      expect(grupo!.map((c) => c.rango), [7, 6]);

      // El índice 2 (8♠) no es parte de la secuencia movible final (la
      // rompe el cambio de pinta en 7♥), así que no debería ser seleccionable.
      expect(juego.grupoSeleccionable(0, 2), isNull);

      // Una carta boca abajo nunca es seleccionable.
      expect(juego.grupoSeleccionable(0, 0), isNull);
    });

    test('mover traslada el grupo y voltea la nueva carta superior del origen', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].addAll([
        Carta(5, Palo.picas, bocaArriba: false),
        Carta(9, Palo.picas, bocaArriba: true),
      ]);
      juego.columnas[1].add(Carta(10, Palo.corazones, bocaArriba: true));

      final ok = juego.mover(0, 1, 1);
      expect(ok, isTrue);
      expect(juego.columnas[0].length, 1);
      expect(juego.columnas[0].last.bocaArriba, isTrue, reason: 'la carta que quedó debe voltearse boca arriba');
      expect(juego.columnas[1].map((c) => c.rango), [10, 9]);
    });

    test('mover rechaza un destino cuyo rango no es exactamente uno más que el grupo', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].add(Carta(9, Palo.picas, bocaArriba: true));
      juego.columnas[1].add(Carta(5, Palo.corazones, bocaArriba: true));
      expect(juego.mover(0, 0, 1), isFalse);
      expect(juego.columnas[0].length, 1);
      expect(juego.columnas[1].length, 1);
    });

    test('mover a una columna vacía siempre es válido', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].add(Carta(3, Palo.treboles, bocaArriba: true));
      expect(juego.mover(0, 0, 5), isTrue);
      expect(juego.columnas[5].single.rango, 3);
    });

    test('una secuencia K..A completa de la misma pinta se remueve y suma al contador', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].addAll([for (var r = 13; r >= 2; r--) Carta(r, Palo.picas, bocaArriba: true)]);
      juego.columnas[1].add(Carta(1, Palo.picas, bocaArriba: true));

      final movido = juego.mover(1, 0, 0);
      expect(movido, isTrue);
      expect(juego.secuenciasCompletas, 1);
      expect(juego.columnas[0], isEmpty);
    });
  });

  group('SpiderGame.repartir', () {
    test('reparte una carta boca arriba a cada columna y consume el stock', () {
      final juego = SpiderGame(
        nPalos: 1,
        columnas: List.generate(columnasSpider, (_) => [Carta(5, Palo.picas, bocaArriba: true)]),
        stock: List.generate(20, (_) => Carta(2, Palo.picas)),
      );
      final antes = juego.stock.length;
      juego.repartir();
      expect(juego.stock.length, antes - columnasSpider);
      for (final col in juego.columnas) {
        expect(col.length, 2);
        expect(col.last.bocaArriba, isTrue);
      }
    });

    test('no reparte si alguna columna está vacía', () {
      final columnas = List.generate(columnasSpider, (_) => [Carta(5, Palo.picas, bocaArriba: true)]);
      columnas[3] = [];
      final juego = SpiderGame(nPalos: 1, columnas: columnas, stock: List.generate(20, (_) => Carta(2, Palo.picas)));
      expect(juego.puedeRepartir, isFalse);
      expect(juego.repartir(), 0);
      expect(juego.stock.length, 20);
    });

    test('no reparte si el stock tiene menos de 10 cartas', () {
      final juego = SpiderGame(
        nPalos: 1,
        columnas: List.generate(columnasSpider, (_) => [Carta(5, Palo.picas, bocaArriba: true)]),
        stock: List.generate(5, (_) => Carta(2, Palo.picas)),
      );
      expect(juego.puedeRepartir, isFalse);
    });
  });

  group('SpiderGame.buscaPista y serialización', () {
    test('buscarPista encuentra un movimiento válido cuando existe', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].add(Carta(9, Palo.picas, bocaArriba: true));
      juego.columnas[1].add(Carta(10, Palo.corazones, bocaArriba: true));
      final pista = juego.buscarPista();
      expect(pista, isNotNull);
      final (origen, indice, destino) = pista!;
      expect(juego.mover(origen, indice, destino), isTrue);
    });

    test('buscarPista devuelve null cuando no hay ningún movimiento posible', () {
      final juego = SpiderGame(nPalos: 4, columnas: List.generate(columnasSpider, (_) => <Carta>[]), stock: []);
      juego.columnas[0].add(Carta(9, Palo.picas, bocaArriba: true));
      juego.columnas[1].add(Carta(3, Palo.corazones, bocaArriba: true));
      expect(juego.buscarPista(), isNull);
    });

    test('aJson/desdeJson conserva el estado completo', () {
      final original = SpiderGame.nuevo(2, random: Random(7));
      original.secuenciasCompletas = 3;
      final restaurado = SpiderGame.desdeJson(original.aJson());
      expect(restaurado.nPalos, original.nPalos);
      expect(restaurado.secuenciasCompletas, 3);
      expect(restaurado.stock.length, original.stock.length);
      for (var c = 0; c < columnasSpider; c++) {
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
