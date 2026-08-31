import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:muller_package/muller_package.dart';

Future<AppResponse> getAgendamentoContexto({
  required int idBarbearia,
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosContexto,
    parameters: <String, dynamic>{'id_barbearia': idBarbearia},
    forceRefresh: forceRefresh,
  );
}

Future<AppResponse> getHorariosDisponiveis({
  required int idBarbearia,
  required int idFuncionarioBarbearia,
  required int idBarbeariaServico,
  required String data,
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosHorarios,
    parameters: <String, dynamic>{
      'id_barbearia': idBarbearia,
      'id_funcionario_barbearia': idFuncionarioBarbearia,
      'id_barbearia_servico': idBarbeariaServico,
      'data': data,
    },
    forceRefresh: forceRefresh,
  );
}

Future<AppResponse> criarAgendamento({
  required int idBarbearia,
  required int idFuncionarioBarbearia,
  required int idBarbeariaServico,
  required String dataAgendamento,
  required String horaInicio,
  String? observacao,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosNovo,
    body: <String, dynamic>{
      'id_barbearia': idBarbearia,
      'id_funcionario_barbearia': idFuncionarioBarbearia,
      'id_barbearia_servico': idBarbeariaServico,
      'data_agendamento': dataAgendamento,
      'hora_inicio': horaInicio,
      if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
    },
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}
