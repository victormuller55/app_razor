import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
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

Future<AppResponse> cancelarAgendamento({required int id}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosCancelar(id),
    body: const <String, dynamic>{},
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Cancela os serviços da ordem que ainda não começaram; a API estorna o Pix da ordem antes.
Future<AppResponse> cancelarOrdemServico({required int idOrdem}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointOrdemServicoCancelar(idOrdem),
    body: const <String, dynamic>{},
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Nota de 1 a 5 e comentário opcional para um serviço concluído (uma vez por agendamento).
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
