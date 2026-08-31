import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/barbearias/barbearias_service.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_event.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

const double mapaBarbeariasRaioKm = 50;

typedef GetBarbeariasMapa = Future<AppResponse> Function({
  int numPag,
  int itensPag,
  Map<String, dynamic>? filtrosQuery,
  double? latitude,
  double? longitude,
  bool forceRefresh,
});

class MapaBarbeariasBloc extends Bloc<MapaBarbeariasEvent, MapaBarbeariasState> {
  MapaBarbeariasBloc({
    required this.latitude,
    required this.longitude,
    GetBarbeariasMapa? getLista,
  })  : _getBarbearias = getLista ?? getBarbearias,
        super(MapaBarbeariasInitialState()) {
    on<MapaBarbeariasLoadEvent>(_load);
  }

  final double latitude;
  final double longitude;
  final GetBarbeariasMapa _getBarbearias;

  Future<void> _load(
    MapaBarbeariasLoadEvent event,
    Emitter<MapaBarbeariasState> emit,
  ) async {
    emit(MapaBarbeariasLoadingState());

    try {
      final List<BarbeariaModel> itens = <BarbeariaModel>[];
      PaginacaoModel paginacao = PaginacaoModel.empty();
      int pagina = 0;

      do {
        final AppResponse response = await _getBarbearias(
          numPag: pagina,
          itensPag: 100,
          filtrosQuery: const BarbeariasFiltros(
            distanciaMaxima: mapaBarbeariasRaioKm,
          ).toQuery(),
          latitude: latitude,
          longitude: longitude,
          forceRefresh: event.forceRefresh,
        );

        final _Envelope envelope = _parseEnvelope(response);
        itens.addAll(envelope.itens);
        paginacao = envelope.paginacao;
        pagina += 1;
      } while (paginacao.hasMore && pagina < paginacao.maxPag);

      emit(
        MapaBarbeariasSuccessState(
          itens: itens,
          paginacao: paginacao,
        ),
      );
    } catch (e) {
      emit(
        MapaBarbeariasErrorState(
          errorModel: errorModelFromApi(e),
        ),
      );
    }
  }

  _Envelope _parseEnvelope(AppResponse response) {
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

    return _Envelope(
      itens: itens,
      paginacao: PaginacaoModel.fromJson(json),
    );
  }
}

class _Envelope {
  const _Envelope({
    required this.itens,
    required this.paginacao,
  });

  final List<BarbeariaModel> itens;
  final PaginacaoModel paginacao;
}
