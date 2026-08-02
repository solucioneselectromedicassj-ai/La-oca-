import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocaland_flutter/main.dart';

void main() {
  testWidgets('La app arranca y muestra el splash inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const OcalandApp());
    // No usamos pumpAndSettle: RootScreen dispara una llamada de red
    // (restaurar identidad) en el post-frame callback, así que solo
    // verificamos el primer frame (el splash), sin esperar a que resuelva.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
