import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgendamentoModel', () {
    test('fromJson mapeia listagem da API', () {
      final AgendamentoModel agendamento = AgendamentoModel.fromJson(
        <String, dynamic>{
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
        },
      );

      expect(agendamento.id, 1);
      expect(agendamento.nomeServico, 'Corte masculino');
      expect(agendamento.dataLabel, '02/09/2026');
      expect(agendamento.horaLabel, '10:00');
      expect(agendamento.horaFimLabel, '10:40');
      expect(agendamento.periodoLabel, '02/09/2026 · 10:00 – 10:40');
      expect(agendamento.duracaoLabel, '40 min');
      expect(agendamento.statusLabel, 'Agendado');
      expect(agendamento.observacao, 'Deixar um pouco nas laterais');
      expect(agendamento.enderecoCompleto, 'Rua X, 450 — Centro, Araucária - PR');
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
  });

  group('AgendamentoFuncionarioOpcao', () {
    test('realizaServico usa ids_servicos', () {
      final AgendamentoFuncionarioOpcao funcionario =
          AgendamentoFuncionarioOpcao.fromJson(
        <String, dynamic>{
          'id': 20,
          'nome': 'João',
          'ids_servicos': <int>[10, 11],
        },
      );

      expect(funcionario.realizaServico(10), isTrue);
      expect(funcionario.realizaServico(99), isFalse);
    });

    test('fromJson resolve a foto do profissional', () {
      final AgendamentoFuncionarioOpcao funcionario =
          AgendamentoFuncionarioOpcao.fromJson(
        <String, dynamic>{
          'id': 20,
          'nome': 'João',
          'foto': '/uploads/funcionarios/joao.jpg',
          'ids_servicos': <int>[10],
        },
      );

      expect(
        funcionario.foto,
        'http://192.168.0.105:5000/uploads/funcionarios/joao.jpg',
      );
    });
  });
}
