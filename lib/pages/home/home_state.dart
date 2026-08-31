import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:muller_package/muller_package.dart';

enum HomeSecaoStatus {
  initial,
  loading,
  success,
  error,
}

class HomeSecao<T> {
  final HomeSecaoStatus status;
  final List<T> itens;
  final ErrorModel errorModel;

  HomeSecao({
    required this.status,
    required this.itens,
    required this.errorModel,
  });

  factory HomeSecao.initial() {
    return HomeSecao<T>(
      status: HomeSecaoStatus.initial,
      itens: <T>[],
      errorModel: ErrorModel.empty(),
    );
  }

  factory HomeSecao.loading() {
    return HomeSecao<T>(
      status: HomeSecaoStatus.loading,
      itens: <T>[],
      errorModel: ErrorModel.empty(),
    );
  }

  factory HomeSecao.success(List<T> itens) {
    return HomeSecao<T>(
      status: HomeSecaoStatus.success,
      itens: itens,
      errorModel: ErrorModel.empty(),
    );
  }

  factory HomeSecao.error(ErrorModel errorModel) {
    return HomeSecao<T>(
      status: HomeSecaoStatus.error,
      itens: <T>[],
      errorModel: errorModel,
    );
  }

  bool get isEmpty {
    return status == HomeSecaoStatus.success && itens.isEmpty;
  }

  bool get isLoading {
    return status == HomeSecaoStatus.loading ||
        status == HomeSecaoStatus.initial;
  }
}

abstract class HomeState {
  ErrorModel errorModel;
  HomeSecao<BarbeariaModel> favoritas;
  HomeSecao<BarbeariaModel> proximas;
  HomeSecao<PromocaoModel> promocoes;
  double? latitude;
  double? longitude;

  HomeState({
    required this.errorModel,
    required this.favoritas,
    required this.proximas,
    required this.promocoes,
    this.latitude,
    this.longitude,
  });

  bool get todasSecoesVazias {
    return favoritas.isEmpty && proximas.isEmpty && promocoes.isEmpty;
  }

  bool get carregando {
    return favoritas.isLoading || proximas.isLoading || promocoes.isLoading;
  }

  HomeState copyWith({
    ErrorModel? errorModel,
    HomeSecao<BarbeariaModel>? favoritas,
    HomeSecao<BarbeariaModel>? proximas,
    HomeSecao<PromocaoModel>? promocoes,
    double? latitude,
    double? longitude,
    bool clearGps = false,
  }) {
    return HomeSuccessState(
      errorModel: errorModel ?? this.errorModel,
      favoritas: favoritas ?? this.favoritas,
      proximas: proximas ?? this.proximas,
      promocoes: promocoes ?? this.promocoes,
      latitude: clearGps ? null : (latitude ?? this.latitude),
      longitude: clearGps ? null : (longitude ?? this.longitude),
    );
  }
}

class HomeInitialState extends HomeState {
  HomeInitialState()
      : super(
          errorModel: ErrorModel.empty(),
          favoritas: HomeSecao<BarbeariaModel>.loading(),
          proximas: HomeSecao<BarbeariaModel>.loading(),
          promocoes: HomeSecao<PromocaoModel>.loading(),
        );
}

class HomeLoadingState extends HomeState {
  HomeLoadingState({
    required super.favoritas,
    required super.proximas,
    required super.promocoes,
    super.latitude,
    super.longitude,
  }) : super(errorModel: ErrorModel.empty());
}

class HomeSuccessState extends HomeState {
  HomeSuccessState({
    required super.favoritas,
    required super.proximas,
    required super.promocoes,
    super.latitude,
    super.longitude,
    ErrorModel? errorModel,
  }) : super(errorModel: errorModel ?? ErrorModel.empty());
}

class HomeErrorState extends HomeState {
  HomeErrorState({
    required super.errorModel,
    required super.favoritas,
    required super.proximas,
    required super.promocoes,
    super.latitude,
    super.longitude,
  });
}
