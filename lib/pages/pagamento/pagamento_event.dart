abstract class PagamentoEvent {}

/// Gera (ou retoma) o Pix do agendamento.
class PagamentoIniciarEvent extends PagamentoEvent {}

/// O app voltou para a frente (ex.: depois de pagar no app do banco): confere com a API.
class PagamentoRetornouEvent extends PagamentoEvent {}

/// Confere o estado de novo (automático enquanto o Pix está aberto, ou pelo botão).
class PagamentoConsultarEvent extends PagamentoEvent {}
