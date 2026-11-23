import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/pages/menu/widgets/menu_barra_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<MenuBarraItem> _itens = <MenuBarraItem>[
  MenuBarraItem(
    label: 'Início',
    icon: Phosphor.house,
    iconSelecionado: PhosphorFill.house,
  ),
  MenuBarraItem(
    label: 'Agenda',
    icon: Phosphor.calendarBlank,
    iconSelecionado: PhosphorFill.calendarBlank,
  ),
];

void main() {
  testWidgets('mostra os nomes, o ícone cheio só na aba atual e avisa o toque',
      (WidgetTester tester) async {
    final List<int> tocados = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MenuBarraAndroid(
            itens: _itens,
            indiceAtual: 0,
            onSelecionar: tocados.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.byIcon(PhosphorFill.house), findsOneWidget);
    expect(find.byIcon(Phosphor.calendarBlank), findsOneWidget);
    expect(find.byIcon(PhosphorFill.calendarBlank), findsNothing);

    await tester.tap(find.text('Agenda'));
    expect(tocados, <int>[1]);
  });
}
