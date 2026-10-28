/// Pagamento de um agendamento pelo app. O status vem sempre da API, que confirma com o
/// Mercado Pago: abrir o QR Code ou voltar para o app nunca decide se foi pago.
enum StatusPagamento {
  pendente('PENDENTE'),
  processando('PROCESSANDO'),
  aprovado('APROVADO'),
  recusado('RECUSADO'),
  cancelado('CANCELADO'),
  expirado('EXPIRADO'),
  reembolsado('REEMBOLSADO'),
  reembolsoParcial('REEMBOLSO_PARCIAL'),
  contestado('CONTESTADO'),
  desconhecido('');

  const StatusPagamento(this.valor);

  final String valor;

  static StatusPagamento from(String? valor) {
    for (final StatusPagamento status in values) {
      if (status.valor == valor && status != desconhecido) {
        return status;
      }
    }
    return desconhecido;
  }
}

class PagamentoModel {
  int? id;
  int? idAgendamento;
  StatusPagamento status;
  String? statusDetalhe;
  double? valorTotal;
  String? metodoPagamento;

  /// Código Pix copia e cola (o QR Code é gerado a partir dele); só vem enquanto está pendente.
  String? pixCopiaCola;
  DateTime? expiraEm;

  /// Quando a API confirmou o pagamento.
  DateTime? dataConfirmacao;

  PagamentoModel({
    this.id,
    this.idAgendamento,
    this.status = StatusPagamento.desconhecido,
    this.statusDetalhe,
    this.valorTotal,
    this.metodoPagamento,
    this.pixCopiaCola,
    this.expiraEm,
    this.dataConfirmacao,
  });

  factory PagamentoModel.fromJson(Map<String, dynamic> json) {
    final dynamic valor = json['valor_total'];
    final String? pix = json['pix_copia_cola']?.toString();
    return PagamentoModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      idAgendamento: json['id_agendamento'] is num
          ? (json['id_agendamento'] as num).toInt()
          : null,
      status: StatusPagamento.from(json['status']?.toString()),
      statusDetalhe: json['status_detalhe']?.toString(),
      valorTotal: valor is num ? valor.toDouble() : double.tryParse('$valor'),
      metodoPagamento: json['metodo_pagamento']?.toString(),
      pixCopiaCola: pix == null || pix.isEmpty ? null : pix,
      expiraEm: DateTime.tryParse(json['expira_em']?.toString() ?? ''),
      dataConfirmacao: DateTime.tryParse(json['data_confirmacao']?.toString() ?? ''),
    );
  }

  bool get aprovado => status == StatusPagamento.aprovado;

  /// Ainda pode virar aprovado: vale continuar consultando.
  bool get emAberto =>
      status == StatusPagamento.pendente || status == StatusPagamento.processando;
}
