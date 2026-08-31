import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/perfil/perfil_event.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/perfil/perfil_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef CarregarPerfil = Future<UsuarioModel> Function({bool forceRefresh});
typedef SairPerfil = Future<void> Function();
typedef AbrirLogin = void Function();

class PerfilBloc extends Bloc<PerfilEvent, PerfilState> {
  PerfilBloc({
    CarregarPerfil? carregar,
    SairPerfil? sair,
    AbrirLogin? abrirLogin,
  })  : _carregarPerfil = carregar ?? carregarPerfil,
        _sairDaConta = sair ?? sairDaConta,
        _abrirLogin = abrirLogin ?? _abrirTelaLogin,
        super(PerfilInitialState()) {
    on<PerfilLoadEvent>(_carregar);
    on<PerfilLogoutEvent>(_sair);
    on<PerfilAtualizadoEvent>(_atualizar);
  }

  final CarregarPerfil _carregarPerfil;
  final SairPerfil _sairDaConta;
  final AbrirLogin _abrirLogin;

  static void _abrirTelaLogin() {
    open(screen: const LoginPage(), closePrevious: true);
  }

  Future<void> _carregar(
    PerfilLoadEvent event,
    Emitter<PerfilState> emit,
  ) async {
    if (!event.silencioso) {
      emit(PerfilLoadingState());
    }

    try {
      final UsuarioModel usuario = await _carregarPerfil(forceRefresh: true);
      emit(PerfilSuccessState(usuario: usuario));
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(PerfilErrorState(errorModel: errorModel));
      _notifyErro(errorModel);
    }
  }

  Future<void> _sair(
    PerfilLogoutEvent event,
    Emitter<PerfilState> emit,
  ) async {
    emit(PerfilLoadingState());
    await _sairDaConta();
    emit(PerfilLoggedOutState());
    _abrirLogin();
  }

  void _atualizar(PerfilAtualizadoEvent event, Emitter<PerfilState> emit) {
    emit(PerfilSuccessState(usuario: event.usuario));
  }

  void _notifyErro(ErrorModel errorModel) {
    try {
      if (AppContext.navigatorKey.currentContext == null) {
        return;
      }
      showSnackbarError(message: errorModel.mensagem);
    } catch (_) {}
  }
}
