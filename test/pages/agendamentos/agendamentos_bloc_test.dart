import 'package:app_razor/pages/agendamentos/agendamentos_bloc.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
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

  const String itemUm = '''
[
  {
    "id": 1,
    "nome_servico": "Corte",
    "nome_barbearia": "Navalha",
    "data_agendamento": "2026-09-02",
    "hora_inicio": "10:00:00",
    "status": "AGENDADO",
    "preco": 45
  }
]
''';

  const String itemDois = '''
[
  {
    "id": 2,
    "nome_servico": "Barba",
    "nome_barbearia": "Navalha",
    "data_agendamento": "2026-09-03",
    "hora_inicio": "11:00:00",
    "status": "CONFIRMADO",
    "preco": 35
  }
]
''';

  Future<AgendamentosState> waitDone(AgendamentosBloc bloc) {
    return bloc.stream.firstWhere((AgendamentosState state) {
      return state is AgendamentosSuccessState ||
          state is AgendamentosErrorState;
    });
  }

  group('AgendamentosBloc', () {
    test('1ª página emite Success com itens e paginação', () async {
      final AgendamentosBloc bloc = AgendamentosBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          bool forceRefresh = false,
        }) async {
          expect(numPag, 0);
          expect(itensPag, 30);
          return ok(
            envelope(
              itens: itemUm,
              maxPag: 5,
              maxItens: 142,
            ),
          );
        },
      );

      final Future<AgendamentosState> done = waitDone(bloc);
      bloc.add(AgendamentosLoadEvent());
      final AgendamentosState state = await done;

      expect(state, isA<AgendamentosSuccessState>());
      expect(state.itens, hasLength(1));
      expect(state.itens.first.nomeServico, 'Corte');
      expect(state.paginacao.numPag, 0);
      expect(state.paginacao.maxPag, 5);
      expect(state.paginacao.hasMore, isTrue);

      await bloc.close();
    });

    test('LoadMore acumula itens da próxima página', () async {
      int chamadas = 0;

      final AgendamentosBloc bloc = AgendamentosBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          bool forceRefresh = false,
        }) async {
          chamadas += 1;
          if (numPag == 0) {
            return ok(
              envelope(
                itens: itemUm,
                numPag: 0,
                maxPag: 2,
                maxItens: 2,
              ),
            );
          }

          expect(numPag, 1);
          return ok(
            envelope(
              itens: itemDois,
              numPag: 1,
              maxPag: 2,
              maxItens: 2,
            ),
          );
        },
      );

      bloc.add(AgendamentosLoadEvent());
      await waitDone(bloc);
      final Future<AgendamentosState> mais = bloc.stream.firstWhere(
        (AgendamentosState state) =>
            state is AgendamentosSuccessState && !state.loadingMore,
      );
      bloc.add(AgendamentosLoadMoreEvent());
      final AgendamentosState state = await mais;

      expect(state.itens, hasLength(2));
      expect(state.itens.first.nomeServico, 'Corte');
      expect(state.itens.last.nomeServico, 'Barba');
      expect(state.paginacao.hasMore, isFalse);
      expect(chamadas, 2);

      await bloc.close();
    });

    test('LoadMore é ignorado na última página', () async {
      int chamadas = 0;

      final AgendamentosBloc bloc = AgendamentosBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          bool forceRefresh = false,
        }) async {
          chamadas += 1;
          return ok(envelope(itens: itemUm));
        },
      );

      bloc.add(AgendamentosLoadEvent());
      await waitDone(bloc);
      bloc.add(AgendamentosLoadMoreEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(chamadas, 1);
      expect(bloc.state.itens, hasLength(1));

      await bloc.close();
    });

    test('forceRefresh a partir do sucesso não troca para Loading', () async {
      final List<AgendamentosState> emitidos = <AgendamentosState>[];

      final AgendamentosBloc bloc = AgendamentosBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          bool forceRefresh = false,
        }) async {
          return ok(envelope(itens: itemUm));
        },
      );

      bloc.stream.listen(emitidos.add);
      bloc.add(AgendamentosLoadEvent());
      await waitDone(bloc);
      emitidos.clear();

      final Future<AgendamentosState> done = waitDone(bloc);
      bloc.add(AgendamentosLoadEvent(forceRefresh: true));
      await done;

      expect(emitidos.whereType<AgendamentosLoadingState>(), isEmpty);
      expect(bloc.state, isA<AgendamentosSuccessState>());
      expect(bloc.state.itens, hasLength(1));

      await bloc.close();
    });

    test('cancelar atualiza o status do item', () async {
      final AgendamentosBloc bloc = AgendamentosBloc(
        getLista: ({
          int numPag = 0,
          int itensPag = 30,
          bool forceRefresh = false,
        }) async {
          return ok(envelope(itens: itemUm));
        },
        cancelar: ({required int id}) async {
          expect(id, 1);
          return ok('''
{
  "id": 1,
  "nome_servico": "Corte",
  "nome_barbearia": "Navalha",
  "data_agendamento": "2026-09-02",
  "hora_inicio": "10:00:00",
  "status": "CANCELADO",
  "preco": 45
}
''');
        },
      );

      bloc.add(AgendamentosLoadEvent());
      await waitDone(bloc);

      final Future<AgendamentosState> done = bloc.stream.firstWhere(
        (AgendamentosState state) =>
            state is AgendamentosSuccessState && state.cancelandoId == null,
      );
      bloc.add(AgendamentosCancelEvent(1));
      final AgendamentosState state = await done;

      expect(state.itens.single.status, 'CANCELADO');
      expect(state.itens.single.podeCancelar, isFalse);

      await bloc.close();
    });
  });
}
