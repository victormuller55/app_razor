import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:muller_package/muller_package.dart';

const int barbeariasItensPag = 30;

Future<AppResponse> getBarbearias({
  int numPag = 0,
  int itensPag = barbeariasItensPag,
  Map<String, dynamic>? filtrosQuery,
  double? latitude,
  double? longitude,
  bool forceRefresh = false,
}) async {
  return HttpCache.getHTTPCached(
    endpoint: AppEndpoints.endpointBarbearias,
    parameters: _parameters(
      numPag: numPag,
      itensPag: itensPag,
      filtrosQuery: filtrosQuery,
      latitude: latitude,
      longitude: longitude,
    ),
    forceRefresh: forceRefresh,
  );
}

Map<String, dynamic> _parameters({
  required int numPag,
  required int itensPag,
  Map<String, dynamic>? filtrosQuery,
  double? latitude,
  double? longitude,
}) {
  final Map<String, dynamic> parameters = <String, dynamic>{
    'num_pag': numPag,
    'itens_pag': itensPag,
  };

  if (filtrosQuery != null && filtrosQuery.isNotEmpty) {
    parameters.addAll(filtrosQuery);
  }

  if (latitude != null && longitude != null) {
    parameters['latitude'] = latitude;
    parameters['longitude'] = longitude;
  }

  return parameters;
}
