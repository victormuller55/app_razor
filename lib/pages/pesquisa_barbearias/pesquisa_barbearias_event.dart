import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';

abstract class PesquisaBarbeariasEvent {}

class PesquisaCarregarEvent extends PesquisaBarbeariasEvent {
  final BarbeariasFiltros filtros;

  PesquisaCarregarEvent({required this.filtros});
}

class PesquisaCarregarMaisEvent extends PesquisaBarbeariasEvent {}
