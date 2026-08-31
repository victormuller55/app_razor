import 'package:app_razor/app_config/const/app_endpoints.dart';
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
    parameters: _geoParameters(
      latitude: latitude,
      longitude: longitude,
    ),
    forceRefresh: forceRefresh,
  );
}

Map<String, dynamic>? _geoParameters({
  double? latitude,
  double? longitude,
}) {
  if (latitude == null || longitude == null) {
    return null;
  }

  return <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
  };
}
