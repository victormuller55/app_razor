import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

const String homeMensagemSemBarbeariasProximas =
    'Nenhuma barbearia próxima a você';

Widget homeEmptyState({
  required String message,
  IconData? icon,
  double iconSize = 36,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: local.AppColors.primaryLight),
            appSizedBox(height: AppSpacing.normal),
          ],
          appText(
            message,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget homeEmptyStateCentral({
  required String message,
  required double height,
}) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: Center(
      child: appText(
        message,
        color: local.AppColors.textSecondary,
        fontSize: AppFontSizes.small,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
