import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

AppFormField criarCampoPerfil({
  required BuildContext context,
  required String hint,
  required IconData icon,
  TextInputType textInputType = TextInputType.text,
  String? Function(String?)? validator,
  bool? showContent,
}) {
  return AppFormField(
    context: context,
    hint: hint,
    paddingHeight: 15,
    maxLines: 1,
    fontSize: 15,
    errorFontSize: 11,
    radius: AppRadius.medium,
    textInputType: textInputType,
    backgroundColor: local.AppColors.white,
    inputColor: local.AppColors.text,
    hintColor: local.AppColors.textSecondary,
    borderColor: local.AppColors.border,
    hoverBorderColor: local.AppColors.primary,
    iconColor: local.AppColors.iconMuted,
    icon: Icon(icon, color: local.AppColors.iconMuted),
    validator: validator,
    showContent: showContent,
  );
}
