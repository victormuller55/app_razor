import 'package:app_razor/app_config/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App sobe sem splash customizada', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
