import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget servicoAgendamentoCard({
  required AgendamentoServicoOpcao servico,
  bool selecionado = false,
  VoidCallback? onTap,
}) {
  final String? descricao = servico.descricao?.trim();
  final bool temDescricao = descricao != null && descricao.isNotEmpty;
  final String? preco =
      servico.preco != null ? formataDinheiro(servico.preco!) : null;

  final Widget conteudo = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _foto(servico),
      appSizedBox(width: AppSpacing.normal),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appText(
              servico.nome ?? AppStrings.vazio,
              bold: true,
              maxLines: 2,
              overflow: true,
              color: selecionado ? local.AppColors.primary : local.AppColors.text,
              fontSize: AppFontSizes.small,
            ),
            if (temDescricao)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: appText(
                  descricao,
                  maxLines: 2,
                  overflow: true,
                  color: local.AppColors.textSecondary,
                  fontSize: AppFontSizes.verySmall,
                ),
              ),
            if (servico.duracaoLabel != null || preco != null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.small),
                child: Row(
                  children: [
                    if (servico.duracaoLabel != null)
                      appContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        radius: BorderRadius.circular(AppRadius.medium),
                        backgroundColor: selecionado
                            ? local.AppColors.white
                            : local.AppColors.inputBackground,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Phosphor.clock,
                              size: 12,
                              color: local.AppColors.textSecondary,
                            ),
                            appSizedBox(width: 4),
                            appText(
                              servico.duracaoLabel!,
                              bold: true,
                              color: local.AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                    if (servico.duracaoLabel != null && preco != null)
                      appSizedBox(width: 8),
                    if (preco != null)
                      appText(
                        preco,
                        bold: true,
                        color: local.AppColors.primary,
                        fontSize: AppFontSizes.small,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  if (onTap == null) {
    return conteudo;
  }

  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.small),
      backgroundColor: selecionado
          ? local.AppColors.primary.withValues(alpha: 0.12)
          : local.AppColors.inputBackground,
      radius: BorderRadius.circular(AppRadius.medium),
      border: selecionado ? Border.all(color: local.AppColors.primary) : null,
      child: conteudo,
    ),
  );
}

Widget _foto(AgendamentoServicoOpcao servico) {
  final String? imagem = servico.imagem;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.medium),
    child: SizedBox(
      width: 88,
      height: 88,
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: 88,
              height: 88,
              errorBuilder: (_, _, _) => _fotoFallback(servico),
            )
          : _fotoFallback(servico),
    ),
  );
}

Widget _fotoFallback(AgendamentoServicoOpcao servico) {
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
