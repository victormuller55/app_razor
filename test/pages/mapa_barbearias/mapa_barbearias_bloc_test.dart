import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_bloc.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_event.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  AppResponse ok(String body) {
    return AppResponse(statusCode: 200, body: body);
  }

  String envelope({
    required String itens,
    int numPag = 0,
    int itensPag = 1,
    int maxPag = 1,
    int maxItens = 1,
  }) {
    return '''
{
  "itens": $itens,
  "num_pag": $numPag,
  "itens_pag": $itensPag,
  "max_pag": $maxPag,
  "max_itens": $maxItens
}
''';
  }

  const String barbeariaPerto = '''
[
  {
    "id": 1,
    "nome": "Navalha Centro",
    "imagem": "/uploads/barbearias/abc.jpg",
    "bairro": "Centro",
    "cidade": "Araucária",
    "nota_media": 4.8,
    "distancia_km": 2.1,
    "aberto": true,
    "latitude": -25.5931,
    "longitude": -49.4104
  }
]
''';

  Future<MapaBarbeariasState> waitDone(MapaBarbeariasBloc bloc) {
    return bloc.stream.firstWhere(
      (MapaBarbeariasState state) =>
          state is MapaBarbeariasSuccessState ||
          state is MapaBarbeariasErrorState,
    );
  }

  group('MapaBarbeariasBloc', () {
    test('carrega barbearias até 50 km na query', () async {
      Map<String, dynamic>? query;
      double? lat;
      double? lng;

      final MapaBarbeariasBloc bloc = MapaBarbeariasBloc(
        latitude: -25.59,
        longitude: -49.41,
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          query = filtrosQuery;
          lat = latitude;
          lng = longitude;
          return ok(envelope(itens: barbeariaPerto));
        },
      );

      final Future<MapaBarbeariasState> done = waitDone(bloc);
      bloc.add(MapaBarbeariasLoadEvent());
      final MapaBarbeariasState state = await done;

      expect(state, isA<MapaBarbeariasSuccessState>());
      expect(state.itens, hasLength(1));
      expect(state.itens.first.nome, 'Navalha Centro');
      expect(lat, -25.59);
      expect(lng, -49.41);
      expect(
        query,
        const BarbeariasFiltros(distanciaMaxima: mapaBarbeariasRaioKm).toQuery(),
      );
      expect(mapaBarbeariasRaioKm, 50);

      await bloc.close();
    });

    test('acumula páginas até o fim da listagem', () async {
      int chamadas = 0;

      final MapaBarbeariasBloc bloc = MapaBarbeariasBloc(
        latitude: -25.59,
        longitude: -49.41,
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          chamadas += 1;

          if (numPag == 0) {
            return ok(
              envelope(
                itens: barbeariaPerto,
                numPag: 0,
                maxPag: 2,
                maxItens: 2,
              ),
            );
          }

          return ok(
            envelope(
              itens: '''
[
  {
    "id": 2,
    "nome": "Fade Studio",
    "cidade": "Curitiba",
    "distancia_km": 12.4,
    "latitude": -25.4284,
    "longitude": -49.2733
  }
]
''',
              numPag: 1,
              maxPag: 2,
              maxItens: 2,
            ),
          );
        },
      );

      final Future<MapaBarbeariasState> done = waitDone(bloc);
      bloc.add(MapaBarbeariasLoadEvent());
      final MapaBarbeariasState state = await done;

      expect(chamadas, 2);
      expect(state.itens.map((item) => item.nome), [
        'Navalha Centro',
        'Fade Studio',
      ]);

      await bloc.close();
    });

    test('erro da API emite ErrorState', () async {
      final MapaBarbeariasBloc bloc = MapaBarbeariasBloc(
        latitude: -25.59,
        longitude: -49.41,
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          throw const FormatException('Resposta inválida da API');
        },
      );

      final Future<MapaBarbeariasState> done = waitDone(bloc);
      bloc.add(MapaBarbeariasLoadEvent());
      final MapaBarbeariasState state = await done;

      expect(state, isA<MapaBarbeariasErrorState>());
      expect(state.itens, isEmpty);

      await bloc.close();
    });
  });
}
