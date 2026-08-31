import 'package:app_razor/app_config/const/app_assets.dart';
import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';

Widget appLogoRazor({
  double height = 88,
  double? width,
  Alignment alignment = Alignment.center,
  bool inverted = false,
  bool fill = false,
}) {
  final Widget logo = Image.asset(
    AppAssets.logo,
    height: fill ? null : height,
    width: fill ? null : width,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Razor',
    color: inverted ? null : local.AppColors.primary,
    colorBlendMode: inverted ? null : BlendMode.srcIn,
  );

  if (fill) {
    return Align(
      alignment: alignment,
      child: SizedBox.expand(child: logo),
    );
  }

  return Align(
    alignment: alignment,
    child: logo,
  );
}
