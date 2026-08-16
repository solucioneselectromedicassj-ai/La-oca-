import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/models/trivia_bank.dart';
import 'package:ocaland_flutter/screens/widgets/trivia_overlay.dart';

void main() {
  const p1 = TriviaQuestion('¿Pregunta 1?', ['A', 'B', 'C', 'D'], 0);
  const p2 = TriviaQuestion('¿Pregunta 2?', ['A', 'B', 'C', 'D'], 1);

  testWidgets('deja responder la segunda pregunta después de contestar la primera (no queda "trabado")', (tester) async {
    final respuestas = <int>[];
    TriviaQuestion actual = p1;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return TriviaOverlay(
              titulo: 'Test',
              pregunta: actual,
              segundos: 0,
              onResponder: (idx) {
                respuestas.add(idx);
                setState(() => actual = p2);
              },
            );
          },
        ),
      ),
    );

    // Responde la primera pregunta.
    await tester.tap(find.text('A').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(respuestas, [0]);

    // Ahora debería estar mostrando la segunda pregunta.
    expect(find.text('¿Pregunta 2?'), findsOneWidget);

    // Antes del fix, este toque no hacía nada porque el widget seguía
    // pensando que ya se había respondido la pregunta anterior.
    await tester.tap(find.text('B').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(respuestas, [0, 1]);
  });
}
