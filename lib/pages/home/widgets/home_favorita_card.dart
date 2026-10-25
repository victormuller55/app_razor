import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homeFavoritaCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 252,
      margin: EdgeInsets.only(right: AppSpacing.normal + 2),
      padding: EdgeInsets.all(AppSpacing.normal + 2),
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 6),
      ),
      child: Row(
        children: [
          homeBarbeariaLogo(
            barbearia: barbearia,
            size: 68,
            radius: AppEstilo.raioCampo + 2,
          ),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(child: _dadosFavorita(barbearia)),
        ],
      ),
    ),
  );
}

Widget _dadosFavorita(BarbeariaModel barbearia) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: [
          Expanded(
            child: appText(
              barbearia.nome ?? AppStrings.vazio,
              bold: true,
              maxLines: 1,
              overflow: true,
              color: local.AppColors.text,
              fontSize: 14,
            ),
          ),
          appSizedBox(width: AppSpacing.small),
          const Icon(
            PhosphorFill.heart,
            size: 16,
            color: Color(0xFFE5484D),
          ),
        ],
      ),
      appText(
        barbearia.localDescricao,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.textSecondary,
        fontSize: 11,
      ),
      appSizedBox(height: AppSpacing.small + 1),
      Row(
        children: [
          homeStatusPill(barbearia),
          appSizedBox(width: AppSpacing.small + 1),
          homeNota(barbearia),
        ],
      ),
    ],
  );
}
