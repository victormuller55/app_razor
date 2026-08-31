import 'package:app_razor/functions/token_storage.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveLocalUserData(UsuarioModel? usuarioModel) async {
  if (usuarioModel == null) {
    return;
  }

  final SharedPreferences localData = await SharedPreferences.getInstance();

  await localData.setInt('id', usuarioModel.id ?? 0);
  await localData.setString('nome', usuarioModel.nome ?? '');
  await localData.setString('email', usuarioModel.email ?? '');
  await localData.setString('tipo', usuarioModel.tipo ?? '');
  await localData.setString('foto', usuarioModel.foto ?? '');
}

Future<UsuarioModel> getLocalUserModel() async {
  final SharedPreferences localData = await SharedPreferences.getInstance();

  return UsuarioModel(
    id: localData.getInt('id'),
    nome: localData.getString('nome'),
    email: localData.getString('email'),
    tipo: localData.getString('tipo'),
    foto: localData.getString('foto'),
  );
}

Future<void> clearLocalData() async {
  final SharedPreferences localData = await SharedPreferences.getInstance();
  await localData.clear();
  await clearToken();
}

Future<bool> hasLocalData() async {
  final SharedPreferences localData = await SharedPreferences.getInstance();
  final int? id = localData.getInt('id');
  final String? token = await getToken();
  return id != null && token != null && token.isNotEmpty;
}
