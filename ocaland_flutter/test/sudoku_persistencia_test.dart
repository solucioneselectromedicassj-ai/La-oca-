import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocaland_flutter/screens/sudoku_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('el sudoku retoma el estado guardado en vez de reiniciar al volver a entrar', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Primera entrada: se genera un sudoku nuevo.
    await tester.pumpWidget(const MaterialApp(home: SudokuScreen(usuarioId: 'u1', nivel: 'menor')));
    await tester.pumpAndSettle(); // deja correr el Future() que genera el puzzle
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'debería haber terminado de generar');

    // Toco la primera celda vacía que encuentre y le pongo un número.
    final celdas = find.byType(GestureDetector);
    expect(celdas, findsWidgets);

    // Toco la tecla "1" del teclado (asumiendo que hay al menos una celda vacía).
    final tecla1 = find.text('1').last;
    // Selecciono una celda vacía: busco el primer GestureDetector tocable (no fija).
    // Como no sabemos cuál es fija de antemano, tocamos varias hasta que el
    // toque de la tecla "1" efectivamente cambie algo guardado.
    for (final celda in celdas.evaluate().take(20)) {
      await tester.tap(find.byWidget(celda.widget));
      await tester.pump();
    }
    await tester.tap(tecla1);
    await tester.pump();

    // Verificamos que haya quedado algo guardado bajo la clave del juego.
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('juego_estado_sudoku');
    expect(guardado, isNotNull, reason: 'debería haber guardado el estado tras jugar una celda');

    // "Salgo" (se destruye el widget) y "vuelvo a entrar" (se crea una
    // instancia nueva de SudokuScreen, como pasa al navegar de nuevo).
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SudokuScreen(usuarioId: 'u1', nivel: 'menor')));
    await tester.pumpAndSettle();

    // El estado restaurado debería seguir siendo el mismo blob guardado
    // (si se hubiera "reiniciado", este string cambiaría porque
    // SudokuGenerator arma un puzzle nuevo al azar cada vez).
    final prefs2 = await SharedPreferences.getInstance();
    final guardadoDespues = prefs2.getString('juego_estado_sudoku');
    expect(guardadoDespues, equals(guardado), reason: 'el sudoku se reinició en vez de retomar el guardado');
  });
}
