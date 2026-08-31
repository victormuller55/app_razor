import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:muller_package/muller_package.dart';

abstract class BarbeariasState {
  ErrorModel errorModel;
  List<BarbeariaModel> itens;
  PaginacaoModel paginacao;
  BarbeariasFiltros filtros;
  bool loadingMore;
  double? latitude;
  double? longitude;

  BarbeariasState({
    required this.errorModel,
    required this.itens,
    required this.paginacao,
    required this.filtros,
    required this.loadingMore,
    this.latitude,
    this.longitude,
  });
}

class BarbeariasInitialState extends BarbeariasState {
  BarbeariasInitialState()
      : super(
          errorModel: ErrorModel.empty(),
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          filtros: BarbeariasFiltros.empty(),
          loadingMore: false,
        );
}

class BarbeariasLoadingState extends BarbeariasState {
  BarbeariasLoadingState({
    BarbeariasFiltros? filtros,
    super.latitude,
    super.longitude,
  }) : super(
          errorModel: ErrorModel.empty(),
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          filtros: filtros ?? BarbeariasFiltros.empty(),
          loadingMore: false,
        );
}

class BarbeariasSuccessState extends BarbeariasState {
  BarbeariasSuccessState({
    required super.itens,
    required super.paginacao,
    BarbeariasFiltros? filtros,
    super.loadingMore = false,
    super.latitude,
    super.longitude,
  }) : super(
          errorModel: ErrorModel.empty(),
          filtros: filtros ?? BarbeariasFiltros.empty(),
        );
}

class BarbeariasErrorState extends BarbeariasState {
  BarbeariasErrorState({
    required super.errorModel,
    BarbeariasFiltros? filtros,
    super.latitude,
    super.longitude,
  }) : super(
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          filtros: filtros ?? BarbeariasFiltros.empty(),
          loadingMore: false,
        );
}
