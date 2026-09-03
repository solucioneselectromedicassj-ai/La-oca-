import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/screens/solitario_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la pantalla del Solitario carga, muestra el tablero y permite robar/mover sin explotar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SolitarioScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('🃏 Solitario'), findsOneWidget);
    expect(find.text('PUNTOS'), findsOneWidget);

    // Robar del mazo no debería tirar ninguna excepción.
    final gestos = find.byType(GestureDetector);
    expect(gestos, findsWidgets);
    await tester.tap(gestos.last); // el mazo suele quedar al final del árbol de widgets del tope
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Tocar un par de cartas del tablero tampoco debería explotar, sea o
    // no un movimiento válido.
    await tester.tap(gestos.first);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Cambiar el modo de robo antes de haber avanzado la partida no pide confirmación.
    await tester.tap(find.text('Sacar 3'));
    await tester.pumpAndSettle();
    expect(find.text('¿Empezar de nuevo?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retoma el estado guardado en vez de reiniciar al volver a entrar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SolitarioScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    final mazo = find.byIcon(Icons.refresh);
    // Si el mazo tiene cartas no habrá ícono de refresh todavía; buscamos
    // el widget del mazo por su contador en texto en su lugar.
    if (mazo.evaluate().isEmpty) {
      await tester.tap(find.textContaining('24'));
    } else {
      await tester.tap(mazo);
    }
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('juego_estado_solitario');
    expect(guardado, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SolitarioScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    final prefs2 = await SharedPreferences.getInstance();
    expect(prefs2.getString('juego_estado_solitario'), equals(guardado));
  });
}
