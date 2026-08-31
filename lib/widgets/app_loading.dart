import 'dart:io';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isIOS => !kIsWeb && Platform.isIOS;

/// Loading nativo: Cupertino no iOS, Material no Android.
Widget appLoadingRazor({Color? color, double? size}) {
  final double dimension = size ?? 28;
  final Color indicatorColor = color ?? local.AppColors.primary;
  final Widget indicator;

  if (_isIOS) {
    indicator = CupertinoActivityIndicator(
      color: indicatorColor,
      radius: (dimension / 2).clamp(8, 14),
    );
  } else {
    indicator = SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
        strokeWidth: dimension <= 20 ? 2 : 2.6,
        color: indicatorColor,
      ),
    );
  }

  return Center(child: indicator);
}
