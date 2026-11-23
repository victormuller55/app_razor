import 'package:app_razor/widgets/app_scaffold_razor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o título sem maiúsculas e o voltar só com tela anterior', (
    WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> navegador = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        home: scaffoldRazor(title: 'Início', body: const SizedBox()),
      ),
    );

    expect(find.text('Início'), findsOneWidget);
    expect(find.byType(BotaoVoltarRazor), findsNothing);

    navegador.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            scaffoldRazor(title: 'Editar nome', body: const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar nome'), findsOneWidget);
    expect(find.text('EDITAR NOME'), findsNothing);
    expect(find.byType(BotaoVoltarRazor), findsOneWidget);

    await tester.tap(find.byType(BotaoVoltarRazor));
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Editar nome'), findsNothing);
  });
}
