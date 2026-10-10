import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic MaterialApp smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Developify'))),
      ),
    );
    expect(find.text('Developify'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
