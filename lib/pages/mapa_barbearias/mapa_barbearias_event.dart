abstract class MapaBarbeariasEvent {}

class MapaBarbeariasLoadEvent extends MapaBarbeariasEvent {
  MapaBarbeariasLoadEvent({this.forceRefresh = false});

  final bool forceRefresh;
}
