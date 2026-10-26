import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';
import 'package:qr_flutter/qr_flutter.dart';

void showQrConfirmacaoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
}) {
  final String? codigo = agendamento.codigoQr;

  if (codigo == null) {
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      // O fundo branco desce até a borda da tela; só o conteúdo respeita a
      // área do indicador de início do iOS.
      return appContainer(
        width: double.infinity,
        backgroundColor: local.AppColors.white,
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
                  AppSpacing.medium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    appText(
                      'Confirme sua presença',
                      bold: true,
                      fontSize: AppFontSizes.medium,
                      color: local.AppColors.text,
                      textAlign: TextAlign.center,
                    ),
                    appSizedBox(height: AppSpacing.small),
                    appText(
                      'Mostre este código para o barbeiro. A leitura confirma sua presença e o serviço.',
                      color: local.AppColors.textSecondary,
                      fontSize: AppFontSizes.verySmall,
                      textAlign: TextAlign.center,
                    ),
                    appSizedBox(height: AppSpacing.normal),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: local.AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: local.AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: codigo,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: local.AppColors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF111111),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ),
                    appSizedBox(height: AppSpacing.normal),
                    if (agendamento.nomeServico != null)
                      appText(
                        agendamento.nomeServico!,
                        bold: true,
                        color: local.AppColors.text,
                        fontSize: AppFontSizes.small,
                        textAlign: TextAlign.center,
                      ),
                    if (agendamento.periodoLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: appText(
                          agendamento.periodoLabel,
                          color: local.AppColors.textSecondary,
                          fontSize: AppFontSizes.verySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
