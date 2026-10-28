import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// RAZ-03: o app só fala em dinheiro devolvido quando a API diz que o
/// Mercado Pago confirmou.
void main() {
  AgendamentoModel cancelado(Map<String, dynamic> reembolso) {
    return AgendamentoModel.fromJson(<String, dynamic>{
      'id': 1,
      'status': 'CANCELADO',
      'status_pagamento': 'APROVADO',
      ...reembolso,
    });
  }

  group('reembolso no AgendamentoModel', () {
    test('lê a situação e os valores do reembolso', () {
      final AgendamentoModel item = cancelado(<String, dynamic>{
        'status_reembolso': 'PROCESSANDO',
        'valor_reembolso_pendente': 60,
      });

      expect(item.statusReembolso, 'PROCESSANDO');
      expect(item.valorReembolsoPendente, 60);
      expect(item.valorReembolsado, isNull);
      expect(item.reembolsoEmProcessamento, isTrue);
      expect(item.reembolsoLabel, 'Reembolso em processamento');
    });

    test('cancelado com pagamento aprovado não aparece como pago', () {
      final AgendamentoModel item = cancelado(<String, dynamic>{
        'status_reembolso': 'PROCESSANDO',
      });

      expect(item.pago, isFalse);
    });

    test('selo para confirmado e para falha', () {
      expect(
        cancelado(<String, dynamic>{
          'status_reembolso': 'CONFIRMADO',
        }).reembolsoLabel,
        'Reembolsado',
      );
      expect(
        cancelado(<String, dynamic>{
          'status_reembolso': 'FALHOU',
        }).reembolsoLabel,
        'Reembolso em nova tentativa',
      );
      expect(cancelado(<String, dynamic>{}).reembolsoLabel, isNull);
    });
  });

  group('mensagem do cancelamento', () {
    test('em processamento não diz que o dinheiro voltou', () {
      final String? mensagem = AgendamentosBloc.mensagemReembolso(
        <AgendamentoModel>[
          cancelado(<String, dynamic>{
            'status_reembolso': 'PROCESSANDO',
            'valor_reembolso_pendente': 60,
          }),
        ],
      );

      expect(mensagem, contains('em processamento'));
      expect(mensagem, isNot(contains('confirmado')));
      expect(mensagem, isNot(contains('devolvid')));
    });

    test('confirmado diz que o Mercado Pago confirmou', () {
      final String? mensagem = AgendamentosBloc.mensagemReembolso(
        <AgendamentoModel>[
          cancelado(<String, dynamic>{
            'status_reembolso': 'CONFIRMADO',
            'valor_reembolsado': 60,
          }),
        ],
      );

      expect(mensagem, contains('confirmado pelo Mercado Pago'));
    });

    test('falha pede verificação e sem pagamento não há mensagem', () {
      expect(
        AgendamentosBloc.mensagemReembolso(<AgendamentoModel>[
          cancelado(<String, dynamic>{'status_reembolso': 'FALHOU'}),
        ]),
        contains('não se perde'),
      );
      expect(
        AgendamentosBloc.mensagemReembolso(<AgendamentoModel>[
          cancelado(<String, dynamic>{}),
        ]),
        isNull,
      );
    });
  });
}
