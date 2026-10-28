import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Linha de barbearia próxima: foto arredondada, dados e status.
/// [divisor] desenha a linha separadora abaixo do item.
Widget homeProximaCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
  bool divisor = true,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.normal + 2),
      decoration: BoxDecoration(
        border: divisor
            ? Border(
                bottom: BorderSide(
                  color: local.AppColors.escuro
                      ? local.AppColors.divisor
                      : const Color(0xFFEDEFF3),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          homeBarbeariaLogo(
            barbearia: barbearia,
            size: 64,
            radius: AppEstilo.raioCampo + 4,
          ),
          appSizedBox(width: AppSpacing.normal + 4),
          Expanded(child: _metadadosProxima(barbearia)),
          appSizedBox(width: AppSpacing.small),
          Icon(
            Phosphor.caretRight,
            size: 18,
            color: AppEstilo.campoIcone,
          ),
        ],
      ),
    ),
  );
}

Widget _metadadosProxima(BarbeariaModel barbearia) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(
            child: appText(
              barbearia.nome ?? AppStrings.vazio,
              bold: true,
              maxLines: 1,
              overflow: true,
              color: local.AppColors.text,
              fontSize: 15,
            ),
          ),
          appSizedBox(width: AppSpacing.small + 1),
          homeStatusPill(barbearia),
        ],
      ),
      appSizedBox(height: 2),
      appText(
        barbearia.localDescricao,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.textSecondary,
        fontSize: 12,
      ),
      appSizedBox(height: AppSpacing.small + 1),
      homeNotaDistancia(barbearia: barbearia),
    ],
  );
}

/// Selo de "Aberto"/"Fechado" no padrão dos campos.
Widget homeStatusPill(BarbeariaModel barbearia) {
  final bool aberto = barbearia.aberto ?? false;
  final Color cor = aberto
      ? local.AppColors.statusAberto
      : local.AppColors.statusFechado;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    ),
    child: appText(
      aberto ? 'Aberto' : 'Fechado',
      bold: true,
      fontSize: 10,
      color: aberto ? cor : local.AppColors.textSecondary,
    ),
  );
}
