import 'dart:async';

import 'package:app_razor/app_config/app_widget.dart';
import 'package:app_razor/functions/push_notificacoes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void _initGoogleMaps() {
  final GoogleMapsFlutterPlatform maps = GoogleMapsFlutterPlatform.instance;

  if (!kIsWeb && maps is GoogleMapsFlutterAndroid) {
    maps.useAndroidViewSurface = true;
  }
}

/// O muller_package imprime o corpo de cada resposta (o login traz o JWT, o Pix traz o código). Na versão
/// de loja esses prints iriam para o log do aparelho; ali eles são descartados.
void silenciarPrintsEmProducao(void Function() corpo, {bool producao = kReleaseMode}) {
  runZoned(
    corpo,
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String linha) {
        if (!producao) {
          parent.print(zone, linha);
        }
      },
    ),
  );
}

void main() {
  silenciarPrintsEmProducao(() async {
    final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    _initGoogleMaps();
    await PushNotificacoes.instance.inicializar();
    runApp(const AppWidget());
  });
}