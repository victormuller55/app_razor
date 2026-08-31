import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

const String rotaMensagemIndisponivel = 'Não foi possível abrir a rota.';

class RotaException implements Exception {
  final String mensagem;

  const RotaException(this.mensagem);

  @override
  String toString() {
    return mensagem;
  }
}

typedef LaunchRota = Future<bool> Function(Uri uri);

String? destinoRotaBarbearia({
  double? latitude,
  double? longitude,
  String? endereco,
  String? nome,
}) {
  if (latitude != null && longitude != null) {
    return '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
  }

  final String? texto = endereco?.trim();

  if (texto != null && texto.isNotEmpty) {
    return texto;
  }

  final String? titulo = nome?.trim();

  if (titulo == null || titulo.isEmpty) {
    return null;
  }

  return titulo;
}

Uri? rotaBarbeariaUri({
  double? latitude,
  double? longitude,
  String? endereco,
  String? nome,
  bool appleMaps = false,
}) {
  final String? destino = destinoRotaBarbearia(
    latitude: latitude,
    longitude: longitude,
    endereco: endereco,
    nome: nome,
  );

  if (destino == null) {
    return null;
  }

  if (appleMaps) {
    return Uri.https('maps.apple.com', '/', <String, String>{
      'daddr': destino,
      'dirflg': 'd',
    });
  }

  return Uri.https('www.google.com', '/maps/dir/', <String, String>{
    'api': '1',
    'destination': destino,
    'travelmode': 'driving',
  });
}

Future<bool> _launchPadrao(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> abrirRotaBarbearia({
  double? latitude,
  double? longitude,
  String? endereco,
  String? nome,
  bool? appleMaps,
  LaunchRota? launch,
}) async {
  final Uri? uri = rotaBarbeariaUri(
    latitude: latitude,
    longitude: longitude,
    endereco: endereco,
    nome: nome,
    appleMaps: appleMaps ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS),
  );

  if (uri == null) {
    throw const RotaException(rotaMensagemIndisponivel);
  }

  final LaunchRota launcher = launch ?? _launchPadrao;
  final bool abriu = await launcher(uri);

  if (!abriu) {
    throw const RotaException(rotaMensagemIndisponivel);
  }
}
