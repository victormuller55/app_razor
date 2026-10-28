import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Linha de serviço selecionável: foto, nome, duração, preço e marcador.
/// Com [ordem], o marcador mostra a posição do serviço na sequência.
Widget servicoAgendamentoCard({
  required AgendamentoServicoOpcao servico,
  bool selecionado = false,
  int? ordem,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  final String? descricao = servico.descricao?.trim();
  final bool temDescricao = descricao != null && descricao.isNotEmpty;
  final String? preco = servico.preco != null
      ? formataDinheiro(servico.preco!)
      : null;
  final String? duracao = servico.duracaoLabel;

  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.normal),
      decoration: BoxDecoration(
        color: selecionado
            ? local.AppColors.primary.withValues(alpha: 0.06)
            : AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppRadii.externo),
        border: Border.all(
          color: selecionado ? local.AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _foto(servico),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  servico.nome ?? AppStrings.vazio,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.small - 1,
                ),
                if (temDescricao)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: appText(
                      descricao,
                      maxLines: 1,
                      overflow: true,
                      color: local.AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                appSizedBox(height: 6),
                Row(
                  children: [
                    if (duracao != null) ...[
                      Icon(
                        Phosphor.clock,
                        size: 13,
                        color: local.AppColors.textSecondary,
                      ),
                      appSizedBox(width: 3),
                      appText(
                        duracao,
                        color: local.AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      appSizedBox(width: AppSpacing.normal),
                    ],
                    if (preco != null)
                      appText(
                        preco,
                        bold: true,
                        color: local.AppColors.primary,
                        fontSize: AppFontSizes.verySmall + 1,
                      ),
                  ],
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.small),
          trailing ?? _marcador(selecionado, ordem: ordem),
        ],
      ),
    ),
  );
}

Widget _marcador(bool selecionado, {int? ordem}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selecionado ? local.AppColors.primary : local.AppColors.surface,
      border: Border.all(
        color: selecionado ? local.AppColors.primary : local.AppColors.contorno,
        width: 1.5,
      ),
    ),
    child: !selecionado
        ? null
        : ordem != null
        ? Center(
            child: appText(
              '$ordem',
              bold: true,
              color: local.AppColors.white,
              fontSize: 12,
            ),
          )
        : const Icon(Phosphor.check, size: 13, color: local.AppColors.white),
  );
}

Widget _foto(AgendamentoServicoOpcao servico) {
  const double size = 60;
  final String? imagem = servico.imagem;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.interno + 4),
    child: SizedBox(
      width: size,
      height: size,
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: size,
              height: size,
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
        size: 24,
        color: local.AppColors.primary,
      ),
    ),
  );
}
