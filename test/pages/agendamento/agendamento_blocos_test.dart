import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_blocos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grade de 15 em 15 minutos, como a API monta, entre [de] e [ate] (`HH:mm`).
List<AgendamentoHorarioModel> grade({
  required String de,
  required String ate,
  required int duracao,
  Set<String> ocupados = const <String>{},
}) {
  final List<AgendamentoHorarioModel> itens = <AgendamentoHorarioModel>[];
  for (int t = minutosDoDia(de)!; t + duracao <= minutosDoDia(ate)!; t += 15) {
    itens.add(
      AgendamentoHorarioModel(
        horaInicio: '${horaDeMinutos(t)}:00',
        horaFim: '${horaDeMinutos(t + duracao)}:00',
        disponivel: !ocupados.contains(horaDeMinutos(t)),
      ),
    );
  }
  return itens;
}

Set<String> livres(List<AgendamentoHorarioModel> horarios) => horarios
    .where((AgendamentoHorarioModel item) => item.disponivel)
    .map((AgendamentoHorarioModel item) => item.horaInicio!)
    .toSet();

void main() {
  group('combinaHorarios', () {
    test('só oferece inícios em que os serviços somados cabem até o fim', () {
      final List<AgendamentoHorarioModel> horarios = combinaHorarios(
        grades: <List<AgendamentoHorarioModel>>[
          grade(de: '09:00', ate: '10:30', duracao: 25),
          grade(de: '09:00', ate: '10:30', duracao: 40),
        ],
        duracaoTotal: 65,
      );

      // 09:00 + 65 = 10:05; 09:15 + 65 = 10:20; 09:30 + 65 = 10:35 passa do fim.
      expect(livres(horarios), <String>{'09:00', '09:15'});
      expect(horarios.first.horaFim, '10:05');
    });

    test('recusa início que esbarra num horário ocupado do profissional', () {
      // Ocupado das 10:00 às 10:30: as faixas que encostam nisso vêm indisponíveis.
      final Set<String> ocupados25 = <String>{'09:45', '10:00', '10:15'};
      final Set<String> ocupados40 = <String>{
        '09:30',
        '09:45',
        '10:00',
        '10:15',
      };

      final List<AgendamentoHorarioModel> horarios = combinaHorarios(
        grades: <List<AgendamentoHorarioModel>>[
          grade(de: '09:00', ate: '12:00', duracao: 25, ocupados: ocupados25),
          grade(de: '09:00', ate: '12:00', duracao: 40, ocupados: ocupados40),
        ],
        duracaoTotal: 65,
      );

      expect(livres(horarios).contains('09:00'), isFalse);
      expect(livres(horarios).contains('10:30'), isTrue);
    });

    test('não deixa dois blocos do mesmo cliente se sobreporem', () {
      final List<AgendamentoHorarioModel> horarios = combinaHorarios(
        grades: <List<AgendamentoHorarioModel>>[
          grade(de: '09:00', ate: '11:00', duracao: 30),
        ],
        duracaoTotal: 30,
        ocupados: <({int inicio, int fim})>[
          (inicio: minutosDoDia('09:30')!, fim: minutosDoDia('10:00')!),
        ],
      );

      expect(livres(horarios).contains('09:15'), isFalse);
      expect(livres(horarios).contains('09:30'), isFalse);
      expect(livres(horarios).contains('09:00'), isTrue);
      expect(livres(horarios).contains('10:00'), isTrue);
    });
  });

  test('agrupaPorFuncionario junta os serviços de cada profissional', () {
    final List<({int idFuncionario, List<int> idsServicos})> grupos =
        agrupaPorFuncionario(<int>[1, 2, 3], <int, int>{1: 10, 2: 20, 3: 10});

    expect(grupos.length, 2);
    expect(grupos[0].idFuncionario, 10);
    expect(grupos[0].idsServicos, <int>[1, 3]);
    expect(grupos[1].idsServicos, <int>[2]);
  });

  test('duracaoDaGrade usa a primeira faixa válida', () {
    expect(duracaoDaGrade(grade(de: '09:00', ate: '10:00', duracao: 25)), 25);
    expect(duracaoDaGrade(const <AgendamentoHorarioModel>[]), isNull);
  });
}
