import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/widgets/app_folha_modal.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
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
      return FolhaModal(
        titulo: 'Confirme sua presença',
        subtitulo:
            'Mostre este código para o barbeiro. A leitura confirma sua presença e o serviço.',
        icone: Phosphor.qrCode,
        centralizado: true,
        conteudo: <Widget>[
          // O QR fica sempre em fundo branco, também no modo escuro, para a leitura.
          DecoratedBox(
            decoration: BoxDecoration(
              color: local.AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: local.AppColors.divisor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
          if (agendamento.nomeServico != null ||
              agendamento.periodoLabel.isNotEmpty)
            _resumo(agendamento),
        ],
      );
    },
  );
}

/// Serviço e horário num bloco cinza embaixo do código.
Widget _resumo(AgendamentoModel agendamento) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppEstilo.campoFundo,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: <Widget>[
        Icon(Phosphor.scissors, size: 18, color: AppEstilo.campoIcone),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (agendamento.nomeServico != null)
                appText(
                  agendamento.nomeServico!,
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.small,
                  maxLines: 1,
                  overflow: true,
                ),
              if (agendamento.periodoLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: appText(
                    agendamento.periodoLabel,
                    color: local.AppColors.textSecondary,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
