import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Monta o botão com a largura em pixels: sem [width], a tela toda; com `double.infinity`, todo o
/// espaço disponível (o botão do pacote encolhe para o texto quando recebe infinito num lugar
/// centralizado). Só mede o espaço nesse caso, para os outros continuarem funcionando em diálogos.
Widget _comLargura(
  double? width,
  Widget Function(BuildContext context, double largura) montar,
) {
  if (width != null && width.isInfinite) {
    return LayoutBuilder(
      builder: (context, constraints) => montar(
        context,
        constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width,
      ),
    );
  }
  return Builder(
    builder: (context) =>
        montar(context, width ?? MediaQuery.of(context).size.width),
  );
}

Widget appElevatedButtonRazor({
  required String title,
  double? padding,
  double? height,
  double? width,
  double? radius,
  Color? color,
  Color? textColor,
  required void Function() onTap,
}) {
  return _comLargura(width, (context, buttonWidth) {
    final buttonHeight = height ?? 50;
    final buttonRadius = radius ?? AppRadii.externo;

    return Padding(
      padding: EdgeInsets.only(top: padding ?? AppSpacing.normal),
      child: appElevatedButtonText(
        title.toUpperCase(),
        function: onTap,
        height: buttonHeight,
        width: buttonWidth,
        color: color ?? local.AppColors.primary,
        textColor: textColor ?? AppColors.white,
        borderRadius: buttonRadius,
      ),
    );
  });
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
  final double resolvedRadius = radius ?? AppRadii.externo;
  final double resolvedHeight = height ?? 50;

  return _comLargura(width, (context, buttonWidth) {
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
              width: buttonWidth,
              color: AppColors.transparent,
              textColor: resolvedTextColor,
              borderRadius: resolvedRadius,
              borderColor: resolvedBorderColor,
              fontSize: fontSize,
            ),
    );
  });
}
