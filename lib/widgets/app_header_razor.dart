import 'dart:math' as math;

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Tokens visuais do padrão "cabeçalho em gradiente + folha branca".
class AppEstilo {
  AppEstilo._();

  /// Raio da curva da folha branca sobre o cabeçalho.
  static const double raioFolha = 32;

  /// Raio de campos, botões e chips.
  static const double raioCampo = 10;

  /// Cor de destaque (barra do título).
  static const Color destaque = Color(0xFF7FB3E6);

  /// Fundo dos campos e superfícies neutras sobre a folha branca.
  static const Color campoFundo = Color(0xFFF2F4F7);

  /// Cor de ícones e textos de dica sobre [campoFundo].
  static const Color campoIcone = Color(0xFF98A0AC);

  /// Cor do tracinho de "puxar" no topo da folha.
  static const Color alca = Color(0xFFE3E6EB);
}

Widget _formaDecorativa({required double size, required double alpha}) {
  return Transform.rotate(
    angle: math.pi / 5,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: local.AppColors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
    ),
  );
}

/// Fundo do cabeçalho: gradiente com formas geométricas translúcidas.
Widget appHeaderFundo({required double altura}) {
  return Container(
    height: altura,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [local.AppColors.primaryDark, local.AppColors.primary],
      ),
    ),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -90,
          left: 60,
          child: _formaDecorativa(size: 260, alpha: 0.05),
        ),
        Positioned(
          top: -40,
          right: -70,
          child: _formaDecorativa(size: 200, alpha: 0.06),
        ),
        Positioned(
          top: altura * 0.42,
          left: -90,
          child: _formaDecorativa(size: 180, alpha: 0.04),
        ),
      ],
    ),
  );
}

/// Título branco, subtítulo e barra de destaque do cabeçalho.
Widget appHeaderTitulo({
  required String titulo,
  String? subtitulo,
  double fontSize = 30,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        titulo,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.1,
          color: local.AppColors.white,
        ),
      ),
      if (subtitulo != null) ...[
        appSizedBox(height: AppSpacing.normal),
        appText(
          subtitulo,
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.white.withValues(alpha: 0.75),
        ),
      ],
      appSizedBox(height: AppSpacing.normal + 4),
      Container(
        width: 46,
        height: 4,
        decoration: BoxDecoration(
          color: AppEstilo.destaque,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ],
  );
}

/// Tracinho de "puxar" exibido no topo da folha branca.
Widget appFolhaAlca() {
  return Center(
    child: Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppEstilo.alca,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
