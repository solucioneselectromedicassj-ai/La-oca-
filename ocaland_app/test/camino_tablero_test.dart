import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/camino_tablero.dart';

void main() {
  test('genera 30 puntos dentro de rango razonable y variables entre sí', () {
    final caminoA = CaminoTablero.generar(30);
    final caminoB = CaminoTablero.generar(30);

    expect(caminoA.length, 30);
    for (final p in caminoA) {
      expect(p.dx, inInclusiveRange(0.05, 0.95));
      expect(p.dy, inInclusiveRange(0.0, 1.0));
    }

    // Con alta probabilidad dos generaciones distintas no dan el mismo
    // camino exacto (confirma que efectivamente varía por etapa).
    final iguales = List.generate(30, (i) => caminoA[i] == caminoB[i]).every((v) => v);
    expect(iguales, isFalse);
  });

  test('la salida (0) y la meta (29) siempre están presentes', () {
    final camino = CaminoTablero.generar(30);
    expect(camino.first.dy, lessThan(camino.last.dy));
  });

  test('las 3 formas (serpiente/interrogación/espiral) generan 30 puntos válidos', () {
    for (final forma in FormaCamino.values) {
      final camino = CaminoTablero.generar(30, forma: forma);
      expect(camino.length, 30);
      expect(camino.first.dy, lessThan(camino.last.dy));
      for (final p in camino) {
        expect(p.dx, inInclusiveRange(0.05, 0.95));
        expect(p.dy, inInclusiveRange(0.0, 1.0));
      }
    }
  });

  test('FormaCamino.deEtapa rota serpiente/interrogación/espiral por etapa', () {
    expect(FormaCamino.deEtapa(1), FormaCamino.serpiente);
    expect(FormaCamino.deEtapa(2), FormaCamino.interrogacion);
    expect(FormaCamino.deEtapa(3), FormaCamino.espiral);
    expect(FormaCamino.deEtapa(4), FormaCamino.serpiente);
    expect(FormaCamino.deEtapa(5), FormaCamino.interrogacion);
    expect(FormaCamino.deEtapa(6), FormaCamino.espiral);
  });
}
