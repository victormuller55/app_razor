import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

void showCancelarAgendamentoModal({
  required BuildContext context,
  required VoidCallback onConfirmar,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
        ),
        child: appContainer(
          width: double.infinity,
          backgroundColor: local.AppColors.surface,
          radius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(modalContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    height: 6,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
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
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
