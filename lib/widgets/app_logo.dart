import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:flutter/material.dart';

Widget appLogoRazor({
  double height = 88,
  double? width,
  Alignment alignment = Alignment.center,
  bool inverted = false,
  bool fill = false,
}) {
  final Widget logo = Text(
    'Razor',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: AppFonts.family,
      fontWeight: FontWeight.w700,
      fontSize: height * 0.62,
      letterSpacing: height * 0.03,
      color: inverted ? local.AppColors.white : local.AppColors.primary,
    ),
  );

  if (fill) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 0.7,
        child: FittedBox(fit: BoxFit.contain, child: logo),
      ),
    );
  }

  return Align(
    alignment: alignment,
    child: SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: BoxFit.contain, child: logo),
    ),
  );
}
