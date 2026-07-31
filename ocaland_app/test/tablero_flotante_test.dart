import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland/game/tablero_flotante.dart';

void main() {
  test('genera 30 puntos sueltos, sin sendero, dentro de rango razonable', () {
    final puntos = TableroFlotante.generar(30);
    expect(puntos.length, 30);
    for (final p in puntos) {
      expect(p.dx, inInclusiveRange(0.0, 1.0));
      expect(p.dy, inInclusiveRange(0.0, 1.0));
    }
    // INICIO arriba, META abajo.
    expect(puntos.first.dy, lessThan(puntos.last.dy));
  });

  test('las casillas quedan bien separadas entre sí (no se superponen)', () {
    final rng = Random(7);
    final puntos = TableroFlotante.generar(30, random: rng);
    const aspectRatioContenido = 0.62;
    for (var a = 0; a < puntos.length; a++) {
      for (var b = a + 1; b < puntos.length; b++) {
        final dx = puntos[a].dx - puntos[b].dx;
        final dy = (puntos[a].dy - puntos[b].dy) / aspectRatioContenido;
        final distancia = sqrt(dx * dx + dy * dy);
        expect(distancia, greaterThan(0.05));
      }
    }
  });

  test('dos generaciones distintas no dan el mismo layout (cambia por etapa)', () {
    final a = TableroFlotante.generar(30);
    final b = TableroFlotante.generar(30);
    final iguales = List.generate(30, (i) => a[i] == b[i]).every((v) => v);
    expect(iguales, isFalse);
  });
}
