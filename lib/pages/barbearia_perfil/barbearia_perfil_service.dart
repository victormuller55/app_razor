import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/favoritas.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:muller_package/muller_package.dart';

Future<AppResponse> getBarbeariaPerfil({
  required int id,
  double? latitude,
  double? longitude,
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointBarbeariaPerfil(id),
    parameters: _geoParameters(latitude: latitude, longitude: longitude),
    forceRefresh: forceRefresh,
  );
}

/// Marca ([favorito] verdadeiro) ou desmarca a barbearia como favorita.
Future<void> salvarBarbeariaFavorita({
  required int id,
  required bool favorito,
}) async {
  final String endpoint = AppEndpoints.endpointBarbeariaFavorito(id);

  if (favorito) {
    await HttpCache.putHTTPCached(endpoint: endpoint);
  } else {
    await HttpCache.deleteHTTPCached(endpoint: endpoint);
  }

  // Lista de favoritas e o perfil em cache ficam desatualizados.
  await HttpCache.invalidateContaining('barbearias');
  favoritasAlteradas.value++;
}

Map<String, dynamic>? _geoParameters({double? latitude, double? longitude}) {
  if (latitude == null || longitude == null) {
    return null;
  }

  return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
}
