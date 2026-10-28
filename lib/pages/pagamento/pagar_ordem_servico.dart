import 'package:app_razor/models/ordem_servico_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_modal.dart';
import 'package:flutter/material.dart';

/// Paga a ordem de serviço com um Pix só, somando os serviços em aberto.
/// Devolve true se a API confirmou o pagamento.
Future<bool> pagarOrdemServico({
  required BuildContext context,
  required OrdemServicoGrupo ordem,
}) async {
  final int? idOrdem = ordem.idApi;
  if (idOrdem == null || ordem.aPagar.isEmpty) {
    return false;
  }

  return showPagamentoOrdemModal(
    context: context,
    idOrdem: idOrdem,
    servicos: ordem.aPagar.length,
    valorPrevisto: ordem.totalAPagar,
  );
}
