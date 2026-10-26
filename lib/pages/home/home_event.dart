abstract class HomeEvent {}

class HomeLoadEvent extends HomeEvent {
  final bool forceRefresh;

  HomeLoadEvent({
    this.forceRefresh = false,
  });
}

/// Recarrega só a seção "Barbearias Favoritas".
class HomeFavoritasEvent extends HomeEvent {}
