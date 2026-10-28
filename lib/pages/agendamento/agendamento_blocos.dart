import 'package:app_razor/models/agendamento_model.dart';

/// Serviços seguidos com o mesmo profissional, num único horário.
///
/// Cada profissional escolhido vira um bloco: os serviços dele são feitos um
/// atrás do outro, somando as durações. Profissionais diferentes pedem
/// horários separados.
class AgendamentoBloco {
  const AgendamentoBloco({
    required this.idFuncionario,
    required this.idsServicos,
    this.data,
    this.horaInicio,
    this.horarios = const <AgendamentoHorarioModel>[],
    this.grades = const <List<AgendamentoHorarioModel>>[],
    this.duracoes = const <int, int>{},
    this.motivoHorarios,
    this.loadingHorarios = false,
  });

  final int idFuncionario;

  /// Na ordem em que serão feitos.
  final List<int> idsServicos;
  final DateTime? data;

  /// Início do primeiro serviço (`HH:mm`).
  final String? horaInicio;

  /// Inícios possíveis para o bloco inteiro.
  final List<AgendamentoHorarioModel> horarios;

  /// Grade da API de cada serviço do bloco, na mesma ordem de [idsServicos].
  final List<List<AgendamentoHorarioModel>> grades;

  /// Duração de cada serviço em minutos, como a API calculou.
  final Map<int, int> duracoes;
  final String? motivoHorarios;
  final bool loadingHorarios;

  bool get completo => data != null && horaInicio != null;

  /// Soma das durações dos serviços do bloco, em minutos.
  int get duracaoTotal => idsServicos.fold<int>(
    0,
    (int soma, int id) => soma + (duracoes[id] ?? 0),
  );

  /// Minutos ocupados pelo bloco no dia, quando o horário já foi escolhido.
  ({int inicio, int fim})? get intervalo {
    final int? inicio = minutosDoDia(horaInicio);
    return inicio == null ? null : (inicio: inicio, fim: inicio + duracaoTotal);
  }

  AgendamentoBloco copyWith({
    List<int>? idsServicos,
    DateTime? data,
    String? horaInicio,
    bool limparHora = false,
    List<AgendamentoHorarioModel>? horarios,
    List<List<AgendamentoHorarioModel>>? grades,
    Map<int, int>? duracoes,
    String? motivoHorarios,
    bool limparMotivo = false,
    bool? loadingHorarios,
  }) {
    return AgendamentoBloco(
      idFuncionario: idFuncionario,
      idsServicos: idsServicos ?? this.idsServicos,
      data: data ?? this.data,
      horaInicio: limparHora ? null : horaInicio ?? this.horaInicio,
      horarios: horarios ?? this.horarios,
      grades: grades ?? this.grades,
      duracoes: duracoes ?? this.duracoes,
      motivoHorarios: limparMotivo
          ? null
          : motivoHorarios ?? this.motivoHorarios,
      loadingHorarios: loadingHorarios ?? this.loadingHorarios,
    );
  }
}

/// Minutos desde a meia-noite de um `HH:mm` (ou `HH:mm:ss`).
int? minutosDoDia(String? hora) {
  if (hora == null || hora.length < 5) {
    return null;
  }

  final int? h = int.tryParse(hora.substring(0, 2));
  final int? m = int.tryParse(hora.substring(3, 5));

  if (h == null || m == null) {
    return null;
  }

  return h * 60 + m;
}

/// `HH:mm` de minutos desde a meia-noite.
String horaDeMinutos(int minutos) {
  final String h = (minutos ~/ 60).toString().padLeft(2, '0');
  final String m = (minutos % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Duração (min) que a API usou para o serviço, pela primeira faixa da grade.
int? duracaoDaGrade(List<AgendamentoHorarioModel> grade) {
  for (final AgendamentoHorarioModel item in grade) {
    final int? inicio = minutosDoDia(item.horaInicio);
    final int? fim = minutosDoDia(item.horaFim);
    if (inicio != null && fim != null && fim > inicio) {
      return fim - inicio;
    }
  }

  return null;
}

/// Agrupa os serviços pelo profissional escolhido para cada um, mantendo a
/// ordem de escolha. Serviço sem profissional fica de fora.
List<({int idFuncionario, List<int> idsServicos})> agrupaPorFuncionario(
  List<int> idsServicos,
  Map<int, int> funcionarioPorServico,
) {
  final Map<int, List<int>> grupos = <int, List<int>>{};

  for (final int idServico in idsServicos) {
    final int? idFuncionario = funcionarioPorServico[idServico];
    if (idFuncionario != null) {
      grupos.putIfAbsent(idFuncionario, () => <int>[]).add(idServico);
    }
  }

  return <({int idFuncionario, List<int> idsServicos})>[
    for (final MapEntry<int, List<int>> grupo in grupos.entries)
      (idFuncionario: grupo.key, idsServicos: grupo.value),
  ];
}

/// Inícios em que cabem todos os serviços do bloco seguidos.
///
/// A API só sabe responder por serviço; cada faixa livre que ela devolve é um
/// pedaço da agenda do profissional sem conflito. Juntando as faixas livres de
/// todos os serviços, um início vale se [duracaoTotal] minutos a partir dele
/// estão inteiros dentro dessa área livre e não batem com [ocupados] (outros
/// blocos do mesmo cliente no mesmo dia).
List<AgendamentoHorarioModel> combinaHorarios({
  required List<List<AgendamentoHorarioModel>> grades,
  required int duracaoTotal,
  List<({int inicio, int fim})> ocupados = const <({int inicio, int fim})>[],
}) {
  if (grades.isEmpty) {
    return const <AgendamentoHorarioModel>[];
  }

  final List<({int inicio, int fim})> livres = <({int inicio, int fim})>[
    for (final List<AgendamentoHorarioModel> grade in grades)
      for (final AgendamentoHorarioModel item in grade)
        if (item.disponivel &&
            minutosDoDia(item.horaInicio) != null &&
            minutosDoDia(item.horaFim) != null)
          (
            inicio: minutosDoDia(item.horaInicio)!,
            fim: minutosDoDia(item.horaFim)!,
          ),
  ]..sort((a, b) => a.inicio.compareTo(b.inicio));

  final List<({int inicio, int fim})> faixas = <({int inicio, int fim})>[];
  for (final ({int inicio, int fim}) livre in livres) {
    if (faixas.isNotEmpty && livre.inicio <= faixas.last.fim) {
      final ({int inicio, int fim}) ultima = faixas.removeLast();
      faixas.add((
        inicio: ultima.inicio,
        fim: livre.fim > ultima.fim ? livre.fim : ultima.fim,
      ));
    } else {
      faixas.add(livre);
    }
  }

  bool cabe(int inicio, int fim) => faixas.any(
    (({int inicio, int fim}) faixa) =>
        faixa.inicio <= inicio && fim <= faixa.fim,
  );

  bool bate(int inicio, int fim) => ocupados.any(
    (({int inicio, int fim}) outro) => inicio < outro.fim && outro.inicio < fim,
  );

  return <AgendamentoHorarioModel>[
    for (final AgendamentoHorarioModel item in grades.first)
      if (minutosDoDia(item.horaInicio) case final int inicio)
        AgendamentoHorarioModel(
          horaInicio: horaDeMinutos(inicio),
          horaFim: horaDeMinutos(inicio + duracaoTotal),
          disponivel:
              cabe(inicio, inicio + duracaoTotal) &&
              !bate(inicio, inicio + duracaoTotal),
        ),
  ];
}
