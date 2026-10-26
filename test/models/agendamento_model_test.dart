import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgendamentoModel', () {
    test('fromJson mapeia listagem da API', () {
      final AgendamentoModel agendamento =
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': 1,
            'id_barbearia': 8,
            'nome_barbearia': 'Navalha Prime Centro',
            'imagem_barbearia': '/uploads/barbearias/abc.jpg',
            'id_funcionario_barbearia': 20,
            'nome_funcionario': 'João',
            'id_barbearia_servico': 10,
            'nome_servico': 'Corte masculino',
            'data_agendamento': '2026-09-02',
            'hora_inicio': '10:00:00',
            'hora_fim': '10:40:00',
            'status': 'AGENDADO',
            'preco': 45,
            'duracao_minutos': 40,
            'observacao': 'Deixar um pouco nas laterais',
            'imagem_servico': '/uploads/servicos/corte.jpg',
            'endereco_completo': 'Rua X, 450 — Centro, Araucária - PR',
            'latitude': -25.5931,
            'longitude': -49.4102,
          });

      expect(agendamento.id, 1);
      expect(agendamento.nomeServico, 'Corte masculino');
      expect(agendamento.dataLabel, '02/09/2026');
      expect(agendamento.horaLabel, '10:00');
      expect(agendamento.horaFimLabel, '10:40');
      expect(agendamento.periodoLabel, '02/09/2026 · 10:00 – 10:40');
      expect(agendamento.duracaoLabel, '40 min');
      expect(agendamento.statusLabel, 'Agendado');
      expect(agendamento.observacao, 'Deixar um pouco nas laterais');
      expect(
        agendamento.enderecoCompleto,
        'Rua X, 450 — Centro, Araucária - PR',
      );
      expect(agendamento.temRota, isTrue);
      expect(agendamento.podeCancelar, isTrue);
      expect(
        agendamento.imagemBarbearia,
        'http://192.168.0.105:5000/uploads/barbearias/abc.jpg',
      );
      expect(
        agendamento.foto,
        'http://192.168.0.105:5000/uploads/servicos/corte.jpg',
      );
    });

    test('temRota fica verdadeiro só com o nome da barbearia', () {
      final AgendamentoModel agendamento = AgendamentoModel.fromJson(
        <String, dynamic>{
          'id': 2,
          'nome_barbearia': 'Classic Fade Costeira',
          'status': 'AGENDADO',
        },
      );

      expect(agendamento.temRota, isTrue);
    });

    test('ordena o mais atual primeiro', () {
      final List<AgendamentoModel> ordenados = ordenaAgendamentosMaisAtual(
        <AgendamentoModel>[
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': 1,
            'data_agendamento': '2026-08-20',
            'hora_inicio': '10:00:00',
          }),
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': 2,
            'data_agendamento': '2026-09-01',
            'hora_inicio': '14:10:00',
          }),
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': 3,
            'data_agendamento': '2026-09-01',
            'hora_inicio': '09:00:00',
          }),
        ],
      );

      expect(ordenados.map((AgendamentoModel item) => item.id), <int>[2, 3, 1]);
    });

    test('cancelado identifica status CANCELADO', () {
      expect(
        AgendamentoModel.fromJson(<String, dynamic>{
          'status': 'CANCELADO',
        }).cancelado,
        isTrue,
      );
      expect(
        AgendamentoModel.fromJson(<String, dynamic>{
          'status': 'AGENDADO',
        }).cancelado,
        isFalse,
      );
    });

    test('encerrado vale para cancelado, concluído e não compareceu', () {
      bool encerrado(String status) => AgendamentoModel.fromJson(
        <String, dynamic>{'status': status},
      ).encerrado;

      expect(encerrado('CANCELADO'), isTrue);
      expect(encerrado('CONCLUIDO'), isTrue);
      expect(encerrado('NO_SHOW'), isTrue);
      expect(encerrado('AGENDADO'), isFalse);
      expect(encerrado('CONFIRMADO'), isFalse);
    });

    test('agrupa em próximos, hoje, ontem, essa semana e mais antigos', () {
      // Segunda, 26/10/2026, à tarde.
      final DateTime agora = DateTime(2026, 10, 26, 15, 30);
      AgendamentoModel em(int id, String data, [String hora = '10:00:00']) =>
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': id,
            'data_agendamento': data,
            'hora_inicio': hora,
          });

      final List<AgendamentoModel> itens = ordenaAgendamentosMaisAtual(
        <AgendamentoModel>[
          em(1, '2026-10-01'),
          em(2, '2026-10-19'),
          em(3, '2026-10-20'),
          em(4, '2026-10-24'),
          em(5, '2026-10-25', '23:30:00'),
          em(6, '2026-10-26', '08:00:00'),
          em(7, '2026-10-26', '18:00:00'),
          em(8, '2026-10-27'),
          em(9, '2026-10-28'),
          AgendamentoModel.fromJson(<String, dynamic>{'id': 10}),
        ],
      );

      final grupos = agrupaAgendamentos(itens, agora);

      expect(grupos.map((g) => g.grupo), <GrupoAgendamento>[
        GrupoAgendamento.proximos,
        GrupoAgendamento.hoje,
        GrupoAgendamento.ontem,
        GrupoAgendamento.essaSemana,
        GrupoAgendamento.maisAntigos,
      ]);
      List<int?> ids(GrupoAgendamento grupo) => grupos
          .firstWhere((g) => g.grupo == grupo)
          .itens
          .map((AgendamentoModel a) => a.id)
          .toList();

      // Dentro de cada grupo continua o mais recente primeiro.
      expect(ids(GrupoAgendamento.proximos), <int>[9, 8]);
      expect(ids(GrupoAgendamento.hoje), <int>[7, 6]);
      expect(ids(GrupoAgendamento.ontem), <int>[5]);
      expect(ids(GrupoAgendamento.essaSemana), <int>[4, 3]);
      expect(ids(GrupoAgendamento.maisAntigos), <int>[2, 1, 10]);
    });

    test('cancelados vão para o fim e pendentes vêm primeiro no grupo', () {
      final DateTime agora = DateTime(2026, 10, 26, 11, 55);
      AgendamentoModel em(int id, String data, String hora, String status) =>
          AgendamentoModel.fromJson(<String, dynamic>{
            'id': id,
            'data_agendamento': data,
            'hora_inicio': hora,
            'status': status,
          });

      final List<AgendamentoModel> itens = ordenaAgendamentosMaisAtual(
        <AgendamentoModel>[
          em(1, '2026-10-28', '15:00:00', 'CANCELADO'),
          em(2, '2026-10-27', '11:50:00', 'CANCELADO'),
          em(3, '2026-10-27', '10:00:00', 'AGENDADO'),
          em(4, '2026-10-26', '10:00:00', 'CONCLUIDO'),
          em(5, '2026-10-26', '09:00:00', 'AGENDADO'),
          em(6, '2026-09-01', '09:00:00', 'CANCELADO'),
        ],
      );

      final grupos = agrupaAgendamentos(itens, agora);

      expect(grupos.map((g) => g.grupo), <GrupoAgendamento>[
        GrupoAgendamento.proximos,
        GrupoAgendamento.hoje,
        GrupoAgendamento.cancelados,
      ]);
      expect(grupos[0].itens.map((a) => a.id), <int>[3]);
      // O pendente das 9h vem antes do concluído das 10h.
      expect(grupos[1].itens.map((a) => a.id), <int>[5, 4]);
      expect(grupos[2].itens.map((a) => a.id), <int>[1, 2, 6]);
    });

    test('dataRelativaLabel usa ontem, hoje, amanhã ou a data', () {
      final DateTime agora = DateTime(2026, 10, 26, 23, 50);
      String rotulo(String? data) => AgendamentoModel.fromJson(
        <String, dynamic>{'data_agendamento': data},
      ).dataRelativaLabel(agora);

      expect(rotulo('2026-10-25'), 'Ontem');
      expect(rotulo('2026-10-26'), 'Hoje');
      expect(rotulo('2026-10-27'), 'Amanhã');
      expect(rotulo('2026-10-28'), '28/10/2026');
      expect(rotulo('2026-10-24'), '24/10/2026');
      expect(rotulo(null), '');
    });

    test('lista vazia não gera grupos', () {
      expect(
        agrupaAgendamentos(<AgendamentoModel>[], DateTime(2026, 10, 26)),
        isEmpty,
      );
    });
  });

  group('AgendamentoHorarioModel', () {
    test('disponivel vem da API e é verdadeiro quando ausente', () {
      AgendamentoHorarioModel horario(Map<String, dynamic> json) =>
          AgendamentoHorarioModel.fromJson(<String, dynamic>{
            'hora_inicio': '09:15:00',
            'hora_fim': '09:45:00',
            ...json,
          });

      expect(
        horario(<String, dynamic>{'disponivel': false}).disponivel,
        isFalse,
      );
      expect(horario(<String, dynamic>{'disponivel': true}).disponivel, isTrue);
      expect(horario(<String, dynamic>{}).disponivel, isTrue);
      expect(horario(<String, dynamic>{}).label, '09:15');
    });
  });

  group('AgendamentoFuncionarioOpcao', () {
    test('realizaServico usa ids_servicos', () {
      final AgendamentoFuncionarioOpcao funcionario =
          AgendamentoFuncionarioOpcao.fromJson(<String, dynamic>{
            'id': 20,
            'nome': 'João',
            'ids_servicos': <int>[10, 11],
          });

      expect(funcionario.realizaServico(10), isTrue);
      expect(funcionario.realizaServico(99), isFalse);
    });

    test('fromJson resolve a foto do profissional', () {
      final AgendamentoFuncionarioOpcao funcionario =
          AgendamentoFuncionarioOpcao.fromJson(<String, dynamic>{
            'id': 20,
            'nome': 'João',
            'foto': '/uploads/funcionarios/joao.jpg',
            'ids_servicos': <int>[10],
          });

      expect(
        funcionario.foto,
        'http://192.168.0.105:5000/uploads/funcionarios/joao.jpg',
      );
    });
  });
}
