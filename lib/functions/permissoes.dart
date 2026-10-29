import 'dart:io';

import 'package:app_razor/functions/push_notificacoes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissaoStatus { concedida, pendente, bloqueada }

/// Permissões que o app pede na tela de permissões.
///
/// Só a localização é obrigatória para entrar na home; câmera e galeria são
/// usadas apenas na foto de perfil. No Android a galeria usa o seletor do
/// sistema, que não precisa de permissão. Avisos (push, RAZ-11) é opcional e só
/// aparece com o Firebase configurado no build.
enum PermissaoApp { localizacao, camera, galeria, notificacoes }

List<PermissaoApp> permissoesDoApp() {
  return <PermissaoApp>[
    PermissaoApp.localizacao,
    PermissaoApp.camera,
    if (Platform.isIOS) PermissaoApp.galeria,
    if (PushNotificacoes.instance.disponivel) PermissaoApp.notificacoes,
  ];
}

PermissaoStatus _statusLocalizacao(LocationPermission permission) {
  switch (permission) {
    case LocationPermission.always:
    case LocationPermission.whileInUse:
      return PermissaoStatus.concedida;
    case LocationPermission.deniedForever:
      return PermissaoStatus.bloqueada;
    case LocationPermission.denied:
    case LocationPermission.unableToDetermine:
      return PermissaoStatus.pendente;
  }
}

PermissaoStatus _statusHandler(PermissionStatus status) {
  if (status.isGranted || status.isLimited) {
    return PermissaoStatus.concedida;
  }

  if (status.isPermanentlyDenied || status.isRestricted) {
    return PermissaoStatus.bloqueada;
  }

  return PermissaoStatus.pendente;
}

Permission _permissionHandler(PermissaoApp permissao) {
  return permissao == PermissaoApp.camera ? Permission.camera : Permission.photos;
}

Future<PermissaoStatus> statusPermissao(PermissaoApp permissao) async {
  if (permissao == PermissaoApp.localizacao) {
    return _statusLocalizacao(await Geolocator.checkPermission());
  }
  if (permissao == PermissaoApp.notificacoes) {
    return PushNotificacoes.instance.statusPermissao();
  }

  return _statusHandler(await _permissionHandler(permissao).status);
}

Future<PermissaoStatus> pedirPermissao(PermissaoApp permissao) async {
  if (permissao == PermissaoApp.localizacao) {
    return _statusLocalizacao(await Geolocator.requestPermission());
  }
  if (permissao == PermissaoApp.notificacoes) {
    return PushNotificacoes.instance.pedirPermissao();
  }

  return _statusHandler(await _permissionHandler(permissao).request());
}

Future<void> abrirAjustesDoApp() async {
  await openAppSettings();
}

Future<bool> localizacaoPermitida() async {
  return await statusPermissao(PermissaoApp.localizacao) ==
      PermissaoStatus.concedida;
}

Future<bool> todasPermissoesConcedidas() async {
  for (final PermissaoApp permissao in permissoesDoApp()) {
    if (await statusPermissao(permissao) != PermissaoStatus.concedida) {
      return false;
    }
  }

  return true;
}
