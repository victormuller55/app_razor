import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela interna do app com a barra de topo no mesmo visual da barra inferior:
/// fundo das telas, linha fina embaixo, título em negrito e voltar redondo.
Widget scaffoldRazor({
  required String title,
  required Widget body,
  Color? background,
  bool centerTitle = false,
  bool hideBackIcon = false,
  List<Widget>? actions,
  Widget? bottomNavigationBar,
  bool safeBottom = true,
}) {
  return Scaffold(
    backgroundColor: background ?? local.AppColors.surface,
    appBar: AppBarRazor(
      title: title,
      centerTitle: centerTitle,
      hideBackIcon: hideBackIcon,
      actions: actions,
    ),
    body: SafeArea(bottom: safeBottom, child: body),
    bottomNavigationBar: bottomNavigationBar,
  );
}

class AppBarRazor extends StatelessWidget implements PreferredSizeWidget {
  const AppBarRazor({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.hideBackIcon = false,
    this.actions,
  });

  final String title;
  final bool centerTitle;
  final bool hideBackIcon;
  final List<Widget>? actions;

  static const double altura = 60;

  @override
  Size get preferredSize => const Size.fromHeight(altura);

  @override
  Widget build(BuildContext context) {
    final bool podeVoltar = !hideBackIcon && Navigator.of(context).canPop();

    return AppBar(
      toolbarHeight: altura,
      backgroundColor: local.AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      titleSpacing: podeVoltar ? 4 : 20,
      leadingWidth: podeVoltar ? 64 : 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: local.AppColors.iconesBarraStatus,
        statusBarBrightness: local.AppColors.brilhoBarraStatus,
      ),
      shape: Border(bottom: BorderSide(color: local.AppColors.divisor)),
      leading: podeVoltar ? const Center(child: BotaoVoltarRazor()) : null,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: local.AppColors.text,
        ),
      ),
      actionsIconTheme: IconThemeData(color: local.AppColors.text),
      actions: <Widget>[...?actions, const SizedBox(width: 8)],
    );
  }
}

/// Voltar redondo em cinza, igual em todas as telas internas.
class BotaoVoltarRazor extends StatelessWidget {
  const BotaoVoltarRazor({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar',
      excludeSemantics: true,
      child: Material(
        color: AppEstilo.campoFundo,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Phosphor.caretLeft,
              size: 20,
              color: local.AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
