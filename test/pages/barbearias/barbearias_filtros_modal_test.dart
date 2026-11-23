import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _abrir(WidgetTester tester, {required bool avancado}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BarbeariasFiltrosModal(
            filtros: BarbeariasFiltros.empty(),
            onApply: (_) {},
            avancado: avancado,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('filtros avançados mostram os campos com texto de exemplo', (
    WidgetTester tester,
  ) async {
    await _abrir(tester, avancado: true);

    for (final String texto in <String>[
      'Local',
      'Cidade',
      'Bairro',
      'Serviço e profissional',
      'Ex.: corte, barba',
      'Nome do profissional',
      'Preço',
      'Mínimo',
      'Máximo',
    ]) {
      expect(find.text(texto), findsOneWidget, reason: texto);
    }
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('campo com texto mostra o botão de apagar, que limpa o campo', (
    WidgetTester tester,
  ) async {
    await _abrir(tester, avancado: true);
    expect(find.byIcon(Phosphor.xCircle), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Curitiba');
    await tester.pump();
    expect(find.byIcon(Phosphor.xCircle), findsOneWidget);

    await tester.tap(find.byIcon(Phosphor.xCircle));
    await tester.pump();
    expect(find.text('Curitiba'), findsNothing);
    expect(find.byIcon(Phosphor.xCircle), findsNothing);
  });

  testWidgets('filtros simples não mostram os campos de texto', (
    WidgetTester tester,
  ) async {
    await _abrir(tester, avancado: false);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Distância'), findsOneWidget);
  });
}
