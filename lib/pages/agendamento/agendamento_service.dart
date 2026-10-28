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
  required List<int> idsBarbeariaServico,
  required String data,
  List<int> ignorar = const <int>[],
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointAgendamentosHorarios,
    parameters: <String, dynamic>{
      'id_barbearia': idBarbearia,
      'id_funcionario_barbearia': idFuncionarioBarbearia,
      // Vários serviços seguidos com o mesmo profissional: a API soma as durações.
      'id_barbearia_servico': idsBarbeariaServico.join(','),
      'data': data,
      // Na edição, os horários da própria reserva aparecem livres.
      if (ignorar.isNotEmpty) 'ignorar': ignorar.join(','),
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

/// Marca vários serviços de uma vez numa ordem de serviço. Cada item traz
/// `id_funcionario_barbearia`, `id_barbearia_servico`, `data_agendamento` e
/// `hora_inicio`; se um não couber, a API não marca nenhum.
Future<AppResponse> criarOrdemServico({
  required int idBarbearia,
  required List<Map<String, dynamic>> itens,
  String? observacao,
}) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointOrdemServico,
    body: <String, dynamic>{
      'id_barbearia': idBarbearia,
      'itens': itens,
      if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
    },
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}

/// Troca serviços, profissionais e horários de uma reserva. Com [idOrdem],
/// edita a ordem; sem ela, o agendamento [idAgendamento] (que vira uma ordem).
/// Cada item traz `id` quando é um serviço que continua. A resposta é a ordem,
/// com `valor_a_pagar` (diferença a pagar) e `valor_estornado`.
Future<AppResponse> editarReserva({
  int? idOrdem,
  required int idAgendamento,
  required List<Map<String, dynamic>> itens,
}) async {
  final AppResponse response = await HttpCache.putHTTPCached(
    endpoint: idOrdem != null
        ? AppEndpoints.endpointOrdemServicoEditar(idOrdem)
        : AppEndpoints.endpointAgendamentoEditar(idAgendamento),
    body: <String, dynamic>{'itens': itens},
  );

  await HttpCache.invalidateContaining('agendamentos');
  return response;
}
