import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/tema_controller.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/menu/menu.dart';
import 'package:app_razor/pages/permissoes/permissoes_page.dart';
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

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  Widget _home = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    temaController.addListener(_aplicarTema);
    _decidirHome();
  }

  @override
  void dispose() {
    temaController.removeListener(_aplicarTema);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _aplicarTema();
  }

  void _aplicarTema() {
    final bool escuro = temaController.escuroCom(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    if (escuro == local.AppColors.escuro || !mounted) {
      return;
    }

    setState(() => local.AppColors.escuro = escuro);

    // As telas leem as cores direto de AppColors, sem depender do Theme; por
    // isso tudo o que está aberto (rotas empilhadas e folhas inclusive) é
    // reconstruído.
    void reconstruir(Element element) {
      element.markNeedsBuild();
      element.visitChildren(reconstruir);
    }

    (context as Element).visitChildren(reconstruir);
  }

  Future<void> _decidirHome() async {
    bool autenticado = false;
    bool localizacao = false;

    try {
      await temaController.carregar();
    } catch (_) {}

    try {
      autenticado = await hasLocalData();
      localizacao = autenticado && await localizacaoPermitida();
    } catch (_) {
      autenticado = false;
    }

    FlutterNativeSplash.remove();

    if (!mounted) {
      return;
    }

    setState(() {
      if (!autenticado) {
        _home = const LoginPage();
      } else {
        _home = localizacao ? const MenuScreen() : const PermissoesPage();
      }
    });
  }

  ThemeData _buildTheme() {
    final Brightness brilho =
    local.AppColors.escuro ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: local.AppColors.background,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: local.AppColors.primaryBrand,
        brightness: brilho,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: local.AppColors.surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.externo),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.externo),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.externo),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo),
        ),
      ),
      textTheme: ThemeData(brightness: brilho).textTheme.apply(
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
      themeAnimationDuration: Duration.zero,
      navigatorObservers: [
        SnackyNavigationObserver(),
        CNTabBarRouteObserver(),
      ],
      home: _home,
    );
  }
}
