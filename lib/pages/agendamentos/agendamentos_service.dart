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
    parameters: <String, dynamic>{
      'num_pag': numPag,
      'itens_pag': itensPag,
    },
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
