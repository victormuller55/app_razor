abstract class BarbeariaPerfilEvent {}

class BarbeariaPerfilLoadEvent extends BarbeariaPerfilEvent {
  final bool forceRefresh;

  BarbeariaPerfilLoadEvent({this.forceRefresh = false});
}

/// Marca ou desmarca a barbearia como favorita.
class BarbeariaPerfilFavoritoEvent extends BarbeariaPerfilEvent {}
