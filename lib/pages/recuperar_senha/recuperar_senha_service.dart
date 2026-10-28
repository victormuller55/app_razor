import 'dart:convert';

import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:muller_package/muller_package.dart';

/// RAZ-08: recuperação de senha do app. O contexto é sempre `APP` (só contas de cliente).
/// Código e token vão no corpo, nunca na URL, e não são gravados no aparelho.
Future<Map<String, dynamic>> solicitarCodigoRecuperacao({required String email}) async {
  final AppResponse response = await postHTTP(
    endpoint: AppEndpoints.endpointAuthRecuperarSenha,
    body: <String, dynamic>{'email': email, 'contexto': 'APP'},
  ).timeout(HttpCache.tempoLimite);
  return _corpo(response);
}

Future<Map<String, dynamic>> verificarCodigoRecuperacao({
  required String email,
  required String codigo,
}) async {
  final AppResponse response = await postHTTP(
    endpoint: AppEndpoints.endpointAuthVerificarCodigo,
    body: <String, dynamic>{'email': email, 'contexto': 'APP', 'codigo': codigo},
  ).timeout(HttpCache.tempoLimite);
  return _corpo(response);
}

Future<Map<String, dynamic>> redefinirSenhaRecuperacao({
  required String token,
  required String senha,
  required String confirmacao,
}) async {
  final AppResponse response = await postHTTP(
    endpoint: AppEndpoints.endpointAuthRedefinirSenha,
    body: <String, dynamic>{'token': token, 'senha': senha, 'confirmacao': confirmacao},
  ).timeout(HttpCache.tempoLimite);
  return _corpo(response);
}

Map<String, dynamic> _corpo(AppResponse response) {
  if (response.body.isEmpty) return <String, dynamic>{};
  return jsonDecode(response.body) as Map<String, dynamic>;
}
