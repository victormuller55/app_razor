import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homePromocaoCard({
  required PromocaoModel promocao,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.normal + 2),
      padding: EdgeInsets.all(AppSpacing.medium - 4),
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPromocao(promocao),
          appSizedBox(height: AppSpacing.normal + 2),
          appText(
            promocao.nome ?? AppStrings.vazio,
            bold: true,
            color: local.AppColors.text,
            fontSize: 15,
          ),
          if ((promocao.descricao ?? '').isNotEmpty) ...[
            appSizedBox(height: 3),
            appText(
              promocao.descricao!,
              color: local.AppColors.textSecondary,
              fontSize: 12,
            ),
          ],
          appSizedBox(height: AppSpacing.normal + 2),
          _rodapePromocao(promocao),
        ],
      ),
    ),
  );
}

Widget _cabecalhoPromocao(PromocaoModel promocao) {
  final String? badge = promocao.badgeTexto;

  return Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: local.AppColors.primary,
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo - 2),
        ),
        child: const Icon(Phosphor.tag, size: 16, color: local.AppColors.white),
      ),
      appSizedBox(width: AppSpacing.normal),
      Expanded(
        child: appText(
          promocao.barbearia?.nome ?? AppStrings.vazio,
          maxLines: 1,
          overflow: true,
          color: local.AppColors.textSecondary,
          fontSize: 12,
          bold: true,
        ),
      ),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: local.AppColors.primary,
            borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
          ),
          child: appText(
            badge,
            bold: true,
            color: local.AppColors.white,
            fontSize: 11,
          ),
        ),
    ],
  );
}

Widget _rodapePromocao(PromocaoModel promocao) {
  final String original = promocao.valorOriginal != null
      ? formataDinheiro(promocao.valorOriginal!)
      : AppStrings.vazio;
  final String promocional = promocao.valorPromocional != null
      ? formataDinheiro(promocao.valorPromocional!)
      : AppStrings.vazio;
  final String validade = _formatValidade(promocao.validade);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (promocional.isNotEmpty)
        appText(
          promocional,
          bold: true,
          color: local.AppColors.primary,
          fontSize: 18,
        ),
      if (original.isNotEmpty) ...[
        appSizedBox(width: AppSpacing.small + 1),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: appText(
            original,
            cortado: true,
            color: AppEstilo.campoIcone,
            fontSize: 12,
          ),
        ),
      ],
      const Spacer(),
      if (validade.isNotEmpty) ...[
        const Icon(Phosphor.clock, size: 13, color: AppEstilo.campoIcone),
        appSizedBox(width: 3),
        appText(
          validade,
          color: local.AppColors.textSecondary,
          fontSize: 11,
        ),
      ],
    ],
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
