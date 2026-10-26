import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_bloc.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_event.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  AppResponse ok(String body) {
    return AppResponse(statusCode: 200, body: body);
  }

  const String perfilJson = '''
{
  "id": 7,
  "nome": "Studio Perfil",
  "descricao": "Corte clássico",
  "imagem": "/uploads/barbearias/abc.jpg",
  "telefone": "41999990000",
  "bairro": "Centro",
  "cidade": "Araucária",
  "nota_media": 4.8,
  "total_avaliacoes": 12,
  "distancia_km": 1.5,
  "aberto": true,
  "hora_abertura": "09:00:00",
  "hora_fechamento": "18:00:00",
  "favorito": true,
  "horarios": [],
  "servicos": [{"id": 1, "nome": "Corte", "preco": 45, "duracao_minutos": 40}],
  "funcionarios": [],
  "promocoes": [],
  "avaliacoes": []
}
''';

  Future<BarbeariaPerfilState> waitDone(BarbeariaPerfilBloc bloc) {
    return bloc.stream.firstWhere((BarbeariaPerfilState state) {
      return state is BarbeariaPerfilSuccessState ||
          state is BarbeariaPerfilErrorState;
    });
  }

  group('BarbeariaPerfilBloc', () {
    test('carrega perfil com GPS e emite Success', () async {
      final BarbeariaPerfilBloc bloc = BarbeariaPerfilBloc(
        barbeariaId: 7,
        getPerfil:
            ({
              required int id,
              double? latitude,
              double? longitude,
              bool forceRefresh = false,
            }) async {
              expect(id, 7);
              expect(latitude, -25.4);
              expect(longitude, -49.2);
              return ok(perfilJson);
            },
        getGps: () async {
          return const GpsPosition(latitude: -25.4, longitude: -49.2);
        },
      );

      bloc.add(BarbeariaPerfilLoadEvent());
      final BarbeariaPerfilState state = await waitDone(bloc);

      expect(state, isA<BarbeariaPerfilSuccessState>());
      expect(state.perfil?.id, 7);
      expect(state.perfil?.nome, 'Studio Perfil');
      expect(state.perfil?.servicos, hasLength(1));
      await bloc.close();
    });

    test('carrega perfil mesmo quando o GPS falha', () async {
      double? latRecebida = -1;
      double? lngRecebida = -1;

      final BarbeariaPerfilBloc bloc = BarbeariaPerfilBloc(
        barbeariaId: 7,
        getPerfil:
            ({
              required int id,
              double? latitude,
              double? longitude,
              bool forceRefresh = false,
            }) async {
              latRecebida = latitude;
              lngRecebida = longitude;
              return ok(perfilJson);
            },
        getGps: () async {
          throw const GpsException(gpsMensagemPermissaoNegada);
        },
      );

      bloc.add(BarbeariaPerfilLoadEvent());
      final BarbeariaPerfilState state = await waitDone(bloc);

      expect(state, isA<BarbeariaPerfilSuccessState>());
      expect(latRecebida, isNull);
      expect(lngRecebida, isNull);
      await bloc.close();
    });

    test('emite Error quando a API falha', () async {
      final BarbeariaPerfilBloc bloc = BarbeariaPerfilBloc(
        barbeariaId: 7,
        getPerfil:
            ({
              required int id,
              double? latitude,
              double? longitude,
              bool forceRefresh = false,
            }) async {
              throw ApiException(
                AppResponse(
                  statusCode: 404,
                  body: '{"status":404,"message":"Barbearia não encontrada"}',
                ),
              );
            },
        getGps: () async {
          return const GpsPosition(latitude: 0, longitude: 0);
        },
      );

      bloc.add(BarbeariaPerfilLoadEvent());
      final BarbeariaPerfilState state = await waitDone(bloc);

      expect(state, isA<BarbeariaPerfilErrorState>());
      expect(state.errorModel.mensagem, 'Barbearia não encontrada');
      await bloc.close();
    });
  });
  group('BarbeariaPerfilBloc favorito', () {
    Future<BarbeariaPerfilBloc> carregado(SalvarFavorito salvar) async {
      final BarbeariaPerfilBloc bloc = BarbeariaPerfilBloc(
        barbeariaId: 7,
        getPerfil:
            ({
              required int id,
              double? latitude,
              double? longitude,
              bool forceRefresh = false,
            }) async {
              return ok(perfilJson);
            },
        getGps: () async => const GpsPosition(latitude: 0, longitude: 0),
        salvarFavorito: salvar,
      );
      bloc.add(BarbeariaPerfilLoadEvent());
      await waitDone(bloc);
      return bloc;
    }

    test('desmarca e marca de novo chamando a API', () async {
      final List<bool> chamadas = <bool>[];
      final BarbeariaPerfilBloc bloc = await carregado(({
        required int id,
        required bool favorito,
      }) async {
        expect(id, 7);
        chamadas.add(favorito);
      });

      // O JSON já vem com favorito: true.
      bloc.add(BarbeariaPerfilFavoritoEvent());
      await bloc.stream.first;
      expect(bloc.state.perfil?.favorito, isFalse);
      await Future<void>.delayed(Duration.zero);

      bloc.add(BarbeariaPerfilFavoritoEvent());
      await bloc.stream.first;
      expect(bloc.state.perfil?.favorito, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(chamadas, <bool>[false, true]);
      await bloc.close();
    });

    test('volta ao valor anterior quando a API falha', () async {
      final BarbeariaPerfilBloc bloc = await carregado(({
        required int id,
        required bool favorito,
      }) async {
        throw ApiException(
          AppResponse(statusCode: 500, body: '{"message":"falhou"}'),
        );
      });

      bloc.add(BarbeariaPerfilFavoritoEvent());
      final List<bool?> valores = await bloc.stream
          .map((BarbeariaPerfilState state) => state.perfil?.favorito)
          .take(2)
          .toList();

      expect(valores, <bool?>[false, true]);
      await bloc.close();
    });
  });
}
