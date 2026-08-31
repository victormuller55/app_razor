import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:app_razor/pages/home/home_event.dart';
import 'package:app_razor/pages/home/home_service.dart';
import 'package:app_razor/pages/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetBarbeariasFavoritas = Future<AppResponse> Function({
  double? latitude,
  double? longitude,
  bool forceRefresh,
});

typedef GetBarbeariasProximas = Future<AppResponse> Function({
  required double latitude,
  required double longitude,
  bool forceRefresh,
});

typedef GetPromocoesProximas = Future<AppResponse> Function({
  required double latitude,
  required double longitude,
  bool forceRefresh,
});

typedef GetGpsPosition = Future<GpsPosition> Function();

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    GetBarbeariasFavoritas? getFavoritas,
    GetBarbeariasProximas? getProximas,
    GetPromocoesProximas? getPromocoes,
    GetGpsPosition? getGps,
  })  : _getFavoritas = getFavoritas ?? getBarbeariasFavoritas,
        _getProximas = getProximas ?? getBarbeariasProximas,
        _getPromocoes = getPromocoes ?? getPromocoesProximas,
        _getGps = getGps ?? getCurrentGps,
        super(HomeInitialState()) {
    on<HomeLoadEvent>(_loadHome);
  }

  final GetBarbeariasFavoritas _getFavoritas;
  final GetBarbeariasProximas _getProximas;
  final GetPromocoesProximas _getPromocoes;
  final GetGpsPosition _getGps;

  Future<void> _loadHome(
    HomeLoadEvent event,
    Emitter<HomeState> emit,
  ) async {
    HomeState current = HomeLoadingState(
      favoritas: HomeSecao<BarbeariaModel>.loading(),
      proximas: HomeSecao<BarbeariaModel>.loading(),
      promocoes: HomeSecao<PromocaoModel>.loading(),
      latitude: state.latitude,
      longitude: state.longitude,
    );

    emit(current);

    void emitNext(HomeState Function(HomeState state) update) {
      current = update(current);
      emit(current);
    }

    await Future.wait<void>(<Future<void>>[
      _loadFavoritas(
        forceRefresh: event.forceRefresh,
        emitNext: emitNext,
      ),
      _loadSecoesComGps(
        forceRefresh: event.forceRefresh,
        emitNext: emitNext,
      ),
    ]);
  }

  Future<void> _loadFavoritas({
    required bool forceRefresh,
    required void Function(HomeState Function(HomeState state)) emitNext,
  }) async {
    try {
      final AppResponse response = await _getFavoritas(
        forceRefresh: forceRefresh,
      );

      emitNext((HomeState state) {
        return state.copyWith(
          favoritas: HomeSecao<BarbeariaModel>.success(
            _parseBarbearias(response),
          ),
        );
      });
    } catch (e) {
      emitNext((HomeState state) {
        return state.copyWith(
          favoritas: HomeSecao<BarbeariaModel>.error(errorModelFromApi(e)),
        );
      });
    }
  }

  Future<void> _loadSecoesComGps({
    required bool forceRefresh,
    required void Function(HomeState Function(HomeState state)) emitNext,
  }) async {
    late final GpsPosition gps;

    try {
      gps = await _getGps();
    } catch (e) {
      final ErrorModel errorModel = gpsErrorModel(e);

      emitNext((HomeState state) {
        return state.copyWith(
          proximas: HomeSecao<BarbeariaModel>.error(errorModel),
          promocoes: HomeSecao<PromocaoModel>.error(errorModel),
          clearGps: true,
        );
      });
      return;
    }

    emitNext((HomeState state) {
      return state.copyWith(
        latitude: gps.latitude,
        longitude: gps.longitude,
      );
    });

    await Future.wait<void>(<Future<void>>[
      _loadProximas(
        latitude: gps.latitude,
        longitude: gps.longitude,
        forceRefresh: forceRefresh,
        emitNext: emitNext,
      ),
      _loadPromocoes(
        latitude: gps.latitude,
        longitude: gps.longitude,
        forceRefresh: forceRefresh,
        emitNext: emitNext,
      ),
    ]);
  }

  Future<void> _loadProximas({
    required double latitude,
    required double longitude,
    required bool forceRefresh,
    required void Function(HomeState Function(HomeState state)) emitNext,
  }) async {
    try {
      final AppResponse response = await _getProximas(
        latitude: latitude,
        longitude: longitude,
        forceRefresh: forceRefresh,
      );

      emitNext((HomeState state) {
        return state.copyWith(
          proximas: HomeSecao<BarbeariaModel>.success(
            _parseBarbearias(response),
          ),
        );
      });
    } catch (e) {
      emitNext((HomeState state) {
        return state.copyWith(
          proximas: HomeSecao<BarbeariaModel>.error(errorModelFromApi(e)),
        );
      });
    }
  }

  Future<void> _loadPromocoes({
    required double latitude,
    required double longitude,
    required bool forceRefresh,
    required void Function(HomeState Function(HomeState state)) emitNext,
  }) async {
    try {
      final AppResponse response = await _getPromocoes(
        latitude: latitude,
        longitude: longitude,
        forceRefresh: forceRefresh,
      );

      emitNext((HomeState state) {
        return state.copyWith(
          promocoes: HomeSecao<PromocaoModel>.success(
            _parsePromocoes(response),
          ),
        );
      });
    } catch (e) {
      emitNext((HomeState state) {
        return state.copyWith(
          promocoes: HomeSecao<PromocaoModel>.error(errorModelFromApi(e)),
        );
      });
    }
  }

  List<BarbeariaModel> _parseBarbearias(AppResponse response) {
    return _parseList(response)
        .map(BarbeariaModel.fromJson)
        .toList();
  }

  List<PromocaoModel> _parsePromocoes(AppResponse response) {
    return _parseList(response)
        .map(PromocaoModel.fromJson)
        .toList();
  }

  List<Map<String, dynamic>> _parseList(AppResponse response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('Resposta inválida da API');
    }

    return decoded
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}
