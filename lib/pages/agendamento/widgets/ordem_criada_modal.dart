import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/ordem_servico_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_modal.dart';
import 'package:app_razor/pages/pagamento/pagar_ordem_servico.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Resumo do que acabou de ser reservado, com a opção de pagar na hora.
/// Fecha sozinho depois do pagamento ou quando o cliente deixa para depois.
Future<void> showOrdemCriadaModal({
  required BuildContext context,
  required List<AgendamentoModel> agendamentos,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) =>
        _OrdemCriadaSheet(agendamentos: agendamentos),
  );
}

class _OrdemCriadaSheet extends StatelessWidget {
  const _OrdemCriadaSheet({required this.agendamentos});

  final List<AgendamentoModel> agendamentos;

  bool get _ordem => agendamentos.length > 1;

  double get _total => agendamentos.fold<double>(
    0,
    (double soma, AgendamentoModel item) => soma + (item.preco ?? 0),
  );

  bool get _podePagar =>
      agendamentos.any((AgendamentoModel item) => item.podePagarPeloApp);

  /// Um serviço só paga o Pix dele; a ordem paga tudo num Pix só.
  Future<void> _pagar(BuildContext context) async {
    final String? idOrdem = agendamentos.first.idOrdemServico;
    if (!_ordem || idOrdem == null) {
      await showPagamentoModal(
        context: context,
        agendamento: agendamentos.first,
      );
      return;
    }
    await pagarOrdemServico(
      context: context,
      ordem: OrdemServicoGrupo(id: idOrdem, itens: agendamentos),
    );
  }

  Widget _item(AgendamentoModel item) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.small + 3),
      child: Row(
        children: [
          appContainer(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            backgroundColor: local.AppColors.white,
            radius: BorderRadius.circular(AppRadii.interno),
            child: Column(
              children: [
                appText(
                  item.horaLabel,
                  bold: true,
                  color: local.AppColors.primary,
                  fontSize: AppFontSizes.verySmall,
                ),
                appText(
                  item.dataLabel.length >= 5
                      ? item.dataLabel.substring(0, 5)
                      : item.dataLabel,
                  color: local.AppColors.textSecondary,
                  fontSize: 10,
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  item.nomeServico ?? AppStrings.vazio,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.verySmall + 1,
                ),
                if (item.nomeFuncionario != null)
                  appText(
                    'com ${item.nomeFuncionario}',
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.textSecondary,
                    fontSize: 12,
                  ),
              ],
            ),
          ),
          if (item.preco != null)
            appText(
              formataDinheiro(item.preco!),
              bold: true,
              color: local.AppColors.text,
              fontSize: AppFontSizes.verySmall,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: local.AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppEstilo.raioFolha),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal + 2,
        AppSpacing.medium,
        AppSpacing.medium + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          appFolhaAlca(),
          appSizedBox(height: AppSpacing.medium),
          Center(
            child: appContainer(
              width: 64,
              height: 64,
              backgroundColor: local.AppColors.statusAberto.withValues(
                alpha: 0.12,
              ),
              radius: BorderRadius.circular(32),
              child: const Center(
                child: Icon(
                  Phosphor.checkCircle,
                  size: 34,
                  color: local.AppColors.statusAberto,
                ),
              ),
            ),
          ),
          appSizedBox(height: AppSpacing.normal + 2),
          appText(
            _ordem ? 'Ordem de serviço criada' : 'Horário reservado',
            bold: true,
            textAlign: TextAlign.center,
            color: local.AppColors.text,
            fontSize: AppFontSizes.medium,
          ),
          appSizedBox(height: 4),
          appText(
            _ordem
                ? '${agendamentos.length} serviços reservados. Ela fica na sua agenda.'
                : 'Ele já está na sua agenda.',
            textAlign: TextAlign.center,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
          appSizedBox(height: AppSpacing.medium),
          appContainer(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.normal + 2,
              AppSpacing.normal + 2,
              AppSpacing.normal + 2,
              AppSpacing.small,
            ),
            backgroundColor: AppEstilo.campoFundo,
            radius: BorderRadius.circular(AppRadii.externo),
            child: Column(
              children: [
                ...agendamentos.map(_item),
                Container(
                  height: 1,
                  margin: EdgeInsets.only(bottom: AppSpacing.small + 3),
                  color: const Color(0xFFE3E6EB),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.small),
                  child: Row(
                    children: [
                      appText(
                        'Total',
                        bold: true,
                        color: local.AppColors.text,
                        fontSize: AppFontSizes.small,
                      ),
                      const Spacer(),
                      appText(
                        formataDinheiro(_total),
                        bold: true,
                        color: local.AppColors.primary,
                        fontSize: AppFontSizes.normal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_podePagar)
            appElevatedButtonRazor(
              title: 'Pagar agora com Pix',
              padding: AppSpacing.medium,
              width: double.infinity,
              color: local.AppColors.statusAberto,
              onTap: () async {
                await _pagar(context);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          appElevatedButtonRazorTransparent(
            title: _podePagar ? 'Pagar depois na agenda' : 'Fechar',
            padding: _podePagar ? AppSpacing.small + 3 : AppSpacing.medium,
            width: double.infinity,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
