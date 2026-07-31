import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/board_layout.dart';
import 'package:ocaland/game/casilla.dart';

void main() {
  test('el layout siempre reparte 20 casillas trampa de 28 posibles', () {
    final layout = BoardLayout.generar();
    expect(layout.casillas.length, 20);

    final conteo = <TipoCasilla, int>{};
    for (final tipo in layout.casillas.values) {
      conteo[tipo] = (conteo[tipo] ?? 0) + 1;
    }

    expect(conteo[TipoCasilla.oca], 6);
    expect(conteo[TipoCasilla.minijuego], 6);
    expect(conteo[TipoCasilla.trampolin], 3);
    expect(conteo[TipoCasilla.carcel], 3);
    expect(conteo[TipoCasilla.calavera], 2);
  });

  test('la casilla 0 es salida y la 29 es meta, nunca trampa', () {
    final layout = BoardLayout.generar();
    expect(layout.tipoDe(0), TipoCasilla.normal);
    expect(layout.tipoDe(29), TipoCasilla.meta);
  });

  test('cada trampolín tiene un avance entre 2 y 4', () {
    final layout = BoardLayout.generar();
    for (final info in layout.trampolines.values) {
      expect(info.avance, inInclusiveRange(2, 4));
    }
  });

  test('los trampolines nunca quedan lo bastante cerca como para encadenarse', () {
    for (var i = 0; i < 50; i++) {
      final layout = BoardLayout.generar();
      final posiciones = layout.trampolines.keys.toList();
      for (var a = 0; a < posiciones.length; a++) {
        for (var b = a + 1; b < posiciones.length; b++) {
          expect((posiciones[a] - posiciones[b]).abs(), greaterThanOrEqualTo(5));
        }
      }
    }
  });

  test('sinCarcel saca la cárcel y reparte igual las 20 trampas entre el resto', () {
    final layout = BoardLayout.generar(sinCarcel: true);
    expect(layout.casillas.length, 20);
    expect(layout.casillas.values.contains(TipoCasilla.carcel), isFalse);

    final conteo = <TipoCasilla, int>{};
    for (final tipo in layout.casillas.values) {
      conteo[tipo] = (conteo[tipo] ?? 0) + 1;
    }
    expect(conteo[TipoCasilla.oca], 7);
    expect(conteo[TipoCasilla.minijuego], 7);
    expect(conteo[TipoCasilla.trampolin], 4);
    expect(conteo[TipoCasilla.calavera], 2);
  });
}
