import 'dart:async';

import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_bloc.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_event.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  AppResponse ok(String body) {
    return AppResponse(statusCode: 200, body: body);
  }

  String envelope({
    required String itens,
    int numPag = 0,
    int maxPag = 1,
    int maxItens = 1,
  }) {
    return '''
{
  "itens": $itens,
  "num_pag": $numPag,
  "itens_pag": 1,
  "max_pag": $maxPag,
  "max_itens": $maxItens
}
''';
  }

  const String itemUm = '''
[{"id": 1, "nome": "Razor Centro", "bairro": "Centro", "cidade": "Curitiba", "nome_servico": "Corte", "preco_servico": 40}]
''';

  const String itemDois = '''
[{"id": 2, "nome": "Razor Batel", "bairro": "Batel", "cidade": "Curitiba"}]
''';

  Future<PesquisaBarbeariasState> sucesso(PesquisaBarbeariasBloc bloc) {
    return bloc.stream.firstWhere((PesquisaBarbeariasState state) {
      return state is PesquisaSuccessState || state is PesquisaErrorState;
    });
  }

  group('PesquisaBarbeariasBloc', () {
    test('envia a busca e segue sem localização', () async {
      Map<String, dynamic>? query;
      double? latitudeEnviada;

      final PesquisaBarbeariasBloc bloc = PesquisaBarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          query = filtrosQuery;
          latitudeEnviada = latitude;
          expect(forceRefresh, isTrue);
          expect(itensPag, 30);
          return ok(envelope(itens: itemUm));
        },
        getGps: () async {
          throw const GpsException(gpsMensagemPermissaoNegada);
        },
      );

      bloc.prepararConsulta();
      final Future<PesquisaBarbeariasState> pronto = sucesso(bloc);
      bloc.add(PesquisaCarregarEvent(
        filtros: const BarbeariasFiltros(busca: 'corte', cidade: 'Curitiba'),
      ));
      final PesquisaBarbeariasState state = await pronto;

      expect(state, isA<PesquisaSuccessState>());
      expect(state.itens.single.nome, 'Razor Centro');
      expect(state.itens.single.nomeServico, 'Corte');
      expect(state.avisoLocalizacao, avisoLocalizacaoNegada);
      expect(latitudeEnviada, isNull);
      expect(query?['busca'], 'corte');
      expect(query?['cidade'], 'Curitiba');

      await bloc.close();
    });

    test('descarta a resposta de uma pesquisa antiga', () async {
      final Completer<AppResponse> primeira = Completer<AppResponse>();
      final Completer<AppResponse> segunda = Completer<AppResponse>();
      final Completer<void> primeiraChamada = Completer<void>();
      final List<String> publicados = <String>[];
      int chamadas = 0;

      final PesquisaBarbeariasBloc bloc = PesquisaBarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) {
          chamadas++;
          if (chamadas == 1) {
            if (!primeiraChamada.isCompleted) {
              primeiraChamada.complete();
            }
            return primeira.future;
          }
          return segunda.future;
        },
        getGps: () async {
          return const GpsPosition(latitude: -25.4, longitude: -49.2);
        },
      );

      final StreamSubscription<PesquisaBarbeariasState> assinatura =
          bloc.stream.listen((PesquisaBarbeariasState atual) {
        if (atual is PesquisaSuccessState) {
          publicados.addAll(
            atual.itens.map((item) => item.nome ?? ''),
          );
        }
      });

      bloc.prepararConsulta();
      bloc.add(PesquisaCarregarEvent(filtros: const BarbeariasFiltros(busca: 'a')));
      await primeiraChamada.future;

      bloc.prepararConsulta();
      bloc.add(PesquisaCarregarEvent(filtros: const BarbeariasFiltros(busca: 'ab')));
      segunda.complete(ok(envelope(itens: itemDois)));
      primeira.complete(ok(envelope(itens: itemUm)));

      final PesquisaBarbeariasState state = await bloc.stream.firstWhere(
        (PesquisaBarbeariasState atual) =>
            atual is PesquisaSuccessState && atual.filtros.busca == 'ab',
      );

      expect(state.itens.single.nome, 'Razor Batel');
      expect(publicados, isNot(contains('Razor Centro')));

      await assinatura.cancel();
      await bloc.close();
    });

    test('próxima página preserva o filtro e não duplica', () async {
      int chamadas = 0;

      final PesquisaBarbeariasBloc bloc = PesquisaBarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          chamadas++;
          expect(filtrosQuery?['busca'], 'razor');
          if (numPag == 0) {
            return ok(envelope(itens: itemUm, maxPag: 2, maxItens: 2));
          }
          return ok(envelope(
            itens: '[{"id": 1, "nome": "Razor Centro"}, {"id": 2, "nome": "Razor Batel"}]',
            numPag: 1,
            maxPag: 2,
            maxItens: 2,
          ));
        },
        getGps: () async {
          return const GpsPosition(latitude: 0, longitude: 0);
        },
      );

      bloc.prepararConsulta();
      final Future<PesquisaBarbeariasState> pronto = sucesso(bloc);
      bloc.add(PesquisaCarregarEvent(filtros: const BarbeariasFiltros(busca: 'razor')));
      await pronto;

      bloc.add(PesquisaCarregarMaisEvent());
      final PesquisaBarbeariasState state = await bloc.stream.firstWhere(
        (PesquisaBarbeariasState atual) =>
            atual is PesquisaSuccessState && !atual.loadingMore && atual.itens.length > 1,
      );

      expect(chamadas, 2);
      expect(state.itens.map((item) => item.id), <int?>[1, 2]);
      expect(state.filtros.busca, 'razor');

      await bloc.close();
    });

    test('erro de conexão emite o estado de erro', () async {
      final PesquisaBarbeariasBloc bloc = PesquisaBarbeariasBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          Map<String, dynamic>? filtrosQuery,
          double? latitude,
          double? longitude,
          bool forceRefresh = false,
        }) async {
          throw Exception('sem rede');
        },
        getGps: () async {
          return const GpsPosition(latitude: 0, longitude: 0);
        },
      );

      bloc.prepararConsulta();
      final Future<PesquisaBarbeariasState> pronto = sucesso(bloc);
      bloc.add(PesquisaCarregarEvent(filtros: BarbeariasFiltros.empty()));
      final PesquisaBarbeariasState state = await pronto;

      expect(state, isA<PesquisaErrorState>());

      await bloc.close();
    });
  });
}
