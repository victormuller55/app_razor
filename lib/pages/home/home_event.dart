abstract class HomeEvent {}

class HomeLoadEvent extends HomeEvent {
  final bool forceRefresh;

  HomeLoadEvent({
    this.forceRefresh = false,
  });
}
