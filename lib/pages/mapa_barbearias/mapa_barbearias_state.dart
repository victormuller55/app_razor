import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

abstract class MapaBarbeariasState {
  List<BarbeariaModel> get itens => const <BarbeariaModel>[];
  ErrorModel get errorModel => ErrorModel.empty();
}

class MapaBarbeariasInitialState extends MapaBarbeariasState {}

class MapaBarbeariasLoadingState extends MapaBarbeariasState {}

class MapaBarbeariasSuccessState extends MapaBarbeariasState {
  MapaBarbeariasSuccessState({
    required this.itens,
    required this.paginacao,
  });

  @override
  final List<BarbeariaModel> itens;
  final PaginacaoModel paginacao;
}

class MapaBarbeariasErrorState extends MapaBarbeariasState {
  MapaBarbeariasErrorState({required this.errorModel});

  @override
  final ErrorModel errorModel;
}
