import 'dart:math' as math;

import 'package:app_razor/models/barbearia_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppMaps {
  AppMaps._();

  static Marker markerFromBarbearia(
    BarbeariaModel barbearia, {
    void Function(BarbeariaModel barbearia)? onTap,
  }) {
    return Marker(
      markerId: MarkerId('${barbearia.id ?? barbearia.nome}'),
      position: LatLng(
        barbearia.latitude ?? 0,
        barbearia.longitude ?? 0,
      ),
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
    final Set<Marker> markers = barbearias
        .where((BarbeariaModel item) {
          return item.latitude != null && item.longitude != null;
        })
        .map(
          (BarbeariaModel barbearia) => markerFromBarbearia(
            barbearia,
            onTap: onBarbeariaTap,
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
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      padding: padding,
      onTap: onTap,
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
