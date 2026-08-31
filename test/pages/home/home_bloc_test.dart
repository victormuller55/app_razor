import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/pages/home/home_bloc.dart';
import 'package:app_razor/pages/home/home_event.dart';
import 'package:app_razor/pages/home/home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  AppResponse ok(String body) {
    return AppResponse(statusCode: 200, body: body);
  }

  const String barbeariaJson = '''
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

  const String promocaoJson = '''
[
  {
    "id": 1,
    "tipo": "PROMOCAO",
    "titulo": "Corte em dobro",
    "descricao": "Oferta da semana",
    "preco_original": 80,
    "preco_promocional": 40,
    "data_fim": "2026-08-31",
    "barbearia": {
      "id": 1,
      "nome": "Razor Centro"
    }
  }
]
''';

  Future<HomeState> waitDone(HomeBloc bloc) {
    return bloc.stream.firstWhere((HomeState state) {
      return !state.favoritas.isLoading &&
          !state.proximas.isLoading &&
          !state.promocoes.isLoading;
    });
  }

  group('HomeBloc seções independentes', () {
    test('GPS negado carrega favoritas e coloca próximas/promoções em erro', () async {
      bool proximasChamada = false;
      bool promocoesChamada = false;

      final HomeBloc bloc = HomeBloc(
        getFavoritas: ({
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          return ok(barbeariaJson);
        },
        getProximas: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          proximasChamada = true;
          return ok(barbeariaJson);
        },
        getPromocoes: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          promocoesChamada = true;
          return ok(promocaoJson);
        },
        getGps: () async {
          throw const GpsException(gpsMensagemPermissaoNegada);
        },
      );

      final Future<HomeState> done = waitDone(bloc);
      bloc.add(HomeLoadEvent());
      final HomeState state = await done;

      expect(state.favoritas.status, HomeSecaoStatus.success);
      expect(state.favoritas.itens, isNotEmpty);
      expect(state.favoritas.itens.first.nome, 'Razor Centro');
      expect(state.proximas.status, HomeSecaoStatus.error);
      expect(state.promocoes.status, HomeSecaoStatus.error);
      expect(state.proximas.errorModel.mensagem, gpsMensagemPermissaoNegada);
      expect(state.promocoes.errorModel.mensagem, gpsMensagemPermissaoNegada);
      expect(state.latitude, isNull);
      expect(state.longitude, isNull);
      expect(proximasChamada, isFalse);
      expect(promocoesChamada, isFalse);

      await bloc.close();
    });

    test('falha de próximas não zera favoritas nem promoções', () async {
      final HomeBloc bloc = HomeBloc(
        getFavoritas: ({
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          return ok(barbeariaJson);
        },
        getProximas: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          throw ApiException(
            AppResponse(statusCode: 500, body: '{"message":"falha próximas"}'),
          );
        },
        getPromocoes: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          return ok(promocaoJson);
        },
        getGps: () async {
          return const GpsPosition(latitude: -23.55, longitude: -46.63);
        },
      );

      final Future<HomeState> done = waitDone(bloc);
      bloc.add(HomeLoadEvent());
      final HomeState state = await done;

      expect(state.favoritas.status, HomeSecaoStatus.success);
      expect(state.favoritas.itens, isNotEmpty);
      expect(state.proximas.status, HomeSecaoStatus.error);
      expect(state.promocoes.status, HomeSecaoStatus.success);
      expect(state.promocoes.itens, isNotEmpty);
      expect(state.promocoes.itens.first.nome, 'Corte em dobro');
      expect(state.todasSecoesVazias, isFalse);
      expect(state.latitude, -23.55);
      expect(state.longitude, -46.63);

      await bloc.close();
    });

    test('listas vazias entram em sucesso vazio, não em erro', () async {
      final HomeBloc bloc = HomeBloc(
        getFavoritas: ({
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          return ok('[]');
        },
        getProximas: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          return ok('[]');
        },
        getPromocoes: ({
          required double latitude,
          required double longitude,
          bool forceRefresh = false,
        }) async {
          return ok('[]');
        },
        getGps: () async {
          return const GpsPosition(latitude: -23.55, longitude: -46.63);
        },
      );

      final Future<HomeState> done = waitDone(bloc);
      bloc.add(HomeLoadEvent());
      final HomeState state = await done;

      expect(state.favoritas.status, HomeSecaoStatus.success);
      expect(state.favoritas.isEmpty, isTrue);
      expect(state.proximas.status, HomeSecaoStatus.success);
      expect(state.proximas.isEmpty, isTrue);
      expect(state.promocoes.status, HomeSecaoStatus.success);
      expect(state.promocoes.isEmpty, isTrue);
      expect(state.todasSecoesVazias, isTrue);

      await bloc.close();
    });
  });
}
