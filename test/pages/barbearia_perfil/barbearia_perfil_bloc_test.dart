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
        getPerfil: ({
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
        getPerfil: ({
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
        getPerfil: ({
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
}
