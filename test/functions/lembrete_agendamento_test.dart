import 'package:app_razor/functions/lembrete_agendamento.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendamentoModel em(
    int id,
    String hora, {
    String status = 'AGENDADO',
    String? fim,
    String data = '2026-10-26',
    String? conclusao,
    String? inicioAtendimento,
  }) {
    return AgendamentoModel.fromJson(<String, dynamic>{
      'id': id,
      'data_agendamento': data,
      'hora_inicio': hora,
      'hora_fim': fim,
      'duracao_minutos': 30,
      'status': status,
      'nome_servico': 'Corte',
      'nome_barbearia': 'Navalha',
      'nome_funcionario': 'Caio Souza',
      'data_conclusao': conclusao,
      'data_inicio_atendimento': inicioAtendimento,
      'chave_atividade': 'chave-$id',
    });
  }

  group('agendamentoParaLembrete', () {
    final DateTime agora = DateTime(2026, 10, 26, 9, 0);

    test('aparece só a partir de 1h antes do início', () {
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[em(1, '10:01:00')], agora),
        isNull,
      );
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '10:00:00'),
        ], agora)?.id,
        1,
      );
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '09:20:00'),
        ], agora)?.id,
        1,
      );
    });

    test(
      'aguardando some quando o horário termina sem confirmar a chegada',
      () {
        expect(
          agendamentoParaLembrete(<AgendamentoModel>[
            em(1, '08:45:00', fim: '09:10:00'),
          ], agora)?.id,
          1,
        );
        expect(
          agendamentoParaLembrete(<AgendamentoModel>[
            em(1, '08:30:00', fim: '09:00:00'),
          ], agora),
          isNull,
        );
      },
    );

    test('ignora cancelados, sem comparecimento e outros dias', () {
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '09:30:00', status: 'CANCELADO'),
          em(2, '09:30:00', status: 'NO_SHOW'),
          em(3, '09:30:00', data: '2026-10-27'),
        ], agora),
        isNull,
      );
    });

    test('com dois na janela, escolhe o que começa primeiro', () {
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '09:50:00'),
          em(2, '09:15:00'),
        ], agora)?.id,
        2,
      );
    });

    test('o que está acontecendo vem antes do próximo', () {
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '09:15:00'),
          em(2, '08:30:00', fim: '09:00:00', status: 'EM_ATENDIMENTO'),
        ], agora)?.id,
        2,
      );
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(
            1,
            '08:00:00',
            status: 'CONCLUIDO',
            conclusao: '2026-10-26T08:55:00',
          ),
          em(2, '09:30:00'),
        ], agora)?.id,
        2,
      );
    });
  });

  group('estadoDaAtividade', () {
    final DateTime agora = DateTime(2026, 10, 26, 9, 0);

    test('cada status vira um estado da atividade', () {
      expect(
        estadoDaAtividade(em(1, '09:30:00'), agora),
        EstadoAtividade.aguardando,
      );
      expect(
        estadoDaAtividade(em(1, '09:30:00', status: 'CONFIRMADO'), agora),
        EstadoAtividade.confirmado,
      );
      expect(
        estadoDaAtividade(em(1, '08:30:00', status: 'EM_ATENDIMENTO'), agora),
        EstadoAtividade.emAtendimento,
      );
      expect(
        estadoDaAtividade(
          em(
            1,
            '08:00:00',
            status: 'CONCLUIDO',
            conclusao: '2026-10-26T08:50:00',
          ),
          agora,
        ),
        EstadoAtividade.finalizado,
      );
    });

    test('confirmado espera o barbeiro até 30 min depois do fim', () {
      final AgendamentoModel confirmado = em(
        1,
        '08:00:00',
        fim: '08:30:00',
        status: 'CONFIRMADO',
      );
      expect(
        estadoDaAtividade(confirmado, DateTime(2026, 10, 26, 8, 59)),
        EstadoAtividade.confirmado,
      );
      expect(
        estadoDaAtividade(confirmado, DateTime(2026, 10, 26, 9, 0)),
        isNull,
      );
    });

    test('o convite para avaliar fica 15 min depois de concluir', () {
      final AgendamentoModel concluido = em(
        1,
        '08:00:00',
        status: 'CONCLUIDO',
        conclusao: '2026-10-26T08:45:00',
      );
      expect(
        estadoDaAtividade(concluido, DateTime(2026, 10, 26, 8, 59)),
        EstadoAtividade.finalizado,
      );
      expect(
        estadoDaAtividade(concluido, DateTime(2026, 10, 26, 9, 0)),
        isNull,
      );
      expect(
        estadoDaAtividade(em(2, '08:00:00', status: 'CONCLUIDO'), agora),
        isNull,
      );
    });
  });

  group('dadosDaAtividade', () {
    test('manda atributos, estado e datas em milissegundos', () {
      final Map<String, dynamic>? dados = dadosDaAtividade(
        em(
          7,
          '08:30:00',
          fim: '09:15:00',
          status: 'EM_ATENDIMENTO',
          inicioAtendimento: '2026-10-26T08:34:00',
        ),
        DateTime(2026, 10, 26, 9, 0),
      );
      expect(dados, <String, dynamic>{
        'id': 7,
        'servico': 'Corte',
        'barbearia': 'Navalha',
        'profissional': 'Caio Souza',
        'foto': null,
        'chave': 'chave-7',
        'estado': 'emAtendimento',
        'inicio': DateTime(2026, 10, 26, 8, 30).millisecondsSinceEpoch,
        'fim': DateTime(2026, 10, 26, 9, 15).millisecondsSinceEpoch,
        'inicio_atendimento': DateTime(
          2026,
          10,
          26,
          8,
          34,
        ).millisecondsSinceEpoch,
      });
    });

    test('sem agendamento para mostrar, nada', () {
      expect(dadosDaAtividade(null, DateTime(2026, 10, 26)), isNull);
    });
  });

  group('LinkAtividade', () {
    test('lê os links da atividade', () {
      final LinkAtividade? qr = LinkAtividade.ler(
        'razor://agendamento/42/qrcode',
      );
      expect(qr?.idAgendamento, 42);
      expect(qr?.acao, AcaoLink.qrCode);
      expect(
        LinkAtividade.ler('razor://agendamento/42/avaliar')?.acao,
        AcaoLink.avaliar,
      );
      expect(LinkAtividade.ler('razor://agendamento/42')?.acao, AcaoLink.abrir);
    });

    test('ignora links de fora ou sem id', () {
      expect(LinkAtividade.ler('https://agendamento/42/qrcode'), isNull);
      expect(LinkAtividade.ler('razor://barbearia/42'), isNull);
      expect(LinkAtividade.ler('razor://agendamento/abc/qrcode'), isNull);
      expect(LinkAtividade.ler(null), isNull);
    });
  });

  group('dataHoraFim', () {
    test('usa hora_fim e, sem ela, a duração', () {
      expect(
        em(1, '09:00:00', fim: '09:25:00').dataHoraFim,
        DateTime(2026, 10, 26, 9, 25),
      );
      expect(em(1, '09:00:00').dataHoraFim, DateTime(2026, 10, 26, 9, 30));
    });
  });
}
