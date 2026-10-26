import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_event.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_service.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetBarbeariaPerfil =
    Future<AppResponse> Function({
      required int id,
      double? latitude,
      double? longitude,
      bool forceRefresh,
    });

typedef GetGpsPosition = Future<GpsPosition> Function();

typedef SalvarFavorito =
    Future<void> Function({required int id, required bool favorito});

class BarbeariaPerfilBloc
    extends Bloc<BarbeariaPerfilEvent, BarbeariaPerfilState> {
  BarbeariaPerfilBloc({
    required this.barbeariaId,
    GetBarbeariaPerfil? getPerfil,
    GetGpsPosition? getGps,
    SalvarFavorito? salvarFavorito,
  }) : _getPerfil = getPerfil ?? getBarbeariaPerfil,
       _getGps = getGps ?? getCurrentGps,
       _salvarFavorito = salvarFavorito ?? salvarBarbeariaFavorita,
       super(BarbeariaPerfilInitialState()) {
    on<BarbeariaPerfilLoadEvent>(_loadPerfil);
    on<BarbeariaPerfilFavoritoEvent>(_alternarFavorito);
  }

  final int barbeariaId;
  final GetBarbeariaPerfil _getPerfil;
  final GetGpsPosition _getGps;
  final SalvarFavorito _salvarFavorito;
  bool _salvandoFavorito = false;

  /// Troca o coração na hora e volta atrás se a API recusar.
  Future<void> _alternarFavorito(
    BarbeariaPerfilFavoritoEvent event,
    Emitter<BarbeariaPerfilState> emit,
  ) async {
    final BarbeariaPerfilModel? perfil = state.perfil;

    // Ignora toques enquanto o anterior ainda está salvando.
    if (state is! BarbeariaPerfilSuccessState ||
        perfil == null ||
        _salvandoFavorito) {
      return;
    }

    final bool anterior = perfil.favorito ?? false;
    _salvandoFavorito = true;
    perfil.favorito = !anterior;
    emit(BarbeariaPerfilSuccessState(perfil: perfil));

    try {
      await _salvarFavorito(id: barbeariaId, favorito: !anterior);
    } catch (e) {
      perfil.favorito = anterior;
      emit(BarbeariaPerfilSuccessState(perfil: perfil));
      _notifyErro(errorModelFromApi(e));
    } finally {
      _salvandoFavorito = false;
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
