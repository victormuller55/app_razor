import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:muller_package/muller_package.dart';

Future<AppResponse> saveCadastro({
  required String nome,
  required String email,
  required String senha,
}) async {
  return postHTTP(
    endpoint: AppEndpoints.endpointAuthCadastro,
    body: <String, dynamic>{
      'nome': nome,
      'email': email,
      'senha': senha,
    },
  );
}
