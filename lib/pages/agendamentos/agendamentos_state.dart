import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class AgendamentosState {
  ErrorModel errorModel;
  List<AgendamentoModel> itens;
  PaginacaoModel paginacao;
  bool loadingMore;
  int? cancelandoId;

  AgendamentosState({
    required this.errorModel,
    required this.itens,
    required this.paginacao,
    required this.loadingMore,
    this.cancelandoId,
  });
}

class AgendamentosInitialState extends AgendamentosState {
  AgendamentosInitialState()
      : super(
          errorModel: ErrorModel.empty(),
          itens: const <AgendamentoModel>[],
          paginacao: PaginacaoModel.empty(),
          loadingMore: false,
        );
}

class AgendamentosLoadingState extends AgendamentosState {
  AgendamentosLoadingState()
      : super(
          errorModel: ErrorModel.empty(),
          itens: const <AgendamentoModel>[],
          paginacao: PaginacaoModel.empty(),
          loadingMore: false,
        );
}

class AgendamentosSuccessState extends AgendamentosState {
  AgendamentosSuccessState({
    required super.itens,
    required super.paginacao,
    super.loadingMore = false,
    super.cancelandoId,
  }) : super(errorModel: ErrorModel.empty());
}

class AgendamentosErrorState extends AgendamentosState {
  AgendamentosErrorState({required super.errorModel})
      : super(
          itens: const <AgendamentoModel>[],
          paginacao: PaginacaoModel.empty(),
          loadingMore: false,
        );
}
