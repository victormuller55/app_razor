import 'package:app_razor/models/agendamento_model.dart';

/// Ordem de serviço já com os agendamentos dela, na ordem de execução. Os
/// serviços marcados juntos vêm da API com o mesmo `id_ordem_servico` e são
/// pagos com um Pix só.
class OrdemServicoGrupo {
  OrdemServicoGrupo({required this.id, required this.itens});

  final String id;
  final List<AgendamentoModel> itens;

  int? get idApi => int.tryParse(id);

  AgendamentoModel get primeiro => itens.first;

  AgendamentoModel get ultimo => itens.last;

  /// Soma dos itens que não foram cancelados.
  double get total => itens
      .where((AgendamentoModel item) => !item.cancelado)
      .fold<double>(0, (double soma, AgendamentoModel item) {
        return soma + (item.preco ?? 0);
      });

  /// Serviços que entram no Pix da ordem: ainda agendados e não pagos.
  List<AgendamentoModel> get aPagar =>
      itens.where((AgendamentoModel item) => item.podePagarPeloApp).toList();

  /// Ordem paga que ficou mais cara numa edição: só a diferença.
  double? get diferencaAPagar {
    for (final AgendamentoModel item in itens) {
      if (item.valorAPagar != null) {
        return item.valorAPagar;
      }
    }
    return null;
  }

  double get totalAPagar =>
      diferencaAPagar ??
      aPagar.fold<double>(
        0,
        (double soma, AgendamentoModel item) => soma + (item.preco ?? 0),
      );

  /// Serviços que ainda podem ser trocados ou remarcados.
  List<AgendamentoModel> editaveisEm(DateTime agora) =>
      itens.where((AgendamentoModel item) => item.podeEditarEm(agora)).toList();

  int get pagos => itens.where((AgendamentoModel item) => item.pago).length;

  bool get aguardando => itens.any((AgendamentoModel item) => item.aguardando);

  bool get encerrada => itens.every((AgendamentoModel item) => item.encerrado);

  bool get cancelada => itens.every((AgendamentoModel item) => item.cancelado);

  List<AgendamentoModel> get cancelaveis =>
      itens.where((AgendamentoModel item) => item.podeCancelar).toList();
}

/// Junta numa [OrdemServicoGrupo] os agendamentos da mesma ordem, na posição
/// do primeiro deles. Ordem com um item só continua como agendamento comum.
List<Object> juntaOrdensServico(List<AgendamentoModel> itens) {
  final Map<String, List<AgendamentoModel>> porOrdem =
      <String, List<AgendamentoModel>>{};

  for (final AgendamentoModel item in itens) {
    final String? ordem = _ordem(item);
    if (ordem != null) {
      porOrdem.putIfAbsent(ordem, () => <AgendamentoModel>[]).add(item);
    }
  }

  final Set<String> emitidas = <String>{};
  final List<Object> linhas = <Object>[];

  for (final AgendamentoModel item in itens) {
    final String? ordem = _ordem(item);
    final List<AgendamentoModel>? membros = ordem == null
        ? null
        : porOrdem[ordem];

    if (ordem == null || membros == null || membros.length < 2) {
      linhas.add(item);
      continue;
    }

    if (emitidas.add(ordem)) {
      final List<AgendamentoModel> ordenados = List<AgendamentoModel>.from(
        membros,
      )..sort(_porInicio);
      linhas.add(OrdemServicoGrupo(id: ordem, itens: ordenados));
    }
  }

  return linhas;
}

String? _ordem(AgendamentoModel item) {
  final String? id = item.idOrdemServico;
  return id == null || id.isEmpty ? null : id;
}

int _porInicio(AgendamentoModel a, AgendamentoModel b) {
  final DateTime? inicioA = a.dataHora;
  final DateTime? inicioB = b.dataHora;

  if (inicioA == null || inicioB == null) {
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  return inicioA.compareTo(inicioB);
}
