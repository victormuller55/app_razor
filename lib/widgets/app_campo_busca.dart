import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

const double appCampoBuscaAltura = 52;

/// Atalho com cara de campo de busca que só abre a tela de pesquisa.
///
/// Não é um TextField de propósito: assim nunca recebe foco nem abre o
/// teclado (inclusive ao voltar da tela de pesquisa).
Widget appCampoBusca({required VoidCallback onTap}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: appCampoBuscaAltura,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium - 4),
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      ),
      child: Row(
        children: [
          const Icon(
            Phosphor.magnifyingGlass,
            size: 20,
            color: AppEstilo.campoIcone,
          ),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(
            child: appText(
              AppStrings.digiteAlgoParaPesquisar,
              color: AppEstilo.campoIcone,
              fontSize: 15,
              maxLines: 1,
              overflow: true,
            ),
          ),
        ],
      ),
    ),
  );
}
