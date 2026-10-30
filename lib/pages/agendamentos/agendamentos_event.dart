abstract class AgendamentosEvent {}

class AgendamentosLoadEvent extends AgendamentosEvent {
  AgendamentosLoadEvent({this.forceRefresh = false});

  final bool forceRefresh;
}

class AgendamentosLoadMoreEvent extends AgendamentosEvent {}

class AgendamentosCancelEvent extends AgendamentosEvent {
  AgendamentosCancelEvent(this.id, {this.motivo});

  final int id;

  /// Opcional; a barbearia vê.
  final String? motivo;
}

/// Cancela os serviços em aberto de uma ordem de serviço (e estorna o Pix dela).
class AgendamentosCancelOrdemEvent extends AgendamentosEvent {
  AgendamentosCancelOrdemEvent({
    required this.idOrdem,
    required this.idPrimeiro,
    this.motivo,
  });

  final int idOrdem;

  /// Serviço da ordem que mostra o carregamento enquanto cancela.
  final int idPrimeiro;

  final String? motivo;
}
