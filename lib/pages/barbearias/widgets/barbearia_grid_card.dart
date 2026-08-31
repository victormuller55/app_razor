import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget barbeariaGridCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: double.infinity,
      height: double.infinity,
      backgroundColor: local.AppColors.white,
      radius: BorderRadius.circular(AppRadius.normal),
      shadow: local.AppColors.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _capaCard(barbearia),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.normal,
              AppSpacing.small + 2,
              AppSpacing.normal,
              AppSpacing.small + 2,
            ),
            child: _metadadosCard(barbearia),
          ),
        ],
      ),
    ),
  );
}

Widget _capaCard(BarbeariaModel barbearia) {
  final String? logo = barbearia.logo;
  final bool temFoto = logo != null && logo.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.normal - 1),
    ),
    child: temFoto
        ? Image.network(
            logo,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _capaFallback(barbearia),
          )
        : _capaFallback(barbearia),
  );
}

Widget _capaFallback(BarbeariaModel barbearia) {
  final String nome = barbearia.nome ?? '';
  final String inicial =
      nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';

  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: nome.isEmpty
          ? Icon(
              Phosphor.scissors,
              size: 36,
              color: local.AppColors.primary,
            )
          : appText(
              inicial,
              bold: true,
              fontSize: 36,
              color: local.AppColors.primary,
            ),
    ),
  );
}

Widget _metadadosCard(BarbeariaModel barbearia) {
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
      Padding(
        padding: EdgeInsets.only(top: AppSpacing.small),
        child: _funcionamento(barbearia),
      ),
      if (barbearia.nomeServico != null && barbearia.nomeServico!.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: appText(
            barbearia.precoServico != null
                ? '${barbearia.nomeServico} · ${formataDinheiro(barbearia.precoServico!)}'
                : barbearia.nomeServico!,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      Padding(
        padding: EdgeInsets.only(top: AppSpacing.small),
        child: _notaEDistancia(barbearia),
      ),
    ],
  );
}

Widget _funcionamento(BarbeariaModel barbearia) {
  final bool aberto = barbearia.aberto ?? false;
  final Color cor = aberto
      ? local.AppColors.statusAberto
      : local.AppColors.statusFechado;
  final String status = aberto ? 'Aberto' : 'Fechado';
  final String? horario = barbearia.horarioHoje;
  final String texto = horario == null ? status : '$status · $horario';

  return Row(
    children: [
      Icon(Phosphor.clock, size: 13, color: cor),
      appSizedBox(width: 4),
      Expanded(
        child: appText(
          texto,
          maxLines: 1,
          overflow: true,
          bold: true,
          color: cor,
          fontSize: 11,
        ),
      ),
    ],
  );
}

Widget _notaEDistancia(BarbeariaModel barbearia) {
  final String nota =
      (barbearia.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
  final int? total = barbearia.totalAvaliacoes;
  final String notaTexto = total != null && total > 0 ? '$nota ($total)' : nota;
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Row(
    children: [
      Icon(Phosphor.star, size: 13, color: local.AppColors.primary),
      appSizedBox(width: 4),
      Flexible(
        child: appText(
          notaTexto,
          maxLines: 1,
          overflow: true,
          color: local.AppColors.text,
          fontSize: 11,
          bold: true,
        ),
      ),
      if (distancia != null) ...[
        appSizedBox(width: AppSpacing.small),
        Icon(Phosphor.mapPin, size: 13, color: local.AppColors.textSecondary),
        appSizedBox(width: 4),
        Flexible(
          child: appText(
            distancia,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    ],
  );
}
