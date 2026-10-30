import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Tela de erro com ícone, mensagem centralizada e botão para tentar de novo. Substitui o
/// `appError` do pacote, que depende de uma imagem que o app não tem.
Widget appErrorRazor(ErrorModel errorModel, {required void Function() function}) {
  final String titulo = errorModel.erro?.trim() ?? '';
  final String mensagem = errorModel.mensagem?.trim().isNotEmpty == true
      ? errorModel.mensagem!.trim()
      : AppStrings.ocorreuUmErro;
  final IconData icone = errorModel.tipo == tipoSemConexao
      ? Phosphor.wifiSlash
      : Phosphor.warningCircle;

  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.big),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: local.AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 44, color: local.AppColors.primaryLight),
          ),
          appSizedBox(height: AppSpacing.medium),
          if (titulo.isNotEmpty) ...[
            appText(
              titulo,
              color: local.AppColors.text,
              bold: true,
              fontSize: AppFontSizes.normal,
              textAlign: TextAlign.center,
            ),
            appSizedBox(height: AppSpacing.small),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: appText(
              mensagem,
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.small,
              textAlign: TextAlign.center,
            ),
          ),
          appSizedBox(height: AppSpacing.medium),
          appElevatedButtonRazorTransparent(
            title: 'Tentar novamente',
            fitContent: true,
            padding: 0,
            onTap: function,
          ),
        ],
      ),
    ),
  );
}
