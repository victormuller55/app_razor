import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

void showCancelarAgendamentoModal({
  required BuildContext context,
  required VoidCallback onConfirmar,
}) {
  showModalEmpty(
    context,
    initialHeight: 0.38,
    minHeight: 0.32,
    maxHeight: 0.5,
    backgroundColor: local.AppColors.white,
    child: Builder(
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.small,
            AppSpacing.medium,
            AppSpacing.normal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              appText(
                'Cancelar agendamento',
                bold: true,
                fontSize: AppFontSizes.medium,
                color: local.AppColors.text,
              ),
              appSizedBox(height: AppSpacing.small),
              appText(
                'Tem certeza que deseja cancelar este horário? Essa ação não pode ser desfeita.',
                color: local.AppColors.textSecondary,
                fontSize: AppFontSizes.verySmall,
              ),
              appSizedBox(height: AppSpacing.medium),
              appElevatedButtonRazor(
                title: 'Sim, cancelar',
                padding: 0,
                height: 46,
                onTap: () {
                  Navigator.of(modalContext).pop();
                  onConfirmar();
                },
              ),
              appElevatedButtonRazorTransparent(
                title: 'Voltar',
                padding: AppSpacing.small,
                height: 46,
                onTap: () => Navigator.of(modalContext).pop(),
              ),
            ],
          ),
        );
      },
    ),
  );
}
