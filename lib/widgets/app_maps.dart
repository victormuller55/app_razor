import 'dart:math' as math;

import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/widgets/app_marcador_barbearia.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppMaps {
  AppMaps._();

  static Marker markerFromBarbearia(
    BarbeariaModel barbearia, {
    void Function(BarbeariaModel barbearia)? onTap,
    ({BitmapDescriptor icone, Offset ancora})? marcador,
  }) {
    return Marker(
      markerId: MarkerId('${barbearia.id ?? barbearia.nome}'),
      position: LatLng(barbearia.latitude ?? 0, barbearia.longitude ?? 0),
      icon: marcador?.icone ?? BitmapDescriptor.defaultMarker,
      anchor: marcador?.ancora ?? const Offset(0.5, 1),
      // Enquanto o pino com nome não fica pronto, o marcador padrão não aparece.
      visible: marcador != null,
      consumeTapEvents: onTap != null,
      onTap: onTap == null ? null : () => onTap(barbearia),
      infoWindow: onTap != null
          ? const InfoWindow()
          : InfoWindow(
              title: barbearia.nome ?? '',
              snippet: barbearia.localDescricao,
            ),
    );
  }

  static LatLngBounds boundsFor({
    required double latitude,
    required double longitude,
    List<BarbeariaModel> barbearias = const <BarbeariaModel>[],
  }) {
    double minLat = latitude;
    double maxLat = latitude;
    double minLng = longitude;
    double maxLng = longitude;

    for (final BarbeariaModel barbearia in barbearias) {
      final double? lat = barbearia.latitude;
      final double? lng = barbearia.longitude;

      if (lat == null || lng == null) {
        continue;
      }

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    if (minLat == maxLat) {
      minLat -= 0.01;
      maxLat += 0.01;
    }

    if (minLng == maxLng) {
      minLng -= 0.01;
      maxLng += 0.01;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static Widget map({
    required double latitude,
    required double longitude,
    List<BarbeariaModel> barbearias = const <BarbeariaModel>[],
    void Function(LatLng)? onTap,
    void Function(BarbeariaModel barbearia)? onBarbeariaTap,
    void Function(GoogleMapController controller)? onMapCreated,
    bool interactive = true,
    bool myLocationEnabled = false,
    double zoom = 15,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return _AppMapa(
      latitude: latitude,
      longitude: longitude,
      barbearias: barbearias,
      onTap: onTap,
      onBarbeariaTap: onBarbeariaTap,
      onMapCreated: onMapCreated,
      interactive: interactive,
      myLocationEnabled: myLocationEnabled,
      zoom: zoom,
      padding: padding,
    );
  }
}

class _AppMapa extends StatefulWidget {
  const _AppMapa({
    required this.latitude,
    required this.longitude,
    required this.barbearias,
    this.onTap,
    this.onBarbeariaTap,
    this.onMapCreated,
    required this.interactive,
    required this.myLocationEnabled,
    required this.zoom,
    required this.padding,
  });

  final double latitude;
  final double longitude;
  final List<BarbeariaModel> barbearias;
  final void Function(LatLng)? onTap;
  final void Function(BarbeariaModel barbearia)? onBarbeariaTap;
  final void Function(GoogleMapController controller)? onMapCreated;
  final bool interactive;
  final bool myLocationEnabled;
  final double zoom;
  final EdgeInsets padding;

  @override
  State<_AppMapa> createState() => _AppMapaState();
}

class _AppMapaState extends State<_AppMapa> {
  final Map<String, ({BitmapDescriptor icone, Offset ancora})> _marcadores =
      <String, ({BitmapDescriptor icone, Offset ancora})>{};

  @override
  void initState() {
    super.initState();
    _gerarMarcadores();
  }

  @override
  void didUpdateWidget(covariant _AppMapa oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.barbearias != widget.barbearias) {
      _gerarMarcadores();
    }
  }

  Future<void> _gerarMarcadores() async {
    // Os que já foram desenhados (em outro mapa) entram direto, sem um quadro de espera.
    for (final BarbeariaModel barbearia in widget.barbearias) {
      final String nome = barbearia.nome ?? '';
      final ({BitmapDescriptor icone, Offset ancora})? pronto =
          AppMarcadorBarbearia.pronto(nome);

      if (pronto != null) {
        _marcadores[nome] = pronto;
      }
    }

    for (final BarbeariaModel barbearia in widget.barbearias) {
      final String nome = barbearia.nome ?? '';

      if (_marcadores.containsKey(nome)) {
        continue;
      }

      final ({BitmapDescriptor icone, Offset ancora}) marcador =
          await AppMarcadorBarbearia.gerar(nome);

      if (!mounted) {
        return;
      }

      setState(() {
        _marcadores[nome] = marcador;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = widget.latitude;
    final double longitude = widget.longitude;
    final double zoom = widget.zoom;
    final bool interactive = widget.interactive;
    final void Function(GoogleMapController controller)? onMapCreated =
        widget.onMapCreated;

    final Set<Marker> markers = widget.barbearias
        .where((BarbeariaModel item) {
          return item.latitude != null && item.longitude != null;
        })
        .map(
          (BarbeariaModel barbearia) => AppMaps.markerFromBarbearia(
            barbearia,
            onTap: widget.onBarbeariaTap,
            marcador: _marcadores[barbearia.nome ?? ''],
          ),
        )
        .toSet();

    final CameraPosition camera = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
      bearing: 0,
      tilt: 0,
    );

    return GoogleMap(
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      padding: widget.padding,
      onTap: widget.onTap,
      markers: markers,
      initialCameraPosition: camera,
      onMapCreated: (GoogleMapController controller) {
        controller.moveCamera(CameraUpdate.newCameraPosition(camera));
        onMapCreated?.call(controller);
      },
      gestureRecognizers: interactive
          ? <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            }
          : const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}
