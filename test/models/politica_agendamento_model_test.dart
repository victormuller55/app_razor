import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoliticaAgendamentoModel', () {
    test('lê a política da API', () {
      final PoliticaAgendamentoModel politica =
          PoliticaAgendamentoModel.fromJson(<String, dynamic>{
            'prazo_cancelamento_minutos': 90,
            'tolerancia_atraso_minutos': 10,
            'multa_automatica': false,
            'regras': <String>['Regra A', '  ', 'Regra B'],
          });

      expect(politica.prazoLabel, '90 minutos');
      expect(politica.toleranciaLabel, '10 minutos');
      expect(politica.multaAutomatica, isFalse);
      expect(politica.regrasParaExibir, <String>['Regra A', 'Regra B']);
    });

    test('sem resposta usa 1 hora e 15 minutos, sem multa', () {
      const PoliticaAgendamentoModel politica = PoliticaAgendamentoModel.padrao;

      expect(politica.prazoLabel, '1 hora');
      expect(politica.toleranciaLabel, '15 minutos');
      expect(politica.regrasParaExibir.join(' '), contains('sem multa'));
      expect(
        politica.regrasParaExibir.join(' '),
        contains('Código de Defesa do Consumidor'),
      );
    });

    test('exatamente 1 hora antes ainda está no prazo', () {
      const PoliticaAgendamentoModel politica = PoliticaAgendamentoModel.padrao;
      final DateTime inicio = DateTime(2026, 10, 28, 14);

      expect(
        politica.foraDoPrazo(inicio, DateTime(2026, 10, 28, 12, 30)),
        isFalse,
      );
      expect(politica.foraDoPrazo(inicio, DateTime(2026, 10, 28, 13)), isFalse);
      expect(
        politica.foraDoPrazo(inicio, DateTime(2026, 10, 28, 13, 0, 1)),
        isTrue,
      );
      expect(
        politica.foraDoPrazo(null, DateTime(2026, 10, 28, 13, 30)),
        isFalse,
      );
    });
  });

  group('cancelamento no agendamento', () {
    AgendamentoModel cancelado(Map<String, dynamic> dados) {
      return AgendamentoModel.fromJson(<String, dynamic>{
        'id': 1,
        'status': 'CANCELADO',
        ...dados,
      });
    }

    test('diferencia quem cancelou e o cancelamento fora do prazo', () {
      expect(
        cancelado(<String, dynamic>{
          'cancelado_por': 'CLIENTE',
        }).cancelamentoLabel,
        'Você cancelou',
      );
      expect(
        cancelado(<String, dynamic>{
          'cancelado_por': 'CLIENTE',
          'cancelamento_tardio': true,
        }).cancelamentoLabel,
        'Você cancelou fora do prazo',
      );

      final AgendamentoModel pelaBarbearia = cancelado(<String, dynamic>{
        'cancelado_por': 'BARBEARIA',
        'motivo_cancelamento': 'Barbeiro doente',
        'data_cancelamento': '2026-10-28T10:00:00',
      });
      expect(pelaBarbearia.canceladoPelaBarbearia, isTrue);
      expect(pelaBarbearia.cancelamentoLabel, 'Cancelado pela barbearia');
      expect(pelaBarbearia.motivoCancelamento, 'Barbeiro doente');
      expect(pelaBarbearia.dataCancelamento, '2026-10-28T10:00:00');
    });

    test('cancelamentos antigos, sem origem, não inventam quem cancelou', () {
      expect(cancelado(<String, dynamic>{}).cancelamentoLabel, isNull);
      expect(
        AgendamentoModel.fromJson(<String, dynamic>{
          'status': 'AGENDADO',
        }).cancelamentoLabel,
        isNull,
      );
    });

    test('não comparecimento traz quando foi registrado', () {
      final AgendamentoModel faltou = AgendamentoModel.fromJson(
        <String, dynamic>{
          'status': 'NO_SHOW',
          'data_no_show': '2026-10-28T14:15:00',
        },
      );
      expect(faltou.statusLabel, 'Não compareceu');
      expect(faltou.dataNoShow, '2026-10-28T14:15:00');
    });

    test('reembolso recusado não aparece como dinheiro perdido', () {
      final AgendamentoModel item = cancelado(<String, dynamic>{
        'status_reembolso': 'FALHOU',
      });
      expect(item.reembolsoLabel, 'Reembolso em nova tentativa');
    });
  });
}
