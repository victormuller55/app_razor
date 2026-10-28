import 'dart:convert';

import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:muller_package/muller_package.dart';

const int agendamentosItensPag = 30;

Future<AppResponse> getAgendamentos({
  int numPag = 0,
  int itensPag = agendamentosItensPag,
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentos,
    parameters: <String, dynamic>{'num_pag': numPag, 'itens_pag': itensPag},
    forceRefresh: forceRefresh,
  );
}

Map<String, dynamic> _corpoCancelamento(String? motivo) {
  final String? texto = motivo?.trim();
  return <String, dynamic>{
    if (texto != null && texto.isNotEmpty) 'motivo': texto,
  };
}

/// Regras de cancelamento e atraso da API; se ela não responder, as padrão.
Future<PoliticaAgendamentoModel> getPoliticaAgendamento() async {
  try {
    final AppResponse response = await HttpCache.getHTTPCached(
      endpoint: AppEndpoints.endpointAgendamentosPolitica,
    );
    return PoliticaAgendamentoModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  } catch (_) {
    return PoliticaAgendamentoModel.padrao;
  }
}

/// Cancela mesmo depois do prazo (fica registrado como fora do prazo, sem multa).
Future<AppResponse> cancelarAgendamento({
  required int id,
  String? motivo,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosCancelar(id),
    body: _corpoCancelamento(motivo),
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Cancela os serviços da ordem que ainda não começaram; a API estorna o Pix da ordem antes.
Future<AppResponse> cancelarOrdemServico({
  required int idOrdem,
  String? motivo,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointOrdemServicoCancelar(idOrdem),
    body: _corpoCancelamento(motivo),
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Nota de 1 a 5 e comentário opcional para a barbearia (uma vez por agendamento).
/// Aparece no perfil da barbearia e entra na nota média.
Future<AppResponse> avaliarAgendamento({
  required int id,
  required int nota,
  String? comentario,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentoAvaliacao(id),
    body: <String, dynamic>{
      'nota': nota,
      if (comentario != null && comentario.trim().isNotEmpty)
        'comentario': comentario.trim(),
    },
  );

  // A agenda mostra a nota e o perfil da barbearia, a média nova.
  await HttpCache.invalidateContaining('agendamentos');
  await HttpCache.invalidateContaining('barbearias');
  return response;
}

/// Nota de 1 a 5 e comentário opcional para o serviço e o profissional (uma vez por agendamento).
/// Só a barbearia vê; não entra na nota média.
Future<AppResponse> avaliarAtendimento({
  required int id,
  required int nota,
  String? comentario,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentoAvaliacaoAtendimento(id),
    body: <String, dynamic>{
      'nota': nota,
      if (comentario != null && comentario.trim().isNotEmpty)
        'comentario': comentario.trim(),
    },
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Avisos ainda não lidos (ex.: "Como foi seu atendimento?"). Sempre da API, sem cache.
Future<AppResponse> getNotificacoesNaoLidas() async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointNotificacoes,
    forceRefresh: true,
  );
}

Future<AppResponse> marcarNotificacaoLida({required int id}) async {
  return HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointNotificacaoLida(id),
    body: const <String, dynamic>{},
  );
}
