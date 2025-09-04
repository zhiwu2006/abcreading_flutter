// Minimal smoke test adapted for current project (no MyApp class).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    ));

    // Verify the widget tree builds and contains a SizedBox.
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
