import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';

abstract class BarbeariasEvent {}

class BarbeariasLoadEvent extends BarbeariasEvent {
  final BarbeariasFiltros filtros;
  final bool forceRefresh;

  BarbeariasLoadEvent({
    BarbeariasFiltros? filtros,
    this.forceRefresh = false,
  }) : filtros = filtros ?? BarbeariasFiltros.empty();
}

class BarbeariasLoadMoreEvent extends BarbeariasEvent {}
