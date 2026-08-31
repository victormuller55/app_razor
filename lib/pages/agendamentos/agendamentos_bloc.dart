import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetAgendamentos = Future<AppResponse> Function({
  int numPag,
  int itensPag,
  bool forceRefresh,
});

typedef CancelAgendamento = Future<AppResponse> Function({required int id});

class _AgendamentosEnvelope {
  final List<AgendamentoModel> itens;
  final PaginacaoModel paginacao;

  const _AgendamentosEnvelope({
    required this.itens,
    required this.paginacao,
  });
}

class AgendamentosBloc extends Bloc<AgendamentosEvent, AgendamentosState> {
  AgendamentosBloc({
    GetAgendamentos? getLista,
    CancelAgendamento? cancelar,
  })  : _getAgendamentos = getLista ?? getAgendamentos,
        _cancelAgendamento = cancelar ?? cancelarAgendamento,
        super(AgendamentosInitialState()) {
    on<AgendamentosLoadEvent>(_loadAgendamentos);
    on<AgendamentosLoadMoreEvent>(_loadMoreAgendamentos);
    on<AgendamentosCancelEvent>(_cancelarAgendamento);
  }

  final GetAgendamentos _getAgendamentos;
  final CancelAgendamento _cancelAgendamento;

  Future<void> _loadAgendamentos(
    AgendamentosLoadEvent event,
    Emitter<AgendamentosState> emit,
  ) async {
    final bool manterLista =
        event.forceRefresh && state is AgendamentosSuccessState;

    if (!manterLista) {
      emit(AgendamentosLoadingState());
    }

    try {
      final AppResponse response = await _getAgendamentos(
        numPag: 0,
        itensPag: agendamentosItensPag,
        forceRefresh: event.forceRefresh,
      );
      final _AgendamentosEnvelope envelope = _parseEnvelope(response);

      emit(
        AgendamentosSuccessState(
          itens: envelope.itens,
          paginacao: envelope.paginacao,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(AgendamentosErrorState(errorModel: errorModel));
      _notifyErro(errorModel);
    }
  }

  Future<void> _loadMoreAgendamentos(
    AgendamentosLoadMoreEvent event,
    Emitter<AgendamentosState> emit,
  ) async {
    final AgendamentosState current = state;

    if (current is! AgendamentosSuccessState) {
      return;
    }

    if (current.loadingMore || !current.paginacao.hasMore) {
      return;
    }

    final List<AgendamentoModel> itensAtuais = current.itens;
    final int proximaPagina = current.paginacao.numPag + 1;

    emit(
      AgendamentosSuccessState(
        itens: itensAtuais,
        paginacao: current.paginacao,
        loadingMore: true,
      ),
    );

    try {
      final AppResponse response = await _getAgendamentos(
        numPag: proximaPagina,
        itensPag: agendamentosItensPag,
        forceRefresh: false,
      );
      final _AgendamentosEnvelope envelope = _parseEnvelope(response);

      emit(
        AgendamentosSuccessState(
          itens: <AgendamentoModel>[...itensAtuais, ...envelope.itens],
          paginacao: envelope.paginacao,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentosSuccessState(
          itens: itensAtuais,
          paginacao: current.paginacao,
        ),
      );
      _notifyErro(errorModel);
    }
  }

  Future<void> _cancelarAgendamento(
    AgendamentosCancelEvent event,
    Emitter<AgendamentosState> emit,
  ) async {
    final AgendamentosState current = state;

    if (current is! AgendamentosSuccessState) {
      return;
    }

    emit(
      AgendamentosSuccessState(
        itens: current.itens,
        paginacao: current.paginacao,
        loadingMore: current.loadingMore,
        cancelandoId: event.id,
      ),
    );

    try {
      final AppResponse response = await _cancelAgendamento(id: event.id);
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final AgendamentoModel atualizado = AgendamentoModel.fromJson(json);
      final List<AgendamentoModel> itens = current.itens
          .map(
            (AgendamentoModel item) =>
                item.id == atualizado.id ? atualizado : item,
          )
          .toList();

      emit(
        AgendamentosSuccessState(
          itens: itens,
          paginacao: current.paginacao,
        ),
      );
      try {
        showSnackbarSuccess(message: 'Agendamento cancelado');
      } catch (_) {}
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentosSuccessState(
          itens: current.itens,
          paginacao: current.paginacao,
        ),
      );
      _notifyErro(errorModel);
    }
  }

  void _notifyErro(ErrorModel errorModel) {
    try {
      if (AppContext.navigatorKey.currentContext == null) {
        return;
      }

      showSnackbarError(message: errorModel.mensagem);
    } catch (_) {}
  }

  _AgendamentosEnvelope _parseEnvelope(AppResponse response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const FormatException('Resposta inválida da API');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final dynamic itensJson = json['itens'];

    if (itensJson is! List) {
      throw const FormatException('Resposta inválida da API');
    }

    final List<AgendamentoModel> itens = itensJson
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) => AgendamentoModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return _AgendamentosEnvelope(
      itens: itens,
      paginacao: PaginacaoModel.fromJson(json),
    );
  }
}
