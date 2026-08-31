import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/menu/menu.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:muller_package/muller_package.dart';
import 'package:snacky/snacky.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  Widget _home = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    _decidirHome();
  }

  Future<void> _decidirHome() async {
    bool autenticado = false;

    try {
      autenticado = await hasLocalData();
    } catch (_) {
      autenticado = false;
    }

    FlutterNativeSplash.remove();

    if (!mounted) {
      return;
    }

    setState(() {
      _home = autenticado ? const MenuScreen() : const LoginPage();
    });
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: local.AppColors.background,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: local.AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: AppFonts.family,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Razor',
      navigatorKey: AppContext.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      navigatorObservers: [
        SnackyNavigationObserver(),
        CNTabBarRouteObserver(),
      ],
      home: _home,
    );
  }
}
