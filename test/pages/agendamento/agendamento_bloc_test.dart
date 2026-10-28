import 'dart:async';
import 'dart:convert';

import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_blocos.dart';
import 'package:app_razor/pages/agendamento/agendamento_bloc.dart';
import 'package:app_razor/pages/agendamento/agendamento_event.dart';
import 'package:app_razor/pages/agendamento/agendamento_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

AppResponse ok(Object body) =>
    AppResponse(statusCode: 200, body: jsonEncode(body));

/// Barbearia com Barba (1, 25 min) e Corte (2, 40 min); Leandro (10) faz os
/// dois e Igor (20) só faz corte.
const Map<String, dynamic> contexto = <String, dynamic>{
  'id_barbearia': 1,
  'servicos': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 1,
      'nome': 'Barba',
      'preco': 30,
      'duracao_minutos': 25,
    },
    <String, dynamic>{
      'id': 2,
      'nome': 'Corte',
      'preco': 45,
      'duracao_minutos': 40,
    },
  ],
  'funcionarios': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 10,
      'nome': 'Leandro',
      'ids_servicos': <int>[1, 2],
    },
    <String, dynamic>{
      'id': 20,
      'nome': 'Igor',
      'ids_servicos': <int>[2],
    },
  ],
};

Map<String, dynamic> horarios(int duracao) {
  return <String, dynamic>{
    'duracao_minutos': duracao,
    'horarios': <Map<String, dynamic>>[
      for (int t = 9 * 60; t + duracao <= 12 * 60; t += 15)
        <String, dynamic>{
          'hora_inicio': '${horaDeMinutos(t)}:00',
          'hora_fim': '${horaDeMinutos(t + duracao)}:00',
          'disponivel': true,
        },
    ],
  };
}

