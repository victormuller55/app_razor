import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget agendamentoListaCard({
  required AgendamentoModel agendamento,
  VoidCallback? onComoChegar,
  VoidCallback? onCancelar,
  bool cancelando = false,
}) {
  return appContainer(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: AppSpacing.normal),
    padding: EdgeInsets.all(AppSpacing.normal),
    backgroundColor: local.AppColors.white,
    radius: BorderRadius.circular(AppRadius.normal),
    shadow: local.AppColors.cardShadow,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _foto(agendamento),
            appSizedBox(width: AppSpacing.normal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: appText(
                          agendamento.nomeServico ?? AppStrings.vazio,
                          bold: true,
                          maxLines: 2,
                          overflow: true,
                          color: local.AppColors.text,
                          fontSize: AppFontSizes.small,
                        ),
                      ),
                      appSizedBox(width: 8),
                      _status(agendamento),
                    ],
                  ),
                  if (agendamento.nomeBarbearia != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: appText(
                        agendamento.nomeBarbearia!,
                        maxLines: 1,
                        overflow: true,
                        color: local.AppColors.textSecondary,
                        fontSize: AppFontSizes.verySmall,
                      ),
                    ),
                  if (agendamento.preco != null)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: appText(
                        formataDinheiro(agendamento.preco!),
                        bold: true,
                        color: local.AppColors.primary,
                        fontSize: AppFontSizes.small,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        appSizedBox(height: AppSpacing.normal),
        if (agendamento.periodoLabel.isNotEmpty)
          _linha(
            icone: Phosphor.calendarBlank,
            texto: agendamento.periodoLabel,
            destaque: true,
          ),
        if (agendamento.duracaoLabel != null)
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: _linha(
              icone: Phosphor.clock,
              texto: agendamento.duracaoLabel!,
            ),
          ),
        if (agendamento.nomeFuncionario != null)
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: _linha(
              icone: Phosphor.user,
              texto: agendamento.nomeFuncionario!,
            ),
          ),
        if (agendamento.enderecoCompleto != null)
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: _linha(
              icone: Phosphor.mapPin,
              texto: agendamento.enderecoCompleto!,
            ),
          ),
        if (agendamento.observacao != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.small),
            child: appContainer(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.small),
              radius: BorderRadius.circular(AppRadius.medium),
              backgroundColor: local.AppColors.inputBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Phosphor.notePencil,
                    size: 14,
                    color: local.AppColors.textSecondary,
                  ),
                  appSizedBox(width: 6),
                  Expanded(
                    child: appText(
                      agendamento.observacao!,
                      color: local.AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if ((!agendamento.cancelado && onComoChegar != null) ||
            (onCancelar != null && agendamento.podeCancelar))
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.normal),
            child: Row(
              children: [
                if (!agendamento.cancelado && onComoChegar != null)
                  Expanded(
                    child: _botaoAcao(
                      icone: Phosphor.navigationArrow,
                      texto: 'Como chegar',
                      cor: local.AppColors.primary,
                      onTap: onComoChegar,
                    ),
                  ),
                if (!agendamento.cancelado &&
                    onComoChegar != null &&
                    onCancelar != null &&
                    agendamento.podeCancelar)
                  appSizedBox(width: AppSpacing.small),
                if (onCancelar != null && agendamento.podeCancelar)
                  Expanded(
                    child: _botaoAcao(
                      icone: Phosphor.xCircle,
                      texto: cancelando ? 'Cancelando...' : 'Cancelar',
                      cor: const Color(0xFFB3261E),
                      onTap: cancelando ? () {} : onCancelar,
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _botaoAcao({
  required IconData icone,
  required String texto,
  required Color cor,
  required VoidCallback onTap,
}) {
  return Material(
    color: cor.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(AppRadius.medium),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 16, color: cor),
            appSizedBox(width: 6),
            appText(
              texto,
              bold: true,
              color: cor,
              fontSize: AppFontSizes.verySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _status(AgendamentoModel agendamento) {
  final Color cor = agendamento.cancelado
      ? const Color(0xFFB3261E)
      : local.AppColors.primary;

  return appContainer(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    radius: BorderRadius.circular(AppRadius.medium),
    backgroundColor: cor.withValues(alpha: 0.08),
    child: appText(
      agendamento.statusLabel,
      bold: true,
      color: cor,
      fontSize: 11,
    ),
  );
}

Widget _linha({
  required IconData icone,
  required String texto,
  bool destaque = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icone,
        size: 14,
        color: destaque ? local.AppColors.primary : local.AppColors.textSecondary,
      ),
      appSizedBox(width: 6),
      Expanded(
        child: appText(
          texto,
          bold: destaque,
          color: destaque ? local.AppColors.text : local.AppColors.textSecondary,
          fontSize: AppFontSizes.verySmall,
        ),
      ),
    ],
  );
}

Widget _foto(AgendamentoModel agendamento) {
  final String? imagem = agendamento.foto;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.medium),
    child: SizedBox(
      width: 72,
      height: 72,
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: 72,
              height: 72,
              errorBuilder: (_, _, _) => _fotoFallback(agendamento),
            )
          : _fotoFallback(agendamento),
    ),
  );
}

Widget _fotoFallback(AgendamentoModel agendamento) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: Icon(
        iconeServico(agendamento.nomeServico),
        size: 28,
        color: local.AppColors.primary,
      ),
    ),
  );
}
