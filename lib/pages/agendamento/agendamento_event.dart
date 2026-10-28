abstract class AgendamentoEvent {}

class AgendamentoLoadEvent extends AgendamentoEvent {
  AgendamentoLoadEvent({this.forceRefresh = false});

  final bool forceRefresh;
}

/// Marca ou desmarca um serviço; os marcados são feitos na ordem da escolha.
class AgendamentoToggleServicoEvent extends AgendamentoEvent {
  AgendamentoToggleServicoEvent(this.idServico);

  final int idServico;
}

/// Escolhe o profissional de [idServico]; sem ele, de todos os serviços
/// marcados que o profissional faz.
class AgendamentoSelectFuncionarioEvent extends AgendamentoEvent {
  AgendamentoSelectFuncionarioEvent(this.idFuncionario, {this.idServico});

  final int idFuncionario;
  final int? idServico;
}

class AgendamentoSelectDataEvent extends AgendamentoEvent {
  AgendamentoSelectDataEvent({required this.idFuncionario, required this.data});

  final int idFuncionario;
  final DateTime data;
}

class AgendamentoSelectHorarioEvent extends AgendamentoEvent {
  AgendamentoSelectHorarioEvent({
    required this.idFuncionario,
    required this.horaInicio,
  });

  final int idFuncionario;
  final String horaInicio;
}

class AgendamentoSalvarEvent extends AgendamentoEvent {
  AgendamentoSalvarEvent({this.observacao});

  final String? observacao;
}
