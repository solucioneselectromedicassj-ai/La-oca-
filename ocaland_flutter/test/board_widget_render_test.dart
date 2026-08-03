import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/jugador.dart';
import 'package:ocaland_flutter/screens/widgets/board_widget.dart';

void main() {
  testWidgets('BoardWidget renderiza sin errores para cada etapa/forma de sendero', (tester) async {
    final jugadores = [
      JugadorPartida(id: 'a', partidaId: 'p', nombre: 'Pablo', esBot: false, posicion: 5, ordenTurno: 0, saltaTurno: false, victorias: 0),
      JugadorPartida(id: 'b', partidaId: 'p', nombre: 'Bot', esBot: true, posicion: 12, ordenTurno: 1, saltaTurno: false, victorias: 0),
    ];
    final layout = <int, String>{5: 'oca', 12: 'carcel', 20: 'calavera', 8: 'puente', 15: 'minijuego'};

    for (final etapa in [1, 4, 7, 10]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 380,
            child: BoardWidget(layoutCasillas: layout, jugadores: jugadores, etapa: etapa),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'etapa $etapa');
      expect(find.byType(BoardWidget), findsOneWidget);
    }
  });
}
