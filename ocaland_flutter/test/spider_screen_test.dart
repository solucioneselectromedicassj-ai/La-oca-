import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/screens/spider_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la pantalla del Spider carga, muestra el tablero y permite mover una carta', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SpiderScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('🕷️ Spider'), findsOneWidget);

    // Tocar dos cartas boca arriba (una de cada una de las dos primeras
    // columnas con cartas) no debería tirar ninguna excepción, sea o no
    // un movimiento válido.
    final gestos = find.byType(GestureDetector);
    expect(gestos, findsWidgets);
    await tester.tap(gestos.first);
    await tester.pump();
    await tester.tap(gestos.at(gestos.evaluate().length - 1));
    await tester.pump();

    expect(tester.takeException(), isNull);

    // Cambiar de dificultad antes de haber movido nada no debería pedir
    // confirmación (todavía no hay progreso que perder).
    await tester.tap(find.text('😌 1 palo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Empezar de nuevo?'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('retoma el estado guardado en vez de reiniciar al volver a entrar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SpiderScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    // Repartir del mazo genera un cambio de estado guardable.
    await tester.tap(find.textContaining('Repartir'));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('juego_estado_spider');
    expect(guardado, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SpiderScreen(usuarioId: 'u1')));
    await tester.pumpAndSettle();

    final prefs2 = await SharedPreferences.getInstance();
    expect(prefs2.getString('juego_estado_spider'), equals(guardado));
  });
}
