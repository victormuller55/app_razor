abstract class AgendamentosEvent {}

class AgendamentosLoadEvent extends AgendamentosEvent {
  AgendamentosLoadEvent({this.forceRefresh = false});

  final bool forceRefresh;
}

class AgendamentosLoadMoreEvent extends AgendamentosEvent {}

class AgendamentosCancelEvent extends AgendamentosEvent {
  AgendamentosCancelEvent(this.id);

  final int id;
}
