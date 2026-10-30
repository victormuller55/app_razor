import 'dart:convert';

import 'package:app_razor/functions/agendamentos_atualizados.dart';
import 'package:app_razor/functions/aviso_avaliacao.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> aviso({
  required int id,
  required int idAgendamento,
  int? notaBarbearia,
  int? notaAtendimento,
}) {
  return <String, dynamic>{
    'id': id,
    'tipo': 'ATENDIMENTO_CONCLUIDO',
    'titulo': 'Como foi seu atendimento?',
    'mensagem':
        'Seu atendimento na barbearia Navalha foi concluído. Que tal avaliar sua experiência?',
    'id_agendamento': idAgendamento,
    'agendamento': <String, dynamic>{
      'id': idAgendamento,
      'status': 'CONCLUIDO',
      'nome_servico': 'Corte',
      'nota_avaliacao': notaBarbearia,
      'nota_avaliacao_atendimento': notaAtendimento,
    },
  };
}

void main() {
  late List<int> lidos;
  late List<int> abertos;
  late GlobalKey<NavigatorState> navegador;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    lidos = <int>[];
    abertos = <int>[];
    navegador = GlobalKey<NavigatorState>();
  });

  AvisosAtendimento avisos(List<Map<String, dynamic>> itens) {
    return AvisosAtendimento(
      buscar: () async => AppResponse(statusCode: 200, body: jsonEncode(itens)),
      marcarLida: ({required int id}) async {
        lidos.add(id);
        return AppResponse(statusCode: 200, body: '{}');
      },
      abrirAvaliacao:
          (BuildContext context, AgendamentoModel agendamento) async {
            abertos.add(agendamento.id!);
          },
      contexto: () => navegador.currentContext,
    );
  }

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        home: const Scaffold(body: SizedBox()),
      ),
    );
  }

  testWidgets(
    '"Avaliar" abre a avaliação do atendimento do aviso e marca como lido',
    (WidgetTester tester) async {
      await montar(tester);
      final AvisosAtendimento checador = avisos(<Map<String, dynamic>>[
        aviso(id: 7, idAgendamento: 42),
        aviso(id: 8, idAgendamento: 43),
      ]);

      final Future<void> conferindo = checador.verificar();
      await tester.pumpAndSettle();
      expect(find.text('Como foi seu atendimento?'), findsOneWidget);

      await tester.tap(find.text('AVALIAR'));
      await tester.pumpAndSettle();
      await conferindo;

      // Um aviso por vez: o segundo fica para a próxima conferida.
      expect(lidos, <int>[7]);
      expect(abertos, <int>[42]);
    },
  );

  testWidgets(
    '"Agora não" marca como lido sem abrir a avaliação nem perguntar de novo',
    (WidgetTester tester) async {
      await montar(tester);
      final AvisosAtendimento checador = avisos(<Map<String, dynamic>>[
        aviso(id: 7, idAgendamento: 42),
      ]);

      final Future<void> conferindo = checador.verificar();
      await tester.pumpAndSettle();
      await tester.tap(find.text('AGORA NÃO'));
      await tester.pumpAndSettle();
      await conferindo;

      expect(lidos, <int>[7]);
      expect(abertos, isEmpty);

      // Mesmo que a API ainda devolva o aviso (falha ao marcar), não pergunta de novo nesta sessão.
      await checador.verificar();
      await tester.pumpAndSettle();
      expect(find.text('Como foi seu atendimento?'), findsNothing);
    },
  );

  testWidgets('atendimento já avaliado só é marcado como lido, sem perguntar', (
    WidgetTester tester,
  ) async {
    await montar(tester);
    final AvisosAtendimento checador = avisos(<Map<String, dynamic>>[
      aviso(id: 7, idAgendamento: 42, notaBarbearia: 5, notaAtendimento: 4),
    ]);

    await checador.verificar();
    await tester.pumpAndSettle();

    expect(find.text('Como foi seu atendimento?'), findsNothing);
    expect(lidos, <int>[7]);
    expect(abertos, isEmpty);
  });

  group('cancelamento pela barbearia', () {
    late List<int> remarcados;

    Map<String, dynamic> cancelamento({int? idBarbearia = 3}) {
      return <String, dynamic>{
        'id': 9,
        'tipo': 'AGENDAMENTO_CANCELADO_BARBEARIA',
        'titulo': 'A barbearia cancelou seu horário',
        'mensagem':
            'Motivo: barbeiro doente. Sem custo para você: marque outro horário.',
        'id_agendamento': 50,
        'agendamento': <String, dynamic>{
          'id': 50,
          'id_barbearia': idBarbearia,
          'status': 'CANCELADO',
          'cancelado_por': 'BARBEARIA',
          'nome_servico': 'Corte',
        },
      };
    }

    AvisosAtendimento checadorCancelamento(Map<String, dynamic> item) {
      remarcados = <int>[];
      return AvisosAtendimento(
        buscar: () async =>
            AppResponse(statusCode: 200, body: jsonEncode(<dynamic>[item])),
        marcarLida: ({required int id}) async {
          lidos.add(id);
          return AppResponse(statusCode: 200, body: '{}');
        },
        abrirAvaliacao: (BuildContext context, AgendamentoModel a) async {
          abertos.add(a.id!);
        },
        abrirRemarcacao: (BuildContext context, AgendamentoModel a) async {
          remarcados.add(a.idBarbearia!);
        },
        contexto: () => navegador.currentContext,
      );
    }

    testWidgets('mostra o motivo e "Marcar outro horário" abre a reserva', (
      WidgetTester tester,
    ) async {
      await montar(tester);
      final AvisosAtendimento checador = checadorCancelamento(cancelamento());

      final Future<void> conferindo = checador.verificar();
      await tester.pumpAndSettle();
      expect(find.text('A barbearia cancelou seu horário'), findsOneWidget);
      expect(find.textContaining('barbeiro doente'), findsOneWidget);

      await tester.tap(find.text('MARCAR OUTRO HORÁRIO'));
      await tester.pumpAndSettle();
      await conferindo;

      expect(lidos, <int>[9]);
      expect(remarcados, <int>[3]);
      expect(abertos, isEmpty);
    });

    testWidgets('sem a barbearia no aviso, só confirma a leitura', (
      WidgetTester tester,
    ) async {
      await montar(tester);
      final AvisosAtendimento checador = checadorCancelamento(
        cancelamento(idBarbearia: null),
      );

      final Future<void> conferindo = checador.verificar();
      await tester.pumpAndSettle();
      expect(find.text('MARCAR OUTRO HORÁRIO'), findsNothing);
      await tester.tap(find.text('ENTENDI'));
      await tester.pumpAndSettle();
      await conferindo;

      expect(lidos, <int>[9]);
      expect(remarcados, isEmpty);
    });
  });

  testWidgets('sem rede não quebra e tenta de novo depois', (
    WidgetTester tester,
  ) async {
    await montar(tester);
    final AvisosAtendimento checador = AvisosAtendimento(
      buscar: () async => throw Exception('sem rede'),
      marcarLida: ({required int id}) async =>
          AppResponse(statusCode: 200, body: '{}'),
      contexto: () => navegador.currentContext,
    );

    await checador.verificar();
    await tester.pumpAndSettle();
    expect(find.text('Como foi seu atendimento?'), findsNothing);
  });

  testWidgets(
    'avisos informativos (RAZ-11): faixa com o mais recente, todos lidos e agenda recarregada',
    (WidgetTester tester) async {
      await montar(tester);
      final List<String> faixas = <String>[];
      final int antes = agendamentosAtualizados.value;
      final AvisosAtendimento checador = AvisosAtendimento(
        buscar: () async => AppResponse(
          statusCode: 200,
          body: jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 21,
              'tipo': 'PAGAMENTO_CONFIRMADO',
              'titulo': 'Pagamento confirmado',
              'mensagem': 'O Pix do seu horário foi confirmado.',
            },
            <String, dynamic>{
              'id': 20,
              'tipo': 'AGENDAMENTO_CONFIRMADO',
              'titulo': 'Horário confirmado',
            },
          ]),
        ),
        marcarLida: ({required int id}) async {
          lidos.add(id);
          return AppResponse(statusCode: 200, body: '{}');
        },
        informar: faixas.add,
        contexto: () => navegador.currentContext,
      );

      await checador.verificar();
      await tester.pumpAndSettle();

      expect(faixas, <String>[
        'Pagamento confirmado\nO Pix do seu horário foi confirmado.',
      ]);
      expect(lidos, <int>[21, 20]);
      expect(agendamentosAtualizados.value, antes + 1);

      // Já mostrados nesta sessão: não repete a faixa.
      await checador.verificar();
      expect(faixas, hasLength(1));
    },
  );
}
