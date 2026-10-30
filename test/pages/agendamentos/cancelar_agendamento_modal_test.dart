import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/cancelar_agendamento_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime inicio = DateTime(2026, 10, 28, 14);

  Future<List<String?>> montar(
    WidgetTester tester, {
    required DateTime agora,
    bool pagoPeloApp = false,
  }) async {
    final List<String?> confirmados = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CancelarAgendamentoSheet(
            onConfirmar: confirmados.add,
            onVoltar: () {},
            politica: PoliticaAgendamentoModel.padrao,
            agora: agora,
            inicio: inicio,
            pagoPeloApp: pagoPeloApp,
          ),
        ),
      ),
    );
    return confirmados;
  }

  testWidgets('no prazo mostra a regra de 1 hora e manda o motivo', (
    WidgetTester tester,
  ) async {
    final List<String?> confirmados = await montar(
      tester,
      agora: DateTime(2026, 10, 28, 12),
    );

    expect(find.textContaining('até 1 hora antes'), findsOneWidget);
    expect(find.textContaining('fora do prazo'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('motivo_cancelamento')),
      '  Imprevisto  ',
    );
    await tester.tap(find.text('SIM, CANCELAR'));
    await tester.pump();

    expect(confirmados, <String?>['Imprevisto']);
  });

  testWidgets('fora do prazo avisa, mas ainda deixa cancelar sem motivo', (
    WidgetTester tester,
  ) async {
    final List<String?> confirmados = await montar(
      tester,
      agora: DateTime(2026, 10, 28, 13, 30),
      pagoPeloApp: true,
    );

    expect(find.textContaining('fora do prazo, sem multa'), findsOneWidget);
    expect(find.textContaining('devolvido pelo Mercado Pago'), findsOneWidget);

    await tester.tap(find.text('SIM, CANCELAR'));
    await tester.pump();

    expect(confirmados, <String?>[null]);
  });

  testWidgets('as regras completas ficam a um toque', (
    WidgetTester tester,
  ) async {
    await montar(tester, agora: DateTime(2026, 10, 28, 12));

    expect(find.textContaining('Código de Defesa do Consumidor'), findsNothing);
    await tester.tap(find.text('Ver todas as regras'));
    await tester.pump();
    expect(
      find.textContaining('Código de Defesa do Consumidor'),
      findsOneWidget,
    );
  });
}
