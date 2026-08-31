import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/barbearias/barbearias_event.dart';
import 'package:app_razor/pages/barbearias/barbearias_service.dart';
import 'package:app_razor/pages/barbearias/barbearias_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetBarbearias = Future<AppResponse> Function({
  int numPag,
  int itensPag,
  Map<String, dynamic>? filtrosQuery,
  double? latitude,
  double? longitude,
  bool forceRefresh,
});

typedef GetGpsPosition = Future<GpsPosition> Function();

class _BarbeariasEnvelope {
  final List<BarbeariaModel> itens;
  final PaginacaoModel paginacao;

  const _BarbeariasEnvelope({
    required this.itens,
    required this.paginacao,
  });
}

class BarbeariasBloc extends Bloc<BarbeariasEvent, BarbeariasState> {
  BarbeariasBloc({
    GetBarbearias? getLista,
    GetGpsPosition? getGps,
  })  : _getBarbearias = getLista ?? getBarbearias,
        _getGps = getGps ?? getCurrentGps,
        super(BarbeariasInitialState()) {
    on<BarbeariasLoadEvent>(_loadBarbearias);
    on<BarbeariasLoadMoreEvent>(_loadMoreBarbearias);
  }

  final GetBarbearias _getBarbearias;
  final GetGpsPosition _getGps;

  Future<void> _loadBarbearias(
    BarbeariasLoadEvent event,
    Emitter<BarbeariasState> emit,
  ) async {
    emit(
      BarbeariasLoadingState(
        filtros: event.filtros,
        latitude: state.latitude,
        longitude: state.longitude,
      ),
    );

    final GpsPosition? gps = await _readGps();
    final double? latitude = gps?.latitude;
    final double? longitude = gps?.longitude;

    try {
      final AppResponse response = await _getBarbearias(
        numPag: 0,
        itensPag: barbeariasItensPag,
        filtrosQuery: event.filtros.toQuery(),
        latitude: latitude,
        longitude: longitude,
        forceRefresh: event.forceRefresh,
      );

      final _BarbeariasEnvelope envelope = _parseEnvelope(response);

      emit(
        BarbeariasSuccessState(
          itens: envelope.itens,
          paginacao: envelope.paginacao,
          filtros: event.filtros,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);

      emit(
        BarbeariasErrorState(
          errorModel: errorModel,
          filtros: event.filtros,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      _notifyErro(errorModel);
    }
  }

  Future<void> _loadMoreBarbearias(
    BarbeariasLoadMoreEvent event,
    Emitter<BarbeariasState> emit,
  ) async {
    final BarbeariasState current = state;

    if (current is! BarbeariasSuccessState) {
      return;
    }

    if (current.loadingMore || !current.paginacao.hasMore) {
      return;
    }

    final List<BarbeariaModel> itensAtuais = current.itens;
    final int proximaPagina = current.paginacao.numPag + 1;

    emit(
      BarbeariasSuccessState(
        itens: itensAtuais,
        paginacao: current.paginacao,
        filtros: current.filtros,
        loadingMore: true,
        latitude: current.latitude,
        longitude: current.longitude,
      ),
    );

    try {
      final AppResponse response = await _getBarbearias(
        numPag: proximaPagina,
        itensPag: barbeariasItensPag,
        filtrosQuery: current.filtros.toQuery(),
        latitude: current.latitude,
        longitude: current.longitude,
        forceRefresh: false,
      );

      final _BarbeariasEnvelope envelope = _parseEnvelope(response);

      emit(
        BarbeariasSuccessState(
          itens: <BarbeariaModel>[...itensAtuais, ...envelope.itens],
          paginacao: envelope.paginacao,
          filtros: current.filtros,
          latitude: current.latitude,
          longitude: current.longitude,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);

      emit(
        BarbeariasSuccessState(
          itens: itensAtuais,
          paginacao: current.paginacao,
          filtros: current.filtros,
          latitude: current.latitude,
          longitude: current.longitude,
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
    } catch (_) {
      // Sem navigator (testes unitários).
    }
  }

  Future<GpsPosition?> _readGps() async {
    try {
      return await _getGps();
    } catch (_) {
      return null;
    }
  }

  _BarbeariasEnvelope _parseEnvelope(AppResponse response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const FormatException('Resposta inválida da API');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final dynamic itensJson = json['itens'];

    if (itensJson is! List) {
      throw const FormatException('Resposta inválida da API');
    }

    final List<BarbeariaModel> itens = itensJson
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) => BarbeariaModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return _BarbeariasEnvelope(
      itens: itens,
      paginacao: PaginacaoModel.fromJson(json),
    );
  }
}
