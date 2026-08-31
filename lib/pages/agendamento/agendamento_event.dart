abstract class AgendamentoEvent {}

class AgendamentoLoadEvent extends AgendamentoEvent {
  AgendamentoLoadEvent({this.forceRefresh = false});

  final bool forceRefresh;
}

class AgendamentoSelectServicoEvent extends AgendamentoEvent {
  AgendamentoSelectServicoEvent(this.idServico);

  final int idServico;
}

class AgendamentoSelectFuncionarioEvent extends AgendamentoEvent {
  AgendamentoSelectFuncionarioEvent(this.idFuncionario);

  final int idFuncionario;
}

class AgendamentoSelectDataEvent extends AgendamentoEvent {
  AgendamentoSelectDataEvent(this.data);

  final DateTime data;
}

class AgendamentoSelectHorarioEvent extends AgendamentoEvent {
  AgendamentoSelectHorarioEvent(this.horaInicio);

  final String horaInicio;
}

class AgendamentoSalvarEvent extends AgendamentoEvent {
  AgendamentoSalvarEvent({this.observacao});

  final String? observacao;
}
