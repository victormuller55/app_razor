import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget homeBarbeariaLogo({
  required BarbeariaModel barbearia,
  double size = 48,
}) {
  final String? logo = barbearia.logo;
  final bool temFoto = logo != null && logo.isNotEmpty;

  return ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: temFoto
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _logoFallback(barbearia, size),
            )
          : _logoFallback(barbearia, size),
    ),
  );
}

Widget homeBarbeariaFotoStatus({
  required BarbeariaModel barbearia,
  double size = 48,
}) {
  final bool aberto = barbearia.aberto ?? false;

  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        homeBarbeariaLogo(barbearia: barbearia, size: size),
        Positioned(
          right: -1,
          bottom: -1,
          child: appContainer(
            width: 12,
            height: 12,
            shape: BoxShape.circle,
            backgroundColor: aberto
                ? local.AppColors.statusAberto
                : local.AppColors.statusFechado,
            border: Border.all(color: local.AppColors.white, width: 2),
          ),
        ),
      ],
    ),
  );
}

Widget _logoFallback(BarbeariaModel barbearia, double size) {
  final String nome = barbearia.nome ?? '';
  final String inicial =
      nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';

  return appContainer(
    width: size,
    height: size,
    radius: BorderRadius.circular(size),
    backgroundColor: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: nome.isEmpty
          ? Icon(
              Phosphor.scissors,
              size: size * 0.45,
              color: local.AppColors.primary,
            )
          : appText(
              inicial,
              bold: true,
              fontSize: size * 0.38,
              color: local.AppColors.primary,
            ),
    ),
  );
}

String? homeTextoDistanciaKm(double? distanciaKm) {
  if (distanciaKm == null) {
    return null;
  }

  return '${distanciaKm.toStringAsFixed(1).replaceAll('.', ',')} km';
}

Widget homeNotaDistancia({
  required BarbeariaModel barbearia,
}) {
  final String nota =
      (barbearia.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Phosphor.star, size: 14, color: local.AppColors.primary),
      appSizedBox(width: 4),
      appText(
        nota,
        color: local.AppColors.text,
        fontSize: AppFontSizes.verySmall,
        bold: true,
      ),
      if (distancia != null) ...[
        appSizedBox(width: AppSpacing.normal),
        Icon(Phosphor.mapPin, size: 14, color: local.AppColors.textSecondary),
        appSizedBox(width: 4),
        appText(
          distancia,
          color: local.AppColors.textSecondary,
          fontSize: AppFontSizes.verySmall,
        ),
      ],
    ],
  );
}
