import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:app_razor/pages/cadastro/cadastro_event.dart';
import 'package:app_razor/pages/cadastro/cadastro_service.dart';
import 'package:app_razor/pages/cadastro/cadastro_state.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class CadastroBloc extends Bloc<CadastroEvent, CadastroState> {
  CadastroBloc() : super(CadastroInitialState()) {
    on<CadastroSaveEvent>(_saveCadastro);
  }

  Future<void> _saveCadastro(
    CadastroSaveEvent event,
    Emitter<CadastroState> emit,
  ) async {
    emit(CadastroLoadingState());

    try {
      final AppResponse response = await saveCadastro(
        nome: event.nome,
        email: event.email,
        senha: event.senha,
      );

      final UsuarioModel usuarioModel = UsuarioModel.fromMap(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      emit(CadastroSuccessState(usuarioModel: usuarioModel));
      showSnackbarSuccess(message: AppStrings.sucessoAoCriarConta);
      open(screen: const LoginPage(), closePrevious: true);
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(CadastroErrorState(errorModel: errorModel));
      showSnackbarError(message: errorModel.mensagem);
    }
  }
}
