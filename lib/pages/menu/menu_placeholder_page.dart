import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class MenuPlaceholderPage extends StatelessWidget {
  const MenuPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: title,
      hideBackIcon: true,
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: local.AppColors.primary),
            appSizedBox(height: AppSpacing.normal),
            appText(
              title,
              bold: true,
              fontSize: AppFontSizes.medium,
              color: local.AppColors.text,
            ),
            appSizedBox(height: AppSpacing.small),
            appText(
              'Em breve',
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.verySmall,
            ),
          ],
        ),
      ),
    );
  }
}
