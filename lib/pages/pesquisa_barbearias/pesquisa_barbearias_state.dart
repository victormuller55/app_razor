import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:muller_package/muller_package.dart';

abstract class PesquisaBarbeariasState {
  final List<BarbeariaModel> itens;
  final PaginacaoModel paginacao;
  final BarbeariasFiltros filtros;
  final bool loadingMore;
  final String? avisoLocalizacao;
  final double? latitude;
  final double? longitude;
  final ErrorModel errorModel;

  PesquisaBarbeariasState({
    required this.itens,
    required this.paginacao,
    required this.filtros,
    required this.loadingMore,
    required this.avisoLocalizacao,
    required this.latitude,
    required this.longitude,
    required this.errorModel,
  });
}

class PesquisaInicialState extends PesquisaBarbeariasState {
  PesquisaInicialState()
      : super(
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          filtros: BarbeariasFiltros.empty(),
          loadingMore: false,
          avisoLocalizacao: null,
          latitude: null,
          longitude: null,
          errorModel: ErrorModel.empty(),
        );
}

class PesquisaLoadingState extends PesquisaBarbeariasState {
  PesquisaLoadingState({
    required super.filtros,
    super.avisoLocalizacao,
    super.latitude,
    super.longitude,
  }) : super(
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          loadingMore: false,
          errorModel: ErrorModel.empty(),
        );
}

class PesquisaSuccessState extends PesquisaBarbeariasState {
  PesquisaSuccessState({
    required super.itens,
    required super.paginacao,
    required super.filtros,
    super.loadingMore = false,
    super.avisoLocalizacao,
    super.latitude,
    super.longitude,
  }) : super(errorModel: ErrorModel.empty());
}

class PesquisaErrorState extends PesquisaBarbeariasState {
  PesquisaErrorState({
    required super.errorModel,
    required super.filtros,
    super.avisoLocalizacao,
    super.latitude,
    super.longitude,
  }) : super(
          itens: const <BarbeariaModel>[],
          paginacao: PaginacaoModel.empty(),
          loadingMore: false,
        );
}
