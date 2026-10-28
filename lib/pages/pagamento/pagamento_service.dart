import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:muller_package/muller_package.dart';

/// Gera (ou retoma) o Pix do agendamento. A API não cria outro se o anterior ainda vale.
Future<AppResponse> iniciarPagamento({required int idAgendamento}) async {
  return HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentoPagamento(idAgendamento),
    body: const <String, dynamic>{},
  );
}

/// Estado atual do pagamento, confirmado pela API com o Mercado Pago. Nunca vem do cache.
Future<AppResponse> consultarPagamento({required int idAgendamento}) async {
  final AppResponse response = await HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentoPagamento(idAgendamento),
    forceRefresh: true,
  );
  // A lista da agenda mostra o status do pagamento.
  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Gera (ou retoma) o Pix único da ordem de serviço (todos os serviços dela).
Future<AppResponse> iniciarPagamentoOrdem({required int idOrdem}) async {
  return HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointOrdemServicoPagamento(idOrdem),
    body: const <String, dynamic>{},
  );
}

/// Estado do Pix da ordem, confirmado pela API com o Mercado Pago. Nunca vem do cache.
Future<AppResponse> consultarPagamentoOrdem({required int idOrdem}) async {
  final AppResponse response = await HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointOrdemServicoPagamento(idOrdem),
    forceRefresh: true,
  );
  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Paga o Pix de teste (só funciona com a API local no provedor simulado; veja app_ambiente.dart).
Future<AppResponse> simularPagamento({required int idPagamento}) async {
  return HttpCache.postHTTPCached(endpoint: AppEndpoints.endpointDevPagamentoAprovar(idPagamento));
}
