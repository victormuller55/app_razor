import 'package:app_razor/models/usuario_model.dart';

abstract class PerfilEvent {}

class PerfilLoadEvent extends PerfilEvent {
  PerfilLoadEvent({this.silencioso = false});

  final bool silencioso;
}

class PerfilLogoutEvent extends PerfilEvent {}

class PerfilAtualizadoEvent extends PerfilEvent {
  PerfilAtualizadoEvent(this.usuario);

  final UsuarioModel usuario;
}
