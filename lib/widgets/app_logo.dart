import 'package:app_razor/app_config/const/app_assets.dart';
import 'package:flutter/material.dart';

Widget appLogoRazor({
  double height = 88,
  double? width,
  Alignment alignment = Alignment.center,
  bool inverted = false,
  bool fill = false,
}) {
  final Widget logo = Image.asset(
    inverted ? AppAssets.logoBranca : AppAssets.logo,
    fit: BoxFit.contain,
  );

  if (fill) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 0.7,
        child: logo,
      ),
    );
  }

  return Align(
    alignment: alignment,
    child: SizedBox(width: width, height: height, child: logo),
  );
}
