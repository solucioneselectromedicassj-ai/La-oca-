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
    expect(conteo[TipoCasilla.puente], 3);
    expect(conteo[TipoCasilla.carcel], 3);
    expect(conteo[TipoCasilla.calavera], 2);
  });

  test('la casilla 0 es salida y la 29 es meta, nunca trampa', () {
    final layout = BoardLayout.generar();
    expect(layout.tipoDe(0), TipoCasilla.normal);
    expect(layout.tipoDe(29), TipoCasilla.meta);
  });

  test('cada puente tiene un avance entre 2 y 4', () {
    final layout = BoardLayout.generar();
    for (final info in layout.puentes.values) {
      expect(info.avance, inInclusiveRange(2, 4));
    }
  });
}
