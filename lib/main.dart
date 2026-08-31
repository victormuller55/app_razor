import 'package:app_razor/app_config/app_widget.dart';
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

void main() {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  _initGoogleMaps();
  runApp(const AppWidget());
}