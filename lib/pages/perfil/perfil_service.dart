import 'dart:convert';
import 'dart:io';

import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:muller_package/muller_package.dart';

UsuarioModel _usuarioDe(AppResponse response) {
  return UsuarioModel.fromMap(
    Map<String, dynamic>.from(jsonDecode(response.body) as Map),
  );
}

Future<UsuarioModel> _persistir(AppResponse response) async {
  final UsuarioModel usuario = _usuarioDe(response);
  await saveLocalUserData(usuario);
  return usuario;
}

Future<UsuarioModel> carregarPerfil({bool forceRefresh = false}) async {
  final UsuarioModel local = await getLocalUserModel();

  try {
    final AppResponse response = await HttpCache.getHTTPCached(
      endpoint: AppEndpoints.endpointUsuariosEu,
      forceRefresh: forceRefresh,
    );
    return _persistir(response);
  } catch (_) {
    if (local.id != null && local.id != 0) {
      return local;
    }
    rethrow;
  }
}

Future<UsuarioModel> atualizarNomePerfil(String nome) async {
  final AppResponse response = await HttpCache.putHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEu,
    body: <String, dynamic>{'nome': nome.trim()},
  );
  await HttpCache.invalidateContaining('usuarios/eu');
  return _persistir(response);
}

Future<void> trocarSenhaPerfil({
  required String senhaAtual,
  required String senhaNova,
}) async {
  await HttpCache.putHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEuSenha,
    body: <String, dynamic>{
      'senha_atual': senhaAtual,
      'senha_nova': senhaNova,
    },
  );
}

Future<UsuarioModel> trocarEmailPerfil({
  required String email,
  required String senha,
}) async {
  final AppResponse response = await HttpCache.putHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEuEmail,
    body: <String, dynamic>{
      'email': email.trim(),
      'senha': senha,
    },
  );
  await HttpCache.invalidateContaining('usuarios/eu');
  return _persistir(response);
}

Future<UsuarioModel> atualizarFotoPerfil(File foto) async {
  final AppResponse response = await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEuFoto,
    body: const <String, dynamic>{},
    file: foto,
  );
  await HttpCache.invalidateContaining('usuarios/eu');
  return _persistir(response);
}

Future<UsuarioModel> removerFotoPerfil() async {
  final AppResponse response = await HttpCache.deleteHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEuFoto,
  );
  await HttpCache.invalidateContaining('usuarios/eu');
  return _persistir(response);
}

Future<void> excluirContaPerfil({required String senha}) async {
  await HttpCache.postHTTPCached(
    endpoint: AppEndpoints.endpointUsuariosEuExcluir,
    body: <String, dynamic>{'senha': senha},
  );
  await HttpCache.clearCache();
  await clearLocalData();
}

Future<void> sairDaConta() async {
  await HttpCache.clearCache();
  await clearLocalData();
}
