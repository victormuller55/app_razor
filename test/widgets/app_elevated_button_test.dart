import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> larguraDentroDeCentro(WidgetTester tester, Widget botao) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            // Centralizado: o lugar onde o infinito encolhia o botão para o texto.
            child: Center(child: botao),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(ElevatedButton)).width;
  }

  testWidgets('double.infinity ocupa toda a largura disponível, mesmo centralizado', (
    WidgetTester tester,
  ) async {
    expect(
      await larguraDentroDeCentro(
        tester,
        appElevatedButtonRazor(title: 'Confirmar', width: double.infinity, onTap: () {}),
      ),
      350,
    );
    expect(
      await larguraDentroDeCentro(
        tester,
        appElevatedButtonRazorTransparent(title: 'Pagar depois', width: double.infinity, onTap: () {}),
      ),
      350,
    );
  });

  testWidgets('largura fixa continua valendo', (WidgetTester tester) async {
    expect(
      await larguraDentroDeCentro(
        tester,
        appElevatedButtonRazor(title: 'Ok', width: 120, onTap: () {}),
      ),
      120,
    );
  });
}
