import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

IconData iconeServico(String? nome) {
  final String texto = (nome ?? '').toLowerCase();

  if (texto.contains('hidrata') || texto.contains('tratamento')) {
    return Phosphor.drop;
  }

  if (texto.contains('sobrancelha')) {
    return Phosphor.sparkle;
  }

  if (texto.contains('color') ||
      texto.contains('tint') ||
      texto.contains('luzes')) {
    return Phosphor.paintBrush;
  }

  if (texto.contains('barba') && !texto.contains('corte')) {
    return Phosphor.user;
  }

  if (texto.contains('combo') || texto.contains('+')) {
    return Phosphor.scissors;
  }

  return Phosphor.scissors;
}

Widget servicoGridCard({
  required BarbeariaServicoModel servico,
  VoidCallback? onTap,
}) {
  final String? descricao = servico.descricao?.trim();
  final bool temDescricao = descricao != null && descricao.isNotEmpty;

  return GestureDetector(
    onTap: onTap,
    child: appContainer(
    width: double.infinity,
    height: double.infinity,
    padding: EdgeInsets.zero,
    backgroundColor: local.AppColors.white,
    radius: BorderRadius.circular(AppRadius.normal),
    shadow: local.AppColors.cardShadow,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _foto(servico),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.normal,
              AppSpacing.small + 2,
              AppSpacing.normal,
              AppSpacing.small + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  servico.nome ?? AppStrings.vazio,
                  bold: true,
                  maxLines: 2,
                  overflow: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.verySmall,
                ),
                if (temDescricao)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: appText(
                      descricao,
                      maxLines: 2,
                      overflow: true,
                      color: local.AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                const Spacer(),
                if (servico.preco != null)
                  appText(
                    formataDinheiro(servico.preco!),
                    bold: true,
                    color: local.AppColors.primary,
                    fontSize: AppFontSizes.small,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
    ),
  );
}

Widget _foto(BarbeariaServicoModel servico) {
  final String? imagem = servico.imagem;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return SizedBox(
    height: 96,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.normal - 1),
          ),
          child: temFoto
              ? Image.network(
                  imagem,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => _fotoFallback(servico),
                )
              : _fotoFallback(servico),
        ),
        if (servico.duracaoLabel != null)
          Positioned(
            top: 8,
            right: 8,
            child: appContainer(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              radius: BorderRadius.circular(AppRadius.medium),
              backgroundColor: local.AppColors.white.withValues(alpha: 0.92),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Phosphor.clock,
                    size: 11,
                    color: local.AppColors.textSecondary,
                  ),
                  appSizedBox(width: 3),
                  appText(
                    servico.duracaoLabel!,
                    bold: true,
                    color: local.AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _fotoFallback(BarbeariaServicoModel servico) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: Icon(
        iconeServico(servico.nome),
        size: 28,
        color: local.AppColors.primary,
      ),
    ),
  );
}
