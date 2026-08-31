import 'package:app_razor/models/usuario_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class PerfilState {
  ErrorModel errorModel;
  UsuarioModel usuario;

  PerfilState({
    required this.errorModel,
    required this.usuario,
  });
}

class PerfilInitialState extends PerfilState {
  PerfilInitialState()
      : super(
          errorModel: ErrorModel.empty(),
          usuario: UsuarioModel.empty(),
        );
}

class PerfilLoadingState extends PerfilState {
  PerfilLoadingState()
      : super(
          errorModel: ErrorModel.empty(),
          usuario: UsuarioModel.empty(),
        );
}

class PerfilSuccessState extends PerfilState {
  PerfilSuccessState({required super.usuario})
      : super(errorModel: ErrorModel.empty());
}

class PerfilLoggedOutState extends PerfilState {
  PerfilLoggedOutState()
      : super(
          errorModel: ErrorModel.empty(),
          usuario: UsuarioModel.empty(),
        );
}

class PerfilErrorState extends PerfilState {
  PerfilErrorState({required super.errorModel})
      : super(usuario: UsuarioModel.empty());
}
