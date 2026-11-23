/// Estilo do Google Maps no modo escuro: fundo quase preto e cinzas neutros,
/// no mesmo tom das telas, com ruas, nomes e água ainda legíveis.
const String estiloMapaEscuro = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a1a"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8e8e93"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a1a"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3a3a3c"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#c7c7cc"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#202020"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1c241c"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#5f6b5f"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1a1a1a"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8e8e93"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#333335"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a3a3c"}]},
  {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#444446"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#6e6e73"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#242426"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1418"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e5a62"}]}
]
''';
