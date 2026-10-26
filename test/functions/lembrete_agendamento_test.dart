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
  }) {
    return AgendamentoModel.fromJson(<String, dynamic>{
      'id': id,
      'data_agendamento': data,
      'hora_inicio': hora,
      'hora_fim': fim,
      'duracao_minutos': 30,
      'status': status,
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

    test('continua durante o serviço e some quando termina', () {
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
    });

    test('ignora cancelados, concluídos e outros dias', () {
      expect(
        agendamentoParaLembrete(<AgendamentoModel>[
          em(1, '09:30:00', status: 'CANCELADO'),
          em(2, '09:30:00', status: 'CONCLUIDO'),
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
