import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget appElevatedButtonRazor({
  required String title,
  double? padding,
  double? height,
  double? width,
  double? radius,
  Color? color,
  required void Function() onTap,
}) {
  return Builder(
    builder: (context) {
      final buttonWidth = width ?? MediaQuery.of(context).size.width;
      final buttonHeight = height ?? 50;
      final buttonRadius = radius ?? AppRadius.medium;

      return Padding(
        padding: EdgeInsets.only(top: padding ?? AppSpacing.normal),
        child: appElevatedButtonText(
          title.toUpperCase(),
          function: onTap,
          height: buttonHeight,
          width: buttonWidth,
          color: color ?? local.AppColors.primary,
          textColor: AppColors.white,
          borderRadius: buttonRadius,
        ),
      );
    },
  );
}

Widget appElevatedButtonRazorTransparent({
  required String title,
  double? width,
  double? height,
  double? radius,
  double? padding,
  double? fontSize,
  Color? textColor,
  Color? borderColor,
  Color? backgroundColor,
  bool fitContent = false,
  required void Function() onTap,
}) {
  final Color resolvedTextColor = textColor ?? local.AppColors.primary;
  final Color resolvedBorderColor = borderColor ?? local.AppColors.primary;
  final double resolvedRadius = radius ?? AppRadius.medium;
  final double resolvedHeight = height ?? 50;

  return Builder(
    builder: (context) {
      final Widget label = appText(
        title.toUpperCase(),
        color: resolvedTextColor,
        bold: true,
        fontSize: fontSize ?? AppFontSizes.verySmall,
        letterSpacing: 0.4,
        maxLines: 1,
        overflow: true,
      );

      return Padding(
        padding: EdgeInsets.only(top: padding ?? AppSpacing.normal),
        child: fitContent
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: resolvedTextColor,
                  backgroundColor: backgroundColor ?? AppColors.transparent,
                  side: BorderSide(color: resolvedBorderColor, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(resolvedRadius),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.big,
                    vertical: AppSpacing.normal,
                  ),
                  minimumSize: Size(0, resolvedHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: label,
              )
            : appElevatedButtonText(
                title.toUpperCase(),
                function: onTap,
                height: resolvedHeight,
                width: width ?? MediaQuery.of(context).size.width,
                color: AppColors.transparent,
                textColor: resolvedTextColor,
                borderRadius: resolvedRadius,
                borderColor: resolvedBorderColor,
                fontSize: fontSize,
              ),
      );
    },
  );
}
