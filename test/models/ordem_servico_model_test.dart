import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/ordem_servico_model.dart';
import 'package:flutter_test/flutter_test.dart';

AgendamentoModel agendamento(
  int id, {
  String hora = '10:00:00',
  double preco = 30,
  String? ordem,
}) {
  return AgendamentoModel(
    id: id,
    dataAgendamento: '2026-11-02',
    horaInicio: hora,
    status: 'AGENDADO',
    preco: preco,
    idOrdemServico: ordem,
  );
}

void main() {
  test('junta os agendamentos da mesma ordem na posição do primeiro', () {
    final List<Object> linhas = juntaOrdensServico(<AgendamentoModel>[
      agendamento(1, hora: '10:25:00', ordem: '7'),
      agendamento(2, ordem: '7'),
      agendamento(3, hora: '09:00:00'),
    ]);

    expect(linhas.length, 2);
    final OrdemServicoGrupo grupo = linhas.first as OrdemServicoGrupo;
    expect(grupo.itens.map((AgendamentoModel item) => item.id), <int>[2, 1]);
    expect(grupo.total, 60);
    expect(grupo.idApi, 7);
    expect((linhas[1] as AgendamentoModel).id, 3);
  });

  test('ordem com um item só continua como agendamento comum', () {
    final List<Object> linhas = juntaOrdensServico(<AgendamentoModel>[
      agendamento(1, ordem: '7'),
    ]);

    expect(linhas.single, isA<AgendamentoModel>());
  });

  test('lê id_ordem_servico e nota_avaliacao do agendamento', () {
    final AgendamentoModel model = AgendamentoModel.fromJson(<String, dynamic>{
      'id': 1,
      'status': 'CONCLUIDO',
      'id_ordem_servico': 9,
      'nota_avaliacao': 4,
    });

    expect(model.idOrdemServico, '9');
    expect(model.notaAvaliacao, 4);
    expect(model.podeAvaliar, isFalse);
  });

  test('só serviço concluído e ainda sem nota pode ser avaliado', () {
    AgendamentoModel comStatus(String status) =>
        AgendamentoModel.fromJson(<String, dynamic>{'id': 1, 'status': status});

    expect(comStatus('CONCLUIDO').podeAvaliar, isTrue);
    expect(comStatus('AGENDADO').podeAvaliar, isFalse);
    expect(comStatus('CANCELADO').podeAvaliar, isFalse);
  });
}
