import 'package:app_razor/models/usuario_model.dart';
import 'package:app_razor/pages/perfil/perfil_bloc.dart';
import 'package:app_razor/pages/perfil/perfil_event.dart';
import 'package:app_razor/pages/perfil/perfil_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  UsuarioModel usuario({
    String nome = 'Maria Silva',
    String email = 'maria@exemplo.com',
  }) {
    return UsuarioModel(
      id: 1,
      nome: nome,
      email: email,
      tipo: 'user_app',
      foto: '/uploads/avatars/1.jpg',
      ativo: true,
    );
  }

  Future<PerfilState> waitDone(PerfilBloc bloc) {
    return bloc.stream.firstWhere((PerfilState state) {
      return state is PerfilSuccessState ||
          state is PerfilErrorState ||
          state is PerfilLoggedOutState;
    });
  }

  group('PerfilBloc', () {
    test('carrega perfil e emite Success', () async {
      final PerfilBloc bloc = PerfilBloc(
        carregar: ({bool forceRefresh = false}) async {
          expect(forceRefresh, isTrue);
          return usuario();
        },
        sair: () async {},
      );

      bloc.add(PerfilLoadEvent());
      final PerfilState state = await waitDone(bloc);

      expect(state, isA<PerfilSuccessState>());
      expect(state.usuario.nome, 'Maria Silva');
      expect(state.usuario.email, 'maria@exemplo.com');
      expect(state.usuario.foto, '/uploads/avatars/1.jpg');
      await bloc.close();
    });

    test('erro na carga emite Error', () async {
      final PerfilBloc bloc = PerfilBloc(
        carregar: ({bool forceRefresh = false}) async {
          throw ApiException(AppResponse(statusCode: 500, body: '{}'));
        },
        sair: () async {},
      );

      bloc.add(PerfilLoadEvent());
      final PerfilState state = await waitDone(bloc);

      expect(state, isA<PerfilErrorState>());
      await bloc.close();
    });

    test('atualizado substitui o usuário em tela', () async {
      final PerfilBloc bloc = PerfilBloc(
        carregar: ({bool forceRefresh = false}) async => usuario(),
        sair: () async {},
      );

      bloc.add(PerfilAtualizadoEvent(usuario(nome: 'Maria Atualizada')));
      final PerfilState state = await waitDone(bloc);

      expect(state, isA<PerfilSuccessState>());
      expect(state.usuario.nome, 'Maria Atualizada');
      await bloc.close();
    });

    test('logout limpa sessão e emite LoggedOut', () async {
      bool saiu = false;
      final PerfilBloc bloc = PerfilBloc(
        carregar: ({bool forceRefresh = false}) async => usuario(),
        sair: () async {
          saiu = true;
        },
        abrirLogin: () {},
      );

      bloc.add(PerfilLogoutEvent());
      final PerfilState state = await waitDone(bloc);

      expect(saiu, isTrue);
      expect(state, isA<PerfilLoggedOutState>());
      await bloc.close();
    });
  });
}
