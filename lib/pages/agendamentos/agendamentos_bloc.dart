import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetAgendamentos =
    Future<AppResponse> Function({int numPag, int itensPag, bool forceRefresh});

typedef CancelAgendamento =
    Future<AppResponse> Function({required int id, String? motivo});

typedef CancelOrdem =
    Future<AppResponse> Function({required int idOrdem, String? motivo});

class _AgendamentosEnvelope {
  final List<AgendamentoModel> itens;
  final PaginacaoModel paginacao;

  const _AgendamentosEnvelope({required this.itens, required this.paginacao});
}

class AgendamentosBloc extends Bloc<AgendamentosEvent, AgendamentosState> {
  AgendamentosBloc({
    GetAgendamentos? getLista,
    CancelAgendamento? cancelar,
    CancelOrdem? cancelarOrdem,
  }) : _getAgendamentos = getLista ?? getAgendamentos,
       _cancelAgendamento = cancelar ?? cancelarAgendamento,
       _cancelOrdem = cancelarOrdem ?? cancelarOrdemServico,
       super(AgendamentosInitialState()) {
    on<AgendamentosLoadEvent>(_loadAgendamentos);
    on<AgendamentosLoadMoreEvent>(_loadMoreAgendamentos);
    on<AgendamentosCancelEvent>(_cancelarAgendamento);
    on<AgendamentosCancelOrdemEvent>(_cancelarOrdem);
  }

  final GetAgendamentos _getAgendamentos;
  final CancelAgendamento _cancelAgendamento;
  final CancelOrdem _cancelOrdem;

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
          itens: ordenaAgendamentosMaisAtual(<AgendamentoModel>[
            ...itensAtuais,
            ...envelope.itens,
          ]),
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
  ) {
    return _cancelar(
      emit,
      cancelandoId: event.id,
      mensagem: 'Agendamento cancelado',
      chamada: () async {
        final AppResponse response = await _cancelAgendamento(
          id: event.id,
          motivo: event.motivo,
        );
        return <AgendamentoModel>[
          AgendamentoModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map),
          ),
        ];
      },
    );
  }

  Future<void> _cancelarOrdem(
    AgendamentosCancelOrdemEvent event,
    Emitter<AgendamentosState> emit,
  ) {
    return _cancelar(
      emit,
      cancelandoId: event.idPrimeiro,
      mensagem: 'Ordem de serviço cancelada',
      chamada: () async {
        // A API cancela tudo o que está em aberto e estorna o Pix da ordem.
        final AppResponse response = await _cancelOrdem(
          idOrdem: event.idOrdem,
          motivo: event.motivo,
        );
        final Map<String, dynamic> ordem = Map<String, dynamic>.from(
          jsonDecode(response.body) as Map,
        );
        final dynamic itens = ordem['agendamentos'];
        return (itens is List ? itens : const <dynamic>[])
            .whereType<Map>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  AgendamentoModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      },
    );
  }

  /// O que aconteceu com o dinheiro, conforme a API respondeu: só fala em
  /// devolução quando o Mercado Pago confirmou. Null quando não havia pagamento.
  static String? mensagemReembolso(List<AgendamentoModel> itens) {
    final AgendamentoModel? comReembolso = itens
        .where((AgendamentoModel item) => item.statusReembolso != null)
        .firstOrNull;
    if (comReembolso == null) {
      return null;
    }
    final double? pendente = comReembolso.valorReembolsoPendente;
    final double? confirmado = comReembolso.valorReembolsado;
    return switch (comReembolso.statusReembolso) {
      'PROCESSANDO' || 'SOLICITADO' =>
        pendente == null
            ? 'Reembolso em processamento pelo Mercado Pago'
            : 'Reembolso de ${formataDinheiro(pendente)} em processamento pelo Mercado Pago',
      'CONFIRMADO' =>
        confirmado == null
            ? 'Reembolso confirmado pelo Mercado Pago'
            : 'Reembolso de ${formataDinheiro(confirmado)} confirmado pelo Mercado Pago',
      'FALHOU' =>
        'O Mercado Pago ainda não concluiu o reembolso. O valor não se perde: vamos tentar de novo',
      _ => null,
    };
  }

  /// Cancela um por um; o que já foi cancelado fica, mesmo se um falhar.
  /// Cancela pela [chamada] e troca na lista os agendamentos que ela devolver.
  Future<void> _cancelar(
    Emitter<AgendamentosState> emit, {
    required int cancelandoId,
    required String mensagem,
    required Future<List<AgendamentoModel>> Function() chamada,
  }) async {
    final AgendamentosState current = state;

    if (current is! AgendamentosSuccessState) {
      return;
    }

    List<AgendamentoModel> itens = current.itens;

    emit(
      AgendamentosSuccessState(
        itens: itens,
        paginacao: current.paginacao,
        loadingMore: current.loadingMore,
        cancelandoId: cancelandoId,
      ),
    );

    try {
      final List<AgendamentoModel> devolvidos = await chamada();
      final Map<int?, AgendamentoModel> atualizados = <int?, AgendamentoModel>{
        for (final AgendamentoModel item in devolvidos) item.id: item,
      };
      itens = itens
          .map((AgendamentoModel item) => atualizados[item.id] ?? item)
          .toList();

      emit(
        AgendamentosSuccessState(
          itens: ordenaAgendamentosMaisAtual(itens),
          paginacao: current.paginacao,
        ),
      );
      try {
        final String? reembolso = mensagemReembolso(devolvidos);
        if (reembolso != null &&
            devolvidos.any((item) => item.statusReembolso == 'FALHOU')) {
          showSnackbarWarning(message: '$mensagem. $reembolso');
        } else {
          showSnackbarSuccess(
            message: reembolso == null ? mensagem : '$mensagem. $reembolso',
          );
        }
      } catch (_) {}
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentosSuccessState(
          itens: ordenaAgendamentosMaisAtual(itens),
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
          (Map<dynamic, dynamic> item) =>
              AgendamentoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return _AgendamentosEnvelope(
      itens: ordenaAgendamentosMaisAtual(itens),
      paginacao: PaginacaoModel.fromJson(json),
    );
  }
}
