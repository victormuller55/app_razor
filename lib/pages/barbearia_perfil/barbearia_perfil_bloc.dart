import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_event.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_service.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetBarbeariaPerfil = Future<AppResponse> Function({
  required int id,
  double? latitude,
  double? longitude,
  bool forceRefresh,
});

typedef GetGpsPosition = Future<GpsPosition> Function();

class BarbeariaPerfilBloc extends Bloc<BarbeariaPerfilEvent, BarbeariaPerfilState> {
  BarbeariaPerfilBloc({
    required this.barbeariaId,
    GetBarbeariaPerfil? getPerfil,
    GetGpsPosition? getGps,
  })  : _getPerfil = getPerfil ?? getBarbeariaPerfil,
        _getGps = getGps ?? getCurrentGps,
        super(BarbeariaPerfilInitialState()) {
    on<BarbeariaPerfilLoadEvent>(_loadPerfil);
  }

  final int barbeariaId;
  final GetBarbeariaPerfil _getPerfil;
  final GetGpsPosition _getGps;

  Future<void> _loadPerfil(
    BarbeariaPerfilLoadEvent event,
    Emitter<BarbeariaPerfilState> emit,
  ) async {
    emit(BarbeariaPerfilLoadingState(perfil: state.perfil));

    double? latitude;
    double? longitude;

    try {
      final GpsPosition gps = await _getGps();
      latitude = gps.latitude;
      longitude = gps.longitude;
    } catch (_) {
      // Distância é opcional: o perfil carrega mesmo sem GPS.
    }

    try {
      final AppResponse response = await _getPerfil(
        id: barbeariaId,
        latitude: latitude,
        longitude: longitude,
        forceRefresh: event.forceRefresh,
      );

      emit(BarbeariaPerfilSuccessState(perfil: _parsePerfil(response)));
    } catch (e) {
      emit(BarbeariaPerfilErrorState(errorModel: errorModelFromApi(e)));
    }
  }

  BarbeariaPerfilModel _parsePerfil(AppResponse response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const FormatException('Resposta inválida da API');
    }

    return BarbeariaPerfilModel.fromJson(Map<String, dynamic>.from(decoded));
  }
}
