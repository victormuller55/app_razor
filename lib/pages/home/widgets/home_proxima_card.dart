import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homeProximaCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.normal),
      padding: EdgeInsets.all(AppSpacing.normal),
      backgroundColor: local.AppColors.white,
      radius: BorderRadius.circular(AppRadius.normal),
      shadow: local.AppColors.cardShadow,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.normal),
            child: homeBarbeariaFotoStatus(barbearia: barbearia, size: 56),
          ),
          Expanded(child: _metadadosProxima(barbearia)),
        ],
      ),
    ),
  );
}

Widget _metadadosProxima(BarbeariaModel barbearia) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      appText(
        barbearia.nome ?? AppStrings.vazio,
        bold: true,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.text,
        fontSize: AppFontSizes.small,
      ),
      appText(
        barbearia.localDescricao,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.textSecondary,
        fontSize: 11,
      ),
      Padding(
        padding: EdgeInsets.only(top: AppSpacing.small),
        child: homeNotaDistancia(barbearia: barbearia),
      ),
    ],
  );
}
