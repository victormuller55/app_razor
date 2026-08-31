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

Future<GpsPosition> getCurrentGps() async {
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

  try {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return GpsPosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } on TimeoutException {
    throw const GpsException(gpsMensagemIndisponivel);
  } on GpsException {
    rethrow;
  } catch (_) {
    throw const GpsException(gpsMensagemIndisponivel);
  }
}
