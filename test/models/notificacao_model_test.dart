import 'dart:convert';

import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/notificacao_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> agendamentoJson({
  int id = 42,
  String status = 'CONCLUIDO',
  int? notaBarbearia,
  int? notaAtendimento,
}) {
  return <String, dynamic>{
    'id': id,
    'nome_servico': 'Corte',
    'nome_barbearia': 'Navalha',
    'status': status,
    'nota_avaliacao': notaBarbearia,
    'nota_avaliacao_atendimento': notaAtendimento,
  };
}

void main() {
  group('AgendamentoModel.podeAvaliar', () {
    test('concluído sem nenhuma nota pode avaliar', () {
      expect(AgendamentoModel.fromJson(agendamentoJson()).podeAvaliar, isTrue);
    });

    test('com só uma das notas ainda pode dar a outra', () {
      final AgendamentoModel soAtendimento = AgendamentoModel.fromJson(
        agendamentoJson(notaAtendimento: 5),
      );
      final AgendamentoModel soBarbearia = AgendamentoModel.fromJson(
        agendamentoJson(notaBarbearia: 4),
      );

      expect(soAtendimento.notaAvaliacaoAtendimento, 5);
      expect(soAtendimento.podeAvaliar, isTrue);
      expect(soBarbearia.notaAvaliacao, 4);
      expect(soBarbearia.podeAvaliar, isTrue);
    });

    test('com as duas notas, ou sem concluir, não pode avaliar', () {
      expect(
        AgendamentoModel.fromJson(
          agendamentoJson(notaBarbearia: 4, notaAtendimento: 5),
        ).podeAvaliar,
        isFalse,
      );
      for (final String status in <String>[
        'AGENDADO',
        'CONFIRMADO',
        'EM_ATENDIMENTO',
        'CANCELADO',
      ]) {
        expect(
          AgendamentoModel.fromJson(
            agendamentoJson(status: status),
          ).podeAvaliar,
          isFalse,
          reason: status,
        );
      }
      expect(
        AgendamentoModel.fromJson(
          agendamentoJson(status: 'EM_ATENDIMENTO'),
        ).emAtendimento,
        isTrue,
      );
    });
  });

  group('NotificacaoModel', () {
    String resposta(List<Map<String, dynamic>> itens) => jsonEncode(itens);

    Map<String, dynamic> aviso({
      int id = 7,
      String tipo = 'ATENDIMENTO_CONCLUIDO',
      int idAgendamento = 42,
      Map<String, dynamic>? agendamento,
    }) {
      return <String, dynamic>{
        'id': id,
        'tipo': tipo,
        'titulo': 'Como foi seu atendimento?',
        'mensagem': 'Seu atendimento na barbearia Navalha foi concluído.',
        'id_agendamento': idAgendamento,
        'agendamento': agendamento ?? agendamentoJson(id: idAgendamento),
        'lida': false,
      };
    }

    test('lê a lista da API e aponta para o atendimento certo', () {
      final List<NotificacaoModel> avisos = NotificacaoModel.listaFromJson(
        jsonDecode(
          resposta(<Map<String, dynamic>>[
            aviso(),
            aviso(id: 8, idAgendamento: 43),
          ]),
        ),
      );

      expect(avisos, hasLength(2));
      expect(avisos.first.id, 7);
      expect(avisos.first.titulo, 'Como foi seu atendimento?');
      expect(avisos.first.atendimentoConcluido, isTrue);
      expect(avisos.first.agendamentoParaAvaliar?.id, 42);
      expect(avisos.last.agendamentoParaAvaliar?.id, 43);
    });

    test(
      'não abre avaliação de outro agendamento, de tipo desconhecido ou já avaliado',
      () {
        final NotificacaoModel trocado = NotificacaoModel.fromJson(
          aviso(agendamento: agendamentoJson(id: 99)),
        )!;
        final NotificacaoModel outroTipo = NotificacaoModel.fromJson(
          aviso(tipo: 'OUTRO'),
        )!;
        final NotificacaoModel avaliado = NotificacaoModel.fromJson(
          aviso(
            agendamento: agendamentoJson(notaBarbearia: 5, notaAtendimento: 5),
          ),
        )!;

        expect(trocado.agendamentoParaAvaliar, isNull);
        expect(outroTipo.agendamentoParaAvaliar, isNull);
        expect(avaliado.agendamentoParaAvaliar, isNull);
      },
    );

    test('ignora itens sem id e respostas que não são lista', () {
      expect(
        NotificacaoModel.listaFromJson(<dynamic>[
          <String, dynamic>{'titulo': 'x'},
        ]),
        isEmpty,
      );
      expect(NotificacaoModel.listaFromJson(<String, dynamic>{}), isEmpty);
    });
  });
}
