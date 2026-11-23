import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/agendamento_lista_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AgendamentoModel _agendado() {
  return AgendamentoModel(
    id: 7,
    status: 'AGENDADO',
    nomeServico: 'Sobrancelha',
    nomeBarbearia: 'Barba & Cia Campina',
    nomeFuncionario: 'Alex Moreira',
    enderecoCompleto: 'Rua Begônia, 1207',
    dataAgendamento: '2026-11-17',
    horaInicio: '13:00',
    horaFim: '13:15',
    preco: 20,
  );
}

Future<void> _montar(WidgetTester tester, AgendamentoModel agendamento) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: agendamentoListaCard(
            agendamento: agendamento,
            onComoChegar: () {},
            onCancelar: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('card mostra só o essencial, sem profissional nem endereço', (
    WidgetTester tester,
  ) async {
    await _montar(tester, _agendado());

    expect(find.text('Sobrancelha'), findsOneWidget);
    expect(find.text('Barba & Cia Campina'), findsOneWidget);
    expect(find.text('Ver info'), findsOneWidget);
    expect(find.text('Como chegar'), findsOneWidget);
    expect(find.text('Alex Moreira'), findsNothing);
    expect(find.text('Rua Begônia, 1207'), findsNothing);
  });

  testWidgets('Ver info abre o modal com profissional e endereço', (
    WidgetTester tester,
  ) async {
    await _montar(tester, _agendado());

    await tester.tap(find.text('Ver info'));
    await tester.pumpAndSettle();

    expect(find.text('ATENDIMENTO'), findsOneWidget);
    expect(find.text('Profissional'), findsOneWidget);
    expect(find.text('Alex Moreira'), findsOneWidget);
    expect(find.text('LOCAL'), findsOneWidget);
    expect(find.text('Rua Begônia, 1207'), findsOneWidget);
  });
}
