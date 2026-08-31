abstract class BarbeariaPerfilEvent {}

class BarbeariaPerfilLoadEvent extends BarbeariaPerfilEvent {
  final bool forceRefresh;

  BarbeariaPerfilLoadEvent({
    this.forceRefresh = false,
  });
}
