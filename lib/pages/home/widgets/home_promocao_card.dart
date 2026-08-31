import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homePromocaoCard({
  required PromocaoModel promocao,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.normal),
      backgroundColor: local.AppColors.white,
      radius: BorderRadius.circular(AppRadius.normal),
      shadow: local.AppColors.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPromocao(promocao),
          _corpoPromocao(promocao),
        ],
      ),
    ),
  );
}

Widget _cabecalhoPromocao(PromocaoModel promocao) {
  final String? badge = promocao.badgeTexto;

  return appContainer(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.normal,
      vertical: AppSpacing.normal,
    ),
    backgroundColor: local.AppColors.primary,
    radius: BorderRadius.vertical(top: Radius.circular(AppRadius.normal - 1)),
    child: Row(
      children: [
        Icon(Phosphor.tag, size: 16, color: local.AppColors.white),
        appSizedBox(width: AppSpacing.small),
        Expanded(
          child: appText(
            promocao.barbearia?.nome ?? AppStrings.vazio,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.white,
            fontSize: AppFontSizes.verySmall,
            bold: true,
          ),
        ),
        if (badge != null)
          appContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            radius: BorderRadius.circular(AppRadius.small),
            backgroundColor: local.AppColors.white.withValues(alpha: 0.18),
            child: appText(
              badge,
              bold: true,
              color: local.AppColors.white,
              fontSize: 11,
            ),
          ),
      ],
    ),
  );
}

Widget _corpoPromocao(PromocaoModel promocao) {
  final String original = promocao.valorOriginal != null
      ? formataDinheiro(promocao.valorOriginal!)
      : AppStrings.vazio;
  final String promocional = promocao.valorPromocional != null
      ? formataDinheiro(promocao.valorPromocional!)
      : AppStrings.vazio;

  return Padding(
    padding: EdgeInsets.all(AppSpacing.normal),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        appText(
          promocao.nome ?? AppStrings.vazio,
          bold: true,
          color: local.AppColors.text,
          fontSize: AppFontSizes.small,
        ),
        appSizedBox(height: AppSpacing.small),
        appText(
          promocao.descricao ?? AppStrings.vazio,
          color: local.AppColors.textSecondary,
          fontSize: AppFontSizes.verySmall,
        ),
        appSizedBox(height: AppSpacing.normal),
        Row(
          children: [
            if (original.isNotEmpty)
              appText(
                original,
                cortado: true,
                color: local.AppColors.textSecondary,
                fontSize: AppFontSizes.verySmall,
              ),
            appSizedBox(width: AppSpacing.normal),
            if (promocional.isNotEmpty)
              appText(
                promocional,
                bold: true,
                color: local.AppColors.primary,
                fontSize: AppFontSizes.small,
              ),
            const Spacer(),
            Icon(Phosphor.clock, size: 14, color: local.AppColors.textSecondary),
            appSizedBox(width: 4),
            appText(
              _formatValidade(promocao.validade),
              color: local.AppColors.textSecondary,
              fontSize: 11,
            ),
          ],
        ),
      ],
    ),
  );
}

String _formatValidade(String? iso) {
  if (iso == null || iso.isEmpty) {
    return AppStrings.vazio;
  }

  try {
    final DateTime data = DateTime.parse(iso);
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    final String ano = data.year.toString();
    return 'até $dia/$mes/$ano';
  } catch (_) {
    return iso;
  }
}
