import 'package:app_razor/models/usuario_model.dart';

class LoginModel {
  UsuarioModel? usuario;
  String? token;

  LoginModel({
    this.usuario,
    this.token,
  });

  factory LoginModel.empty() {
    return LoginModel(
      usuario: UsuarioModel.empty(),
      token: '',
    );
  }

  factory LoginModel.fromMap(Map<String, dynamic> json) {
    return LoginModel(
      usuario: json['usuario'] is Map<String, dynamic>
          ? UsuarioModel.fromMap(json['usuario'] as Map<String, dynamic>)
          : UsuarioModel.empty(),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'usuario': usuario?.toMap(),
      'token': token,
    };
  }
}
