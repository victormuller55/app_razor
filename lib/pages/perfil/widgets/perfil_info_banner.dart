import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/pages/perfil/widgets/perfil_form_lista.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Aviso no topo das telas de configuração: no mínimo da altura do campo e do
/// botão, com o texto centralizado na vertical.
Widget perfilInfoBanner({required List<String> linhas, IconData? icon}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: perfilAlturaItem),
    child: appContainer(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.normal + AppSpacing.small,
        vertical: AppSpacing.normal,
      ),
      radius: BorderRadius.circular(AppEstilo.raioCampo),
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: local.AppColors.white, size: 18),
            appSizedBox(width: AppSpacing.normal),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < linhas.length; i++) ...[
                  if (i > 0) appSizedBox(height: AppSpacing.small),
                  appText(
                    linhas[i],
                    color: local.AppColors.white,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
