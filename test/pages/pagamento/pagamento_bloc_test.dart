import 'dart:async';
import 'dart:io';

import 'package:app_razor/functions/api_error.dart';

import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/pagamento_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_bloc.dart';
import 'package:app_razor/pages/pagamento/pagamento_event.dart';
import 'package:app_razor/pages/pagamento/pagamento_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  const String pix = '00020126580014br.gov.bcb.pix0136teste5204000053039865802BR6304ABCD';

  AppResponse resposta(String status, {String? codigo}) {
    return AppResponse(
      statusCode: 200,
      body:
          '{"id": 1, "id_agendamento": 7, "status": "$status", "valor_total": 50.0, '
          '"expira_em": "2026-10-26T15:30:00"'
          '${codigo != null ? ', "pix_copia_cola": "$codigo"' : ''}}',
    );
  }

  /// Bloc com a API simulada; nenhuma cobrança real.
  PagamentoBloc criar({
    required List<AppResponse> consultas,
    AppResponse? inicio,
    Object? erroInicio,
    Object? erroConsulta,
    void Function()? aoIniciar,
    void Function()? aoConsultar,
    void Function(int idPagamento)? aoSimular,
    Duration intervalo = const Duration(hours: 1),
  }) {
    int indice = 0;
    return PagamentoBloc(
      idAgendamento: 7,
      intervaloConsulta: intervalo,
      iniciar: ({required int idAgendamento}) async {
        expect(idAgendamento, 7);
        aoIniciar?.call();
        if (erroInicio != null) {
          throw erroInicio;
        }
        return inicio ?? resposta('PENDENTE', codigo: pix);
      },
      consultar: ({required int idAgendamento}) async {
        aoConsultar?.call();
        if (erroConsulta != null) {
          throw erroConsulta;
        }
        final AppResponse atual = consultas[indice < consultas.length ? indice : consultas.length - 1];
        indice++;
        return atual;
      },
      simular: ({required int idPagamento}) async {
        aoSimular?.call(idPagamento);
        return AppResponse(statusCode: 204, body: '');
      },
    );
  }

  Future<PagamentoState> ate(PagamentoBloc bloc, Set<EtapaPagamento> etapas) {
    return bloc.stream.firstWhere((PagamentoState s) => etapas.contains(s.etapa));
  }

  group('PagamentoBloc Pix', () {
    test('mostra o QR Code e o copia e cola vindos da API, sem marcar como pago', () async {
      final PagamentoBloc bloc = criar(consultas: <AppResponse>[]);

      bloc.add(PagamentoIniciarEvent());
      final PagamentoState aguardando = await ate(bloc, {EtapaPagamento.aguardandoPix});

      expect(aguardando.pagamento?.pixCopiaCola, pix);
      expect(aguardando.pagamento?.expiraEm, DateTime(2026, 10, 26, 15, 30));
      expect(bloc.state.etapa, isNot(EtapaPagamento.aprovado));
      await bloc.close();
    });

    test('confere sozinho enquanto o Pix está aberto e só aprova quando a API confirma', () async {
      final PagamentoBloc bloc = criar(
        intervalo: Duration.zero,
        consultas: <AppResponse>[
          resposta('PENDENTE', codigo: pix),
          resposta('PENDENTE', codigo: pix),
          resposta('APROVADO'),
        ],
      );

      bloc.add(PagamentoIniciarEvent());
      final PagamentoState fim = await ate(bloc, {EtapaPagamento.aprovado, EtapaPagamento.erro});
      expect(fim.etapa, EtapaPagamento.aprovado);
      await bloc.close();
    });

    test('Pix de teste: paga pela API local e o aprovado vem da consulta', () async {
      final List<int> simulados = <int>[];
      final PagamentoBloc bloc = criar(
        consultas: <AppResponse>[resposta('APROVADO')],
        aoSimular: simulados.add,
      );

      bloc.add(PagamentoIniciarEvent());
      await ate(bloc, {EtapaPagamento.aguardandoPix});
      bloc.add(PagamentoSimularEvent());
      final PagamentoState fim = await ate(bloc, {EtapaPagamento.aprovado, EtapaPagamento.erro});

      expect(simulados, <int>[1]);
      expect(fim.etapa, EtapaPagamento.aprovado);
      await bloc.close();
    });

    test('voltar para o app só confere: continua pendente se a API diz pendente', () async {
      int consultas = 0;
      final PagamentoBloc bloc = criar(
        consultas: <AppResponse>[resposta('PENDENTE', codigo: pix)],
        aoConsultar: () => consultas++,
      );

      bloc.add(PagamentoIniciarEvent());
      await ate(bloc, {EtapaPagamento.aguardandoPix});
      bloc.add(PagamentoRetornouEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(consultas, 1);
      expect(bloc.state.etapa, EtapaPagamento.aguardandoPix);
      expect(bloc.state.pagamento?.pixCopiaCola, pix);
      await bloc.close();
    });

    test('expirado, cancelado, recusado e em análise vêm da API', () async {
      Future<EtapaPagamento> depoisDe(AppResponse consulta, EtapaPagamento esperada) async {
        final PagamentoBloc bloc = criar(consultas: <AppResponse>[consulta]);
        bloc.add(PagamentoIniciarEvent());
        await ate(bloc, {EtapaPagamento.aguardandoPix});
        bloc.add(PagamentoConsultarEvent());
        final PagamentoState fim = await ate(bloc, {esperada});
        await bloc.close();
        return fim.etapa;
      }

      expect(await depoisDe(resposta('EXPIRADO'), EtapaPagamento.expirado), EtapaPagamento.expirado);
      expect(await depoisDe(resposta('CANCELADO'), EtapaPagamento.cancelado), EtapaPagamento.cancelado);
      expect(await depoisDe(resposta('RECUSADO'), EtapaPagamento.recusado), EtapaPagamento.recusado);
      expect(
        await depoisDe(resposta('PROCESSANDO'), EtapaPagamento.processando),
        EtapaPagamento.processando,
      );
    });

    test('pendente sem código Pix não mostra QR Code', () async {
      final PagamentoBloc bloc = criar(inicio: resposta('PENDENTE'), consultas: <AppResponse>[]);
      bloc.add(PagamentoIniciarEvent());
      expect((await ate(bloc, {EtapaPagamento.expirado})).etapa, EtapaPagamento.expirado);
      await bloc.close();
    });

    test('cobrança já paga não gera outro Pix', () async {
      int chamadas = 0;
      final PagamentoBloc bloc = criar(
        inicio: resposta('APROVADO'),
        consultas: <AppResponse>[],
        aoIniciar: () => chamadas++,
      );
      bloc.add(PagamentoIniciarEvent());
      await ate(bloc, {EtapaPagamento.aprovado});
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      bloc.add(PagamentoIniciarEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(chamadas, 1);
      await bloc.close();
    });

    test('sem rede mostra erro de conexão; erro da API mostra a mensagem dela', () async {
      final PagamentoBloc semRede = criar(
        erroInicio: const SocketException('offline'),
        consultas: <AppResponse>[],
      );
      semRede.add(PagamentoIniciarEvent());
      expect((await ate(semRede, {EtapaPagamento.erroConexao})).etapa, EtapaPagamento.erroConexao);
      await semRede.close();

      final PagamentoBloc recusadoPelaApi = criar(
        erroInicio: ApiException(
          AppResponse(
            statusCode: 400,
            body: '{"status": 400, "message": "Esta barbearia ainda não recebe pagamentos pelo app"}',
          ),
        ),
        consultas: <AppResponse>[],
      );
      recusadoPelaApi.add(PagamentoIniciarEvent());
      final PagamentoState erro = await ate(recusadoPelaApi, {EtapaPagamento.erro});
      expect(erro.mensagem, contains('ainda não recebe'));
      await recusadoPelaApi.close();
    });

    test('tempo esgotado ao gerar o Pix encerra o carregamento e deixa tentar de novo', () async {
      int chamadas = 0;
      final PagamentoBloc bloc = criar(
        consultas: <AppResponse>[],
        erroInicio: TimeoutException('demorou'),
        aoIniciar: () => chamadas++,
      );
      bloc.add(PagamentoIniciarEvent());
      final PagamentoState erro = await ate(bloc, {EtapaPagamento.erro});

      expect(erro.etapa, isNot(EtapaPagamento.preparando));
      expect(erro.mensagem, mensagemTempoEsgotado);
      expect(erro.mensagem, isNot(contains('TimeoutException')));

      // A nova tentativa é segura: a API confere a cobrança antes de criar outra.
      bloc.add(PagamentoIniciarEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(chamadas, 1); // intervalo mínimo de 1s entre inícios
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      bloc.add(PagamentoIniciarEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(chamadas, 2);
      await bloc.close();
    });

    test('queda de rede na conferência mantém o QR Code na tela', () async {
      final PagamentoBloc bloc = criar(
        consultas: <AppResponse>[],
        erroConsulta: const SocketException('offline'),
      );
      bloc.add(PagamentoIniciarEvent());
      await ate(bloc, {EtapaPagamento.aguardandoPix});
      bloc.add(PagamentoConsultarEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.etapa, EtapaPagamento.aguardandoPix);
      expect(bloc.state.pagamento?.pixCopiaCola, pix);
      await bloc.close();
    });

    test('toques repetidos não geram dois Pix', () async {
      int chamadas = 0;
      final PagamentoBloc bloc = criar(
        consultas: <AppResponse>[resposta('PENDENTE', codigo: pix)],
        aoIniciar: () => chamadas++,
      );

      bloc
        ..add(PagamentoIniciarEvent())
        ..add(PagamentoIniciarEvent())
        ..add(PagamentoIniciarEvent());
      await ate(bloc, {EtapaPagamento.aguardandoPix});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(chamadas, 1);
      await bloc.close();
    });
  });

  group('AgendamentoModel pagamento', () {
    AgendamentoModel com(Map<String, dynamic> json) =>
        AgendamentoModel.fromJson(<String, dynamic>{'status': 'AGENDADO', ...json});

    test('só oferece pagar pelo app quando a barbearia recebe e ainda não foi pago', () {
      expect(com(<String, dynamic>{'pagamento_online': true}).podePagarPeloApp, isTrue);
      expect(com(<String, dynamic>{'pagamento_online': false}).podePagarPeloApp, isFalse);
      expect(com(<String, dynamic>{}).podePagarPeloApp, isFalse);
      expect(
        com(<String, dynamic>{'pagamento_online': true, 'status_pagamento': 'RECUSADO'}).podePagarPeloApp,
        isTrue,
      );
      final AgendamentoModel pago = com(<String, dynamic>{
        'pagamento_online': true,
        'status_pagamento': 'APROVADO',
      });
      expect(pago.pago, isTrue);
      expect(pago.podePagarPeloApp, isFalse);
      expect(
        com(<String, dynamic>{'pagamento_online': true, 'status_pagamento': 'PROCESSANDO'}).podePagarPeloApp,
        isFalse,
      );
      expect(
        AgendamentoModel.fromJson(<String, dynamic>{
          'status': 'CONFIRMADO',
          'pagamento_online': true,
        }).podePagarPeloApp,
        isFalse,
      );
    });

    test('PagamentoModel lê o status da API', () {
      final PagamentoModel pagamento = PagamentoModel.fromJson(<String, dynamic>{
        'id': 3,
        'status': 'PENDENTE',
        'valor_total': 45,
        'pix_copia_cola': 'codigo-pix',
      });
      expect(pagamento.status, StatusPagamento.pendente);
      expect(pagamento.emAberto, isTrue);
      expect(pagamento.valorTotal, 45.0);
      expect(pagamento.pixCopiaCola, 'codigo-pix');
      expect(PagamentoModel.fromJson(<String, dynamic>{'status': 'XYZ'}).status, StatusPagamento.desconhecido);
    });
  });
}
