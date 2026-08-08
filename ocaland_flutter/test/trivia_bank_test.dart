import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/trivia_bank.dart';

void main() {
  group('TriviaBank', () {
    // Regresión: bancoPorPais/bancoDificil devolvían la lista const interna
    // tal cual. Los controllers de juego le hacen `..shuffle()` al
    // resultado para elegir una pregunta al azar, y una lista const es
    // inmutable — .shuffle() tiraba una excepción no capturada (silenciosa
    // en release web) y la Cuestionados nunca llegaba a mostrarse. Esto
    // pasaba SIEMPRE que tocaba una trampa (oca/cárcel/calavera), en modo
    // solo y en multijugador.
    for (final pais in TriviaBank.paises) {
      for (final bracket in ['ninos', 'adolescentes', 'jovenes', 'adultos', 'adultos_plus', 'mayores']) {
        test('bancoPorPais($pais, $bracket) devuelve una lista no vacía y mezclable', () {
          final banco = TriviaBank.bancoPorPais(pais, bracket);
          expect(banco, isNotEmpty);
          expect(() => banco.shuffle(), returnsNormally);
        });

        test('bancoDificil($bracket) devuelve una lista no vacía y mezclable', () {
          final banco = TriviaBank.bancoDificil(bracket);
          expect(banco, isNotEmpty);
          expect(() => banco.shuffle(), returnsNormally);
        });
      }
    }
  });
}