void main() {
  late List<Map<String, dynamic>> criados;
  late List<List<Map<String, dynamic>>> ordens;
  late bool falharOrdem;
  late List<List<int>> ignorados;
  // Horários que a API já considera ocupados (a grade só muda na próxima consulta).
  late Set<String> ocupadoAgora;
  // Quantas confirmações seguidas ficam sem resposta (tempo esgotado) antes de a API responder.
  late int semResposta;
  late List<
    ({int? idOrdem, int idAgendamento, List<Map<String, dynamic>> itens})
  >
  edicoes;

  /// Duração somada que a API devolve para os serviços pedidos juntos.
  int duracao(List<int> ids) =>
      ids.fold<int>(0, (int soma, int id) => soma + (id == 1 ? 25 : 40));

  AgendamentoBloc criarBloc({int? servicoId, AgendamentoEdicao? edicao}) {
    int proximoId = 100;
    return AgendamentoBloc(
      barbeariaId: 1,
      servicoId: servicoId,
      edicao: edicao,
      agora: () => DateTime(2026, 11, 2, 8),
      putEdicao:
          ({
            int? idOrdem,
            required int idAgendamento,
            required List<Map<String, dynamic>> itens,
          }) async {
            edicoes.add((
              idOrdem: idOrdem,
              idAgendamento: idAgendamento,
              itens: itens,
            ));
            return ok(<String, dynamic>{
              'id': 88,
              'valor_a_pagar': 45,
              'valor_estornado': null,
              'agendamentos': <Map<String, dynamic>>[
                for (final Map<String, dynamic> item in itens)
                  <String, dynamic>{
                    ...item,
                    'id': item['id'] ?? proximoId++,
                    'status': 'AGENDADO',
                  },
              ],
            });
          },
      getContexto:
          ({required int idBarbearia, bool forceRefresh = false}) async =>
              ok(contexto),
      getHorarios:
          ({
            required int idBarbearia,
            required int idFuncionarioBarbearia,
            required List<int> idsBarbeariaServico,
            required String data,
            List<int> ignorar = const <int>[],
            bool forceRefresh = false,
          }) async {
            ignorados.add(ignorar);
            final Map<String, dynamic> grade = horarios(
              duracao(idsBarbeariaServico),
            );
            for (final dynamic horario in grade['horarios'] as List<dynamic>) {
              final String inicio = horario['hora_inicio'] as String;
              if (ocupadoAgora.contains(inicio.substring(0, 5))) {
                horario['disponivel'] = false;
              }
            }
            return ok(grade);
          },
      postAgendamento:
          ({
            required int idBarbearia,
            required int idFuncionarioBarbearia,
            required int idBarbeariaServico,
            required String dataAgendamento,
            required String horaInicio,
            String? observacao,
          }) async {
            if (semResposta > 0) {
              semResposta--;
              throw TimeoutException('sem resposta');
            }
            if (ocupadoAgora.contains(horaInicio)) {
              // Outra pessoa marcou entre a consulta e a confirmação.
              throw ApiException(
                AppResponse(
                  statusCode: 409,
                  body: jsonEncode(<String, dynamic>{
                    'status': 409,
                    'error': 'Conflict',
                    'message':
                        'Esse horário acabou de ficar indisponível. Escolha outro horário para continuar',
                  }),
                ),
              );
            }
            final Map<String, dynamic> item = <String, dynamic>{
              'id': proximoId++,
              'id_funcionario_barbearia': idFuncionarioBarbearia,
              'id_barbearia_servico': idBarbeariaServico,
              'hora_inicio': horaInicio,
            };
            criados.add(item);
            return ok(item);
          },
      postOrdem:
          ({
            required int idBarbearia,
            required List<Map<String, dynamic>> itens,
            String? observacao,
          }) async {
            // A API cria tudo ou nada.
            if (falharOrdem) {
              throw Exception('ocupado');
            }
            ordens.add(itens);
            return ok(<String, dynamic>{
              'id': 77,
              'agendamentos': <Map<String, dynamic>>[
                for (final Map<String, dynamic> item in itens)
                  <String, dynamic>{
                    ...item,
                    'id': proximoId++,
                    'id_ordem_servico': 77,
                  },
              ],
            });
          },
    );
  }

  Future<AgendamentoState> esperar(
    AgendamentoBloc bloc,
    bool Function(AgendamentoState state) condicao,
  ) async {
    if (condicao(bloc.state)) {
      return bloc.state;
    }
    return bloc.stream.firstWhere(condicao);
  }

  bool horariosProntos(AgendamentoState state) =>
      state is AgendamentoReadyState &&
      state.blocos.isNotEmpty &&
      state.blocos.every((b) => !b.loadingHorarios && b.horarios.isNotEmpty);

  setUp(() {
    criados = <Map<String, dynamic>>[];
    ordens = <List<Map<String, dynamic>>>[];
    falharOrdem = false;
    ignorados = <List<int>>[];
    ocupadoAgora = <String>{};
    semResposta = 0;
    edicoes = [];
  });

  test(
    'horário ocupado na confirmação recarrega a grade e pede outro horário',
    () async {
      final AgendamentoBloc bloc = criarBloc(servicoId: 1);
      bloc.add(AgendamentoLoadEvent());
      await esperar(bloc, horariosProntos);
      bloc.add(
        AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
      );
      await esperar(bloc, (AgendamentoState s) => s.completo);
      final int consultasAntes = ignorados.length;

      // Entre a consulta e o toque em confirmar, alguém marcou 09:00.
      ocupadoAgora.add('09:00');
      bloc.add(AgendamentoSalvarEvent());
      await esperar(bloc, (AgendamentoState s) => s.salvando);
      final AgendamentoState depois = await esperar(
        bloc,
        (AgendamentoState s) =>
            s is AgendamentoReadyState &&
            !s.salvando &&
            horariosProntos(s) &&
            s.blocos.single.horarios.any(
              (h) => h.horaInicio == '09:00' && !h.disponivel,
            ),
      );

      expect(ignorados.length, greaterThan(consultasAntes));
      expect(criados, isEmpty);
      expect(depois, isA<AgendamentoReadyState>());
      // A seleção de serviço e profissional fica; o horário sai e 09:00 aparece ocupado.
      expect(depois.blocos.single.idFuncionario, 10);
      expect(depois.blocos.single.idsServicos, <int>[1]);
      expect(depois.blocos.single.horaInicio, isNull);
      expect(depois.completo, isFalse);
      final bool nove = depois.blocos.single.horarios
          .firstWhere((h) => h.horaInicio == '09:00')
          .disponivel;
      expect(nove, isFalse);

      // Escolhe outro e marca.
      bloc.add(
        AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:30'),
      );
      await esperar(bloc, (AgendamentoState s) => s.completo);
      bloc.add(AgendamentoSalvarEvent());
      await esperar(bloc, (AgendamentoState s) => s is AgendamentoSuccessState);
      expect(criados.single['hora_inicio'], '09:30');
      await bloc.close();
    },
  );

  test('mesmo profissional faz os dois serviços seguidos numa ordem', () async {
    final AgendamentoBloc bloc = criarBloc(servicoId: 1);
    bloc.add(AgendamentoLoadEvent());
    await esperar(bloc, horariosProntos);

    // Barba sugere o Leandro (único que faz); o corte entra junto com ele.
    bloc.add(AgendamentoToggleServicoEvent(2));
    final AgendamentoState pronto = await esperar(
      bloc,
      (AgendamentoState s) =>
          horariosProntos(s) && s.blocos.single.idsServicos.length == 2,
    );
    expect(pronto.blocos.single.idFuncionario, 10);
    expect(pronto.blocos.single.duracaoTotal, 65);

    bloc.add(
      AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
    );
    await esperar(bloc, (AgendamentoState s) => s.completo);

    bloc.add(AgendamentoSalvarEvent());
    final AgendamentoState fim = await esperar(
      bloc,
      (AgendamentoState s) => s is AgendamentoSuccessState,
    );

    // Os dois vão numa ordem só, sem passar pelo /novo.
    expect(criados, isEmpty);
    expect(ordens.single.map((item) => item['hora_inicio']), <String>[
      '09:00',
      '09:25',
    ]);
    expect((fim as AgendamentoSuccessState).agendamentos.length, 2);
    expect(fim.agendamentos.map((item) => item.id), <int>[100, 101]);
    expect(fim.idOrdem, '77');
    await bloc.close();
  });

  test('um serviço só vai pelo /novo, sem ordem', () async {
    final AgendamentoBloc bloc = criarBloc(servicoId: 1);
    bloc.add(AgendamentoLoadEvent());
    await esperar(bloc, horariosProntos);
    bloc.add(
      AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
    );
    await esperar(bloc, (AgendamentoState s) => s.completo);

    bloc.add(AgendamentoSalvarEvent());
    final AgendamentoState fim = await esperar(
      bloc,
      (AgendamentoState s) => s is AgendamentoSuccessState,
    );

    expect(criados.single['hora_inicio'], '09:00');
    expect(ordens, isEmpty);
    expect((fim as AgendamentoSuccessState).idOrdem, isNull);
    await bloc.close();
  });

  test(
    'tempo esgotado ao confirmar encerra o carregamento, mantém a seleção e deixa tentar de novo',
    () async {
      semResposta = 1;
      final AgendamentoBloc bloc = criarBloc(servicoId: 1);
      bloc.add(AgendamentoLoadEvent());
      await esperar(bloc, horariosProntos);
      bloc.add(
        AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
      );
      await esperar(bloc, (AgendamentoState s) => s.completo);

      bloc.add(AgendamentoSalvarEvent());
      await esperar(bloc, (AgendamentoState s) => s.salvando);
      final AgendamentoState depois = await esperar(
        bloc,
        (AgendamentoState s) => s is AgendamentoReadyState && !s.salvando,
      );
      expect(criados, isEmpty);
      expect(depois.completo, isTrue);
      expect(depois.blocos.single.horaInicio, '09:00');

      // A API devolve a mesma reserva se a primeira tivesse sido gravada; repetir é seguro.
      bloc.add(AgendamentoSalvarEvent());
      await esperar(bloc, (AgendamentoState s) => s is AgendamentoSuccessState);
      expect(criados.single['hora_inicio'], '09:00');
      await bloc.close();
    },
  );

  test('profissionais diferentes pedem um horário para cada', () async {
    final AgendamentoBloc bloc = criarBloc(servicoId: 1);
    bloc.add(AgendamentoLoadEvent());
    await esperar(bloc, horariosProntos);

    bloc.add(AgendamentoToggleServicoEvent(2));
    await esperar(
      bloc,
      (AgendamentoState s) =>
          horariosProntos(s) && s.blocos.single.idsServicos.length == 2,
    );
    bloc.add(AgendamentoSelectFuncionarioEvent(20, idServico: 2));
    final AgendamentoState dois = await esperar(
      bloc,
      (AgendamentoState s) => horariosProntos(s) && s.blocos.length == 2,
    );
    expect(dois.completo, isFalse);

    // Barba às 09:00 (até 09:25) bloqueia o corte com o Igor que bateria nisso.
    bloc.add(
      AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
    );
    final AgendamentoState comBarba = await esperar(
      bloc,
      (AgendamentoState s) => s.blocos.first.horaInicio == '09:00',
    );
    final Iterable<String?> livresIgor = comBarba.blocos
        .firstWhere((b) => b.idFuncionario == 20)
        .horarios
        .where((h) => h.disponivel)
        .map((h) => h.horaInicio);
    expect(livresIgor.contains('09:00'), isFalse);
    expect(livresIgor.contains('09:30'), isTrue);
    await bloc.close();
  });

  test('se a ordem falha, nada é criado e a seleção fica', () async {
    falharOrdem = true;
    final AgendamentoBloc bloc = criarBloc(servicoId: 1);
    bloc.add(AgendamentoLoadEvent());
    await esperar(bloc, horariosProntos);
    bloc.add(AgendamentoToggleServicoEvent(2));
    await esperar(
      bloc,
      (AgendamentoState s) =>
          horariosProntos(s) && s.blocos.single.idsServicos.length == 2,
    );
    bloc.add(
      AgendamentoSelectHorarioEvent(idFuncionario: 10, horaInicio: '09:00'),
    );
    await esperar(bloc, (AgendamentoState s) => s.completo);

    bloc.add(AgendamentoSalvarEvent());
    await esperar(bloc, (AgendamentoState s) => s.salvando);
    final AgendamentoState depois = await esperar(
      bloc,
      (AgendamentoState s) => s is AgendamentoReadyState && !s.salvando,
    );

    expect(criados, isEmpty);
    expect(ordens, isEmpty);
    expect(depois.completo, isTrue);
    await bloc.close();
  });

  test(
    'edição volta com o horário marcado e acrescenta serviço com o id do que fica',
    () async {
      final AgendamentoBloc bloc = criarBloc(
        edicao: AgendamentoEdicao(
          itens: <AgendamentoModel>[
            AgendamentoModel(
              id: 41,
              idBarbearia: 1,
              idFuncionarioBarbearia: 10,
              idBarbeariaServico: 1,
              dataAgendamento: '2026-11-02',
              horaInicio: '10:00:00',
              status: 'AGENDADO',
            ),
          ],
        ),
      );
      bloc.add(AgendamentoLoadEvent());
      final AgendamentoState pronto = await esperar(
        bloc,
        (AgendamentoState s) => horariosProntos(s) && s.completo,
      );

      // O horário da própria reserva aparece livre e já vem escolhido.
      expect(pronto.blocos.single.idFuncionario, 10);
      expect(pronto.blocos.single.horaInicio, '10:00');
      expect(ignorados.last, <int>[41]);

      bloc.add(AgendamentoToggleServicoEvent(2));
      await esperar(
        bloc,
        (AgendamentoState s) =>
            horariosProntos(s) &&
            s.blocos.single.idsServicos.length == 2 &&
            s.completo,
      );

      bloc.add(AgendamentoSalvarEvent());
      final AgendamentoState fim = await esperar(
        bloc,
        (AgendamentoState s) => s is AgendamentoSuccessState,
      );

      expect(criados, isEmpty);
      expect(ordens, isEmpty);
      expect(edicoes.single.idOrdem, isNull);
      expect(edicoes.single.idAgendamento, 41);
      expect(edicoes.single.itens.map((item) => item['id']), <int?>[41, null]);
      expect(edicoes.single.itens.map((item) => item['hora_inicio']), <String>[
        '10:00',
        '10:25',
      ]);
      final AgendamentoSuccessState sucesso = fim as AgendamentoSuccessState;
      expect(sucesso.editado, isTrue);
      expect(sucesso.valorAPagar, 45);
      expect(sucesso.idOrdem, '88');
      await bloc.close();
    },
  );
}
