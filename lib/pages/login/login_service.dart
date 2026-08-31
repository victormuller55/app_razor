import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:muller_package/muller_package.dart';

Future<AppResponse> loginUsuario({
  required String email,
  required String senha,
}) async {
  return postHTTP(
    endpoint: AppEndpoints.endpointAuthLogin,
    body: <String, dynamic>{
      'email': email,
      'senha': senha,
    },
  );
}
