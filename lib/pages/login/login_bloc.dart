import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/auth_navigation.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/functions/token_storage.dart';
import 'package:app_razor/models/login_model.dart';
import 'package:app_razor/pages/login/login_event.dart';
import 'package:app_razor/pages/login/login_service.dart';
import 'package:app_razor/pages/login/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitialState()) {
    on<LoginSaveEvent>(_saveLogin);
  }

  Future<void> _saveLogin(
    LoginSaveEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoadingState());

    try {
      final AppResponse response = await loginUsuario(
        email: event.email,
        senha: event.senha,
      );

      final LoginModel loginModel = LoginModel.fromMap(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      await saveToken(loginModel.token);
      await saveLocalUserData(loginModel.usuario);

      emit(LoginSuccessState(loginModel: loginModel));
      showSnackbarSuccess(message: AppStrings.loginEfetuadoComSucesso);
      await openHomeAfterAuth();
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(LoginErrorState(errorModel: errorModel));
      showSnackbarError(message: errorModel.mensagem);
    }
  }
}
