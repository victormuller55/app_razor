import 'package:app_razor/models/pagamento_model.dart';

enum EtapaPagamento {
  /// Antes de gerar o Pix: mostra o valor.
  inicio,
  preparando,

  /// QR Code e código Pix na tela, esperando o cliente pagar no banco.
  aguardandoPix,

  /// Conferindo com a API.
  verificando,

  /// O Mercado Pago está analisando o pagamento.
  processando,
  aprovado,
  recusado,

  /// O Pix foi cancelado (ex.: o agendamento foi cancelado).
  cancelado,

  /// O Pix venceu sem pagamento.
  expirado,
  reembolsado,
  erroConexao,
  erro,
}

class PagamentoState {
  PagamentoState({required this.etapa, this.pagamento, this.mensagem});

  PagamentoState.inicio() : this(etapa: EtapaPagamento.inicio);

  final EtapaPagamento etapa;
  final PagamentoModel? pagamento;
  final String? mensagem;

  bool get ocupado => etapa == EtapaPagamento.preparando;

  PagamentoState copiar({required EtapaPagamento etapa, String? mensagem}) {
    return PagamentoState(etapa: etapa, pagamento: pagamento, mensagem: mensagem);
  }
}
