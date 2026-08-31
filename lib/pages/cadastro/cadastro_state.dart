import 'package:app_razor/models/usuario_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class CadastroState {
  ErrorModel errorModel;
  UsuarioModel usuarioModel;

  CadastroState({required this.errorModel, required this.usuarioModel});
}

class CadastroInitialState extends CadastroState {
  CadastroInitialState()
    : super(errorModel: ErrorModel.empty(), usuarioModel: UsuarioModel.empty());
}

class CadastroLoadingState extends CadastroState {
  CadastroLoadingState()
    : super(errorModel: ErrorModel.empty(), usuarioModel: UsuarioModel.empty());
}

class CadastroSuccessState extends CadastroState {
  CadastroSuccessState({required super.usuarioModel}) : super(errorModel: ErrorModel.empty());
}

class CadastroErrorState extends CadastroState {
  CadastroErrorState({required super.errorModel}) : super(usuarioModel: UsuarioModel.empty());
}
