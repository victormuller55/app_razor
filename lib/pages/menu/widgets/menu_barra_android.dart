import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuBarraItem {
  const MenuBarraItem({
    required this.label,
    required this.icon,
    required this.iconSelecionado,
  });

  final String label;
  final IconData icon;
  final IconData iconSelecionado;
}

/// Barra inferior do Android: fundo das telas, pílula atrás do ícone da aba
/// atual e nome curto embaixo, no mesmo espírito da barra nativa do iOS.
class MenuBarraAndroid extends StatelessWidget {
  const MenuBarraAndroid({
    super.key,
    required this.itens,
    required this.indiceAtual,
    required this.onSelecionar,
  });

  final List<MenuBarraItem> itens;
  final int indiceAtual;
  final ValueChanged<int> onSelecionar;

  static const Duration _duracao = Duration(milliseconds: 260);

  void _tocar(int index) {
    if (index != indiceAtual) {
      HapticFeedback.selectionClick();
    }
    onSelecionar(index);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: local.AppColors.surface,
        border: Border(top: BorderSide(color: local.AppColors.divisor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < itens.length; i++)
                Expanded(child: _item(i, itens[i], i == indiceAtual)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, MenuBarraItem item, bool selecionado) {
    final Color cor =
        selecionado ? local.AppColors.primary : local.AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selecionado,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => _tocar(index),
        radius: 36,
        highlightColor: Colors.transparent,
        splashColor: local.AppColors.primary.withValues(alpha: 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: _duracao,
              curve: Curves.easeOutCubic,
              width: selecionado ? 60 : 40,
              height: 32,
              decoration: BoxDecoration(
                color: selecionado
                    ? local.AppColors.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedSwitcher(
                duration: _duracao,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  selecionado ? item.iconSelecionado : item.icon,
                  key: ValueKey<bool>(selecionado),
                  size: 22,
                  color: cor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: _duracao,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 11.5,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                color: cor,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
