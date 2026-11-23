import 'package:app_razor/pages/menu/menu_espaco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<double> _espaco(WidgetTester tester, double paddingBaixo) async {
  late double espaco;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: paddingBaixo)),
      child: Builder(
        builder: (BuildContext context) {
          espaco = espacoBarraMenu(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return espaco;
}

void main() {
  testWidgets('sem barra por cima (Android) usa a folga padrão', (
    WidgetTester tester,
  ) async {
    expect(await _espaco(tester, 0), kBottomNavigationBarHeight);
  });

  testWidgets('com a barra de vidro (iOS) usa a altura real dela', (
    WidgetTester tester,
  ) async {
    expect(await _espaco(tester, 92), 92);
  });
}
