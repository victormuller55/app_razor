import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget perfilInfoBanner({
  required List<String> linhas,
  IconData? icon,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.normal),
    child: appContainer(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.normal),
      radius: BorderRadius.circular(AppRadius.medium),
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: local.AppColors.white, size: 18),
            appSizedBox(width: AppSpacing.normal),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < linhas.length; i++) ...[
                  if (i > 0) appSizedBox(height: AppSpacing.small),
                  appText(
                    linhas[i],
                    color: local.AppColors.white,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
