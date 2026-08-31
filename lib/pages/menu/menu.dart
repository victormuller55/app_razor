import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_page.dart';
import 'package:app_razor/pages/barbearias/barbearias_page.dart';
import 'package:app_razor/pages/home/home_page.dart';
import 'package:app_razor/pages/perfil/perfil_page.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class MenuConst {
  static int currentIndex = 0;
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final List<Widget> _screens;

  bool get _iosNativo =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _selectAba(int index) {
    setState(() {
      MenuConst.currentIndex = index;
    });
  }

  void _openAbaPerfil() {
    _selectAba(3);
  }

  @override
  void initState() {
    super.initState();
    MenuConst.currentIndex = 0;
    _screens = <Widget>[
      HomePage(onOpenPerfil: _openAbaPerfil),
      const BarbeariasPage(),
      const AgendamentosPage(),
      const PerfilPage(),
    ];
  }

  BottomNavigationBarItem _itemNavegacao({
    required int index,
    required IconData icon,
    required IconData iconSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(
        MenuConst.currentIndex == index ? iconSelected : icon,
        size: 28,
      ),
      label: AppStrings.vazio,
    );
  }

  List<BottomNavigationBarItem> _itemsNavegacaoAndroid() {
    return <BottomNavigationBarItem>[
      _itemNavegacao(
        index: 0,
        icon: Phosphor.house,
        iconSelected: PhosphorFill.house,
      ),
      _itemNavegacao(
        index: 1,
        icon: Phosphor.storefront,
        iconSelected: PhosphorFill.storefront,
      ),
      _itemNavegacao(
        index: 2,
        icon: Phosphor.calendarBlank,
        iconSelected: PhosphorFill.calendarBlank,
      ),
      _itemNavegacao(
        index: 3,
        icon: Phosphor.user,
        iconSelected: PhosphorFill.user,
      ),
    ];
  }

  Widget _barraNavegacaoAndroid() {
    return BottomNavigationBar(
      backgroundColor: local.AppColors.primary,
      currentIndex: MenuConst.currentIndex,
      onTap: _selectAba,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: local.AppColors.white,
      unselectedItemColor: local.AppColors.white.withValues(alpha: 0.72),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
      items: _itemsNavegacaoAndroid(),
    );
  }

  Widget _barraNavegacaoIos() {
    return CNTabBar(
      currentIndex: MenuConst.currentIndex,
      onTap: _selectAba,
      tint: local.AppColors.primary,
      items: const <CNTabBarItem>[
        CNTabBarItem(
          label: 'Início',
          icon: CNSymbol('house'),
          activeIcon: CNSymbol('house.fill'),
        ),
        CNTabBarItem(
          label: 'Barbearias',
          icon: CNSymbol('storefront'),
          activeIcon: CNSymbol('storefront.fill'),
        ),
        CNTabBarItem(
          label: 'Agenda',
          icon: CNSymbol('calendar'),
          activeIcon: CNSymbol('calendar'),
        ),
        CNTabBarItem(
          label: 'Perfil',
          icon: CNSymbol('person'),
          activeIcon: CNSymbol('person.fill'),
        ),
      ],
    );
  }

  Widget _bodyTela() {
    return IndexedStack(
      index: MenuConst.currentIndex,
      children: _screens,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_iosNativo) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: local.AppColors.background,
          body: Stack(
            children: <Widget>[
              Positioned.fill(child: _bodyTela()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _barraNavegacaoIos(),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: local.AppColors.background,
        body: _bodyTela(),
        bottomNavigationBar: _barraNavegacaoAndroid(),
      ),
    );
  }
}
