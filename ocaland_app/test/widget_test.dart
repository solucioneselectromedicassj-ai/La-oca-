import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocaland/theme/ocaland_theme.dart';

void main() {
  testWidgets('OcalandTheme.light builds a valid MaterialApp theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OcalandTheme.light,
        home: const Scaffold(body: Text('Ocaland')),
      ),
    );

    expect(find.text('Ocaland'), findsOneWidget);
  });
}
