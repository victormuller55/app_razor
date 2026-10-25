import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Logo/foto da barbearia. Circular por padrão; com [radius], vira um
/// quadrado de cantos arredondados.
Widget homeBarbeariaLogo({
  required BarbeariaModel barbearia,
  double size = 48,
  double? radius,
}) {
  final String? logo = barbearia.logo;
  final bool temFoto = logo != null && logo.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(radius ?? size),
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

  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [local.AppColors.primary, local.AppColors.primaryLight],
      ),
    ),
    child: Center(
      child: nome.isEmpty
          ? Icon(
              Phosphor.scissors,
              size: size * 0.45,
              color: local.AppColors.white,
            )
          : appText(
              inicial,
              bold: true,
              fontSize: size * 0.38,
              color: local.AppColors.white,
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

/// Estrela amarela com a nota da barbearia.
Widget homeNota(BarbeariaModel barbearia) {
  final String nota =
      (barbearia.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(PhosphorFill.star, size: 13, color: Color(0xFFF2B01E)),
      appSizedBox(width: 3),
      appText(
        nota,
        color: local.AppColors.text,
        fontSize: 12,
        bold: true,
      ),
    ],
  );
}

Widget homeNotaDistancia({
  required BarbeariaModel barbearia,
}) {
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      homeNota(barbearia),
      if (distancia != null) ...[
        appSizedBox(width: AppSpacing.normal),
        const Icon(Phosphor.mapPin, size: 13, color: Color(0xFF98A0AC)),
        appSizedBox(width: 3),
        appText(
          distancia,
          color: local.AppColors.textSecondary,
          fontSize: 12,
        ),
      ],
    ],
  );
}
