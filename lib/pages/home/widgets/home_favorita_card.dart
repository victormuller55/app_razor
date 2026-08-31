import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homeFavoritaCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: 248,
      margin: EdgeInsets.only(right: AppSpacing.normal),
      padding: EdgeInsets.all(AppSpacing.normal),
      backgroundColor: local.AppColors.primary.withValues(alpha: 0.08),
      radius: BorderRadius.circular(AppRadius.normal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoFavorita(barbearia),
          _metricasFavorita(barbearia),
        ],
      ),
    ),
  );
}

Widget _cabecalhoFavorita(BarbeariaModel barbearia) {
  return Row(
    children: [
      Padding(
        padding: EdgeInsets.only(right: AppSpacing.normal),
        child: homeBarbeariaFotoStatus(barbearia: barbearia, size: 42),
      ),
      Expanded(child: _dadosFavorita(barbearia)),
      Padding(
        padding: EdgeInsets.only(left: AppSpacing.small),
        child: Icon(
          PhosphorFill.heart,
          size: 18,
          color: local.AppColors.primary,
        ),
      ),
    ],
  );
}

Widget _dadosFavorita(BarbeariaModel barbearia) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      appText(
        barbearia.nome ?? AppStrings.vazio,
        bold: true,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.text,
        fontSize: AppFontSizes.verySmall,
      ),
      appText(
        barbearia.localDescricao,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.textSecondary,
        fontSize: 11,
      ),
    ],
  );
}

Widget _metricasFavorita(BarbeariaModel barbearia) {
  final String nota =
      (barbearia.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Row(
    children: [
      _itemMetrica(
        icone: Phosphor.star,
        texto: nota,
        corIcone: local.AppColors.primary,
        corTexto: local.AppColors.text,
      ),
      if (distancia != null) ...[
        const Spacer(),
        _itemMetrica(
          icone: Phosphor.mapPin,
          texto: distancia,
          corIcone: local.AppColors.textSecondary,
          corTexto: local.AppColors.textSecondary,
        ),
      ],
    ],
  );
}

Widget _itemMetrica({
  required IconData icone,
  required String texto,
  required Color corIcone,
  required Color corTexto,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icone, size: 14, color: corIcone),
      appSizedBox(width: 4),
      appText(
        texto,
        color: corTexto,
        fontSize: AppFontSizes.verySmall,
        bold: true,
      ),
    ],
  );
}
