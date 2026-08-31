import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/pages/barbearias/barbearias_bloc.dart';
import 'package:app_razor/pages/barbearias/barbearias_event.dart';
import 'package:app_razor/pages/barbearias/barbearias_state.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
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

  const String barbeariaUm = '''
[
  {
    "id": 1,
    "nome": "Razor Centro",
    "imagem": "/uploads/barbearias/abc.jpg",
    "bairro": "Centro",
    "cidade": "São Paulo",
    "nota_media": 4.5,
    "distancia_km": 1.23,
    "aberto": true,
    "latitude": -23.5505,
    "longitude": -46.6333
  }
]
''';

  const String barbeariaDois = '''
[
  {
    "id": 2,
    "nome": "Razor Jardins",
    "imagem": "/uploads/barbearias/def.jpg",
    "bairro": "Jardins",
    "cidade": "São Paulo",
    "nota_media": 4.8,
    "distancia_km": 2.1,
    "aberto": true
  }
]
''';

  Future<BarbeariasState> waitDone(BarbeariasBloc bloc) {
    return bloc.stream.firstWhere((BarbeariasState state) {
      return state is BarbeariasSuccessState || state is BarbeariasErrorState;
    });
  }

  group('BarbeariasBloc', () {
    test('1ª página emite Success com itens e paginação', () async {
      final BarbeariasBloc bloc = BarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          expect(numPag, 0);
          return ok(
            envelope(
              itens: barbeariaUm,
              maxPag: 5,
              maxItens: 142,
            ),
          );
        },
        getGps: () async {
          return const GpsPosition(latitude: -23.55, longitude: -46.63);
        },
      );

      final Future<BarbeariasState> done = waitDone(bloc);
      bloc.add(BarbeariasLoadEvent());
      final BarbeariasState state = await done;

      expect(state, isA<BarbeariasSuccessState>());
      expect(state.itens, hasLength(1));
      expect(state.itens.first.nome, 'Razor Centro');
      expect(state.paginacao.numPag, 0);
      expect(state.paginacao.maxPag, 5);
      expect(state.paginacao.maxItens, 142);
      expect(state.paginacao.hasMore, isTrue);
      expect(state.latitude, -23.55);
      expect(state.longitude, -46.63);
      expect(state.loadingMore, isFalse);

      await bloc.close();
    });

    test('LoadMore acumula itens da próxima página', () async {
      int chamadas = 0;

      final BarbeariasBloc bloc = BarbeariasBloc(
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
                itens: barbeariaUm,
                numPag: 0,
                maxPag: 2,
                maxItens: 2,
              ),
            );
          }

          expect(numPag, 1);
          return ok(
            envelope(
              itens: barbeariaDois,
              numPag: 1,
              maxPag: 2,
              maxItens: 2,
            ),
          );
        },
        getGps: () async {
          throw const GpsException(gpsMensagemPermissaoNegada);
        },
      );

      bloc.add(BarbeariasLoadEvent());
      final BarbeariasState primeira = await waitDone(bloc);
      expect(primeira, isA<BarbeariasSuccessState>());
      expect(primeira.itens, hasLength(1));
      expect(primeira.latitude, isNull);

      final Future<BarbeariasState> mais = bloc.stream.firstWhere(
        (BarbeariasState state) =>
            state is BarbeariasSuccessState && !state.loadingMore,
      );
      bloc.add(BarbeariasLoadMoreEvent());
      final BarbeariasState acumulada = await mais;

      expect(acumulada, isA<BarbeariasSuccessState>());
      expect(acumulada.itens, hasLength(2));
      expect(acumulada.itens.first.nome, 'Razor Centro');
      expect(acumulada.itens.last.nome, 'Razor Jardins');
      expect(acumulada.paginacao.numPag, 1);
      expect(acumulada.paginacao.hasMore, isFalse);
      expect(chamadas, 2);

      await bloc.close();
    });

    test('LoadMore não dispara se já estiver na última página', () async {
      int chamadas = 0;

      final BarbeariasBloc bloc = BarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          chamadas += 1;
          return ok(
            envelope(
              itens: barbeariaUm,
              numPag: 0,
              maxPag: 1,
              maxItens: 1,
            ),
          );
        },
        getGps: () async {
          return const GpsPosition(latitude: -23.55, longitude: -46.63);
        },
      );

      bloc.add(BarbeariasLoadEvent());
      await waitDone(bloc);

      bloc.add(BarbeariasLoadMoreEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(chamadas, 1);
      expect(bloc.state, isA<BarbeariasSuccessState>());
      expect(bloc.state.itens, hasLength(1));
      expect(bloc.state.paginacao.hasMore, isFalse);
      expect(bloc.state.loadingMore, isFalse);

      await bloc.close();
    });

    test('erro na 1ª página emite ErrorState', () async {
      final BarbeariasBloc bloc = BarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          throw ApiException(
            AppResponse(
              statusCode: 400,
              body: '{"message":"parâmetro inválido"}',
            ),
          );
        },
        getGps: () async {
          return const GpsPosition(latitude: -23.55, longitude: -46.63);
        },
      );

      final Future<BarbeariasState> done = waitDone(bloc);
      bloc.add(BarbeariasLoadEvent());
      final BarbeariasState state = await done;

      expect(state, isA<BarbeariasErrorState>());
      expect(state.errorModel.mensagem, 'parâmetro inválido');
      expect(state.itens, isEmpty);

      await bloc.close();
    });

    test('filtros vão na query da 1ª página', () async {
      Map<String, dynamic>? queryEnviada;

      final BarbeariasFiltros filtros = BarbeariasFiltros(
        cidade: 'São Paulo',
        bairro: 'Centro',
        aberto: true,
        notaMinima: 4,
      );

      final BarbeariasBloc bloc = BarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          queryEnviada = filtrosQuery;
          return ok(envelope(itens: '[]', itensPag: 0, maxPag: 0, maxItens: 0));
        },
        getGps: () async {
          throw const GpsException(gpsMensagemIndisponivel);
        },
      );

      final Future<BarbeariasState> done = waitDone(bloc);
      bloc.add(BarbeariasLoadEvent(filtros: filtros));
      final BarbeariasState state = await done;

      expect(state, isA<BarbeariasSuccessState>());
      expect(state.itens, isEmpty);
      expect(queryEnviada, filtros.toQuery());
      expect(state.filtros.cidade, 'São Paulo');

      await bloc.close();
    });
  });
}
