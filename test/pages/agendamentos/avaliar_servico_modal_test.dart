import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

class _Envio {
  _Envio(this.id, this.nota, this.comentario);

  final int id;
  final int nota;
  final String? comentario;
}

void main() {
  late List<_Envio> atendimento;
  late List<_Envio> barbearia;
  bool falharBarbearia = false;
  bool? resultado;

  Future<AppResponse> enviarAtendimento({
    required int id,
    required int nota,
    String? comentario,
  }) async {
    atendimento.add(_Envio(id, nota, comentario));
    return AppResponse(statusCode: 201, body: '{}');
  }

  Future<AppResponse> enviarBarbearia({
    required int id,
    required int nota,
    String? comentario,
  }) async {
    if (falharBarbearia) {
      throw Exception('falhou');
    }
    barbearia.add(_Envio(id, nota, comentario));
    return AppResponse(statusCode: 201, body: '{}');
  }

  setUp(() {
    atendimento = <_Envio>[];
    barbearia = <_Envio>[];
    falharBarbearia = false;
    resultado = null;
  });

  Future<void> abrir(WidgetTester tester, AgendamentoModel agendamento) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await showAvaliarServicoModal(
                  context: context,
                  agendamento: agendamento,
                  enviarAtendimento: enviarAtendimento,
                  enviarBarbearia: enviarBarbearia,
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.text('ENVIAR AVALIAÇÃO'));
    await tester.pumpAndSettle();
  }

  AgendamentoModel concluido({int? notaBarbearia, int? notaAtendimento}) {
    return AgendamentoModel(
      id: 42,
      status: 'CONCLUIDO',
      nomeServico: 'Corte',
      nomeFuncionario: 'Caio',
      nomeBarbearia: 'Navalha',
      notaAvaliacao: notaBarbearia,
      notaAvaliacaoAtendimento: notaAtendimento,
    );
  }

  testWidgets('avalia só o serviço e o profissional', (
    WidgetTester tester,
  ) async {
    await abrir(tester, concluido());
    expect(find.text('O serviço e o profissional'), findsOneWidget);
    expect(find.text('A barbearia'), findsOneWidget);

    await tester.tap(find.byKey(const Key('estrela_atendimento_5')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('comentario_atendimento')),
      'O Caio caprichou',
    );
    await enviar(tester);

    expect(atendimento.single.id, 42);
    expect(atendimento.single.nota, 5);
    expect(atendimento.single.comentario, 'O Caio caprichou');
    expect(barbearia, isEmpty);
    expect(resultado, isTrue);
  });

  testWidgets('avalia só a barbearia', (WidgetTester tester) async {
    await abrir(tester, concluido());
    await tester.tap(find.byKey(const Key('estrela_barbearia_3')));
    await enviar(tester);

    expect(atendimento, isEmpty);
    expect(barbearia.single.nota, 3);
  });

  testWidgets('avalia as duas de uma vez', (WidgetTester tester) async {
    await abrir(tester, concluido());
    await tester.tap(find.byKey(const Key('estrela_atendimento_4')));
    await tester.tap(find.byKey(const Key('estrela_barbearia_5')));
    await enviar(tester);

    expect(atendimento.single.nota, 4);
    expect(barbearia.single.nota, 5);
  });

  testWidgets('sem nota nenhuma não envia; "Agora não" fecha sem avaliar', (
    WidgetTester tester,
  ) async {
    await abrir(tester, concluido());
    await enviar(tester);
    expect(find.text('O serviço e o profissional'), findsOneWidget);

    await tester.tap(find.text('AGORA NÃO'));
    await tester.pumpAndSettle();

    expect(atendimento, isEmpty);
    expect(barbearia, isEmpty);
    expect(resultado, isNull);
  });

  testWidgets('a nota já dada aparece pronta e não é enviada de novo', (
    WidgetTester tester,
  ) async {
    await abrir(tester, concluido(notaBarbearia: 4));
    expect(find.byKey(const Key('estrela_barbearia_1')), findsNothing);
    expect(find.text('Sua avaliação'), findsOneWidget);

    await tester.tap(find.byKey(const Key('estrela_atendimento_2')));
    await enviar(tester);

    expect(atendimento.single.nota, 2);
    expect(barbearia, isEmpty);
  });

  testWidgets(
    'se a da barbearia falha, a do atendimento fica e dá para tentar de novo',
    (WidgetTester tester) async {
      falharBarbearia = true;
      await abrir(tester, concluido());
      await tester.tap(find.byKey(const Key('estrela_atendimento_5')));
      await tester.tap(find.byKey(const Key('estrela_barbearia_5')));
      await enviar(tester);

      // Folha continua aberta; a do atendimento já foi e não aparece mais para editar.
      expect(atendimento, hasLength(1));
      expect(find.byKey(const Key('estrela_atendimento_5')), findsNothing);
      expect(find.byKey(const Key('estrela_barbearia_5')), findsOneWidget);

      falharBarbearia = false;
      await enviar(tester);

      expect(atendimento, hasLength(1));
      expect(barbearia.single.nota, 5);
      expect(resultado, isTrue);
    },
  );
}
