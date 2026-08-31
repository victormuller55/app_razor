import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class BarbeariaPerfilState {
  ErrorModel errorModel;
  BarbeariaPerfilModel? perfil;

  BarbeariaPerfilState({
    required this.errorModel,
    this.perfil,
  });
}

class BarbeariaPerfilInitialState extends BarbeariaPerfilState {
  BarbeariaPerfilInitialState() : super(errorModel: ErrorModel.empty());
}

class BarbeariaPerfilLoadingState extends BarbeariaPerfilState {
  BarbeariaPerfilLoadingState({BarbeariaPerfilModel? perfil})
      : super(
          errorModel: ErrorModel.empty(),
          perfil: perfil,
        );
}

class BarbeariaPerfilSuccessState extends BarbeariaPerfilState {
  BarbeariaPerfilSuccessState({required BarbeariaPerfilModel perfil})
      : super(
          errorModel: ErrorModel.empty(),
          perfil: perfil,
        );
}

class BarbeariaPerfilErrorState extends BarbeariaPerfilState {
  BarbeariaPerfilErrorState({required ErrorModel errorModel})
      : super(errorModel: errorModel);
}
