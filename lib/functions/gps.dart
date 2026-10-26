import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:muller_package/muller_package.dart';

const String gpsMensagemServicoDesativado =
    'Ative a localização do dispositivo para ver barbearias próximas e promoções.';

const String gpsMensagemPermissaoNegada =
    'Permita o acesso à localização para ver barbearias próximas e promoções.';

const String gpsMensagemIndisponivel =
    'Não foi possível obter sua localização.';

class GpsPosition {
  final double latitude;
  final double longitude;

  const GpsPosition({
    required this.latitude,
    required this.longitude,
  });
}

class GpsException implements Exception {
  final String mensagem;

  const GpsException(this.mensagem);

  @override
  String toString() {
    return mensagem;
  }
}

ErrorModel gpsErrorModel(Object error) {
  if (error is GpsException) {
    return ErrorModel(
      tipo: 'gps',
      mensagem: error.mensagem,
      erro: '',
    );
  }

  return ErrorModel(
    tipo: 'gps',
    mensagem: gpsMensagemIndisponivel,
    erro: '',
  );
}

/// Por quanto tempo uma posição já obtida é reaproveitada entre telas.
const Duration _gpsValidade = Duration(minutes: 2);

GpsPosition? _ultimaPosicao;
DateTime? _ultimaPosicaoEm;
Future<GpsPosition>? _buscaEmAndamento;

// ~110 m de precisão: suficiente para "próximas" e mantém a mesma chave no
// cache HTTP enquanto o usuário não se desloca.
double _arredondar(double valor) {
  return (valor * 1000).roundToDouble() / 1000;
}

GpsPosition _gpsFromPosition(Position position) {
  return GpsPosition(
    latitude: _arredondar(position.latitude),
    longitude: _arredondar(position.longitude),
  );
}

/// Posição atual do usuário.
///
/// Reaproveita a última posição por [_gpsValidade], compartilha a mesma busca
/// entre telas que pedem ao mesmo tempo e tenta a última posição conhecida do
/// sistema antes de ligar o GPS.
Future<GpsPosition> getCurrentGps() {
  final GpsPosition? ultima = _ultimaPosicao;
  final DateTime? ultimaEm = _ultimaPosicaoEm;

  if (ultima != null &&
      ultimaEm != null &&
      DateTime.now().difference(ultimaEm) < _gpsValidade) {
    return Future<GpsPosition>.value(ultima);
  }

  return _buscaEmAndamento ??= _buscarGps().then((GpsPosition gps) {
    _ultimaPosicao = gps;
    _ultimaPosicaoEm = DateTime.now();
    return gps;
  }).whenComplete(() => _buscaEmAndamento = null);
}

Future<GpsPosition> _buscarGps() async {
  final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw const GpsException(gpsMensagemServicoDesativado);
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const GpsException(gpsMensagemPermissaoNegada);
  }

  Position? conhecida;

  try {
    conhecida = await Geolocator.getLastKnownPosition();
  } catch (_) {
    conhecida = null;
  }

  if (conhecida != null &&
      DateTime.now().difference(conhecida.timestamp) < _gpsValidade) {
    return _gpsFromPosition(conhecida);
  }

  try {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );

    return _gpsFromPosition(position);
  } catch (_) {
    // Sem posição nova a tempo: uma posição antiga ainda serve para listar
    // barbearias próximas.
    if (conhecida != null) {
      return _gpsFromPosition(conhecida);
    }

    throw const GpsException(gpsMensagemIndisponivel);
  }
}
