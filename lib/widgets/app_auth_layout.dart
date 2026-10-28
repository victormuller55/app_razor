import 'dart:math' as math;

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Layout compartilhado das telas de autenticação (login e cadastro).
///
/// Cabeçalho em gradiente com formas geométricas, marca, título e barra de
/// destaque; abaixo, uma folha branca arredondada com o formulário e o rodapé.
class AppAuthLayout extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget conteudo;
  final String rodapePergunta;
  final String rodapeAcao;
  final VoidCallback onRodapeTap;
  final VoidCallback? onVoltar;
  final bool loading;

  const AppAuthLayout({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.conteudo,
    required this.rodapePergunta,
    required this.rodapeAcao,
    required this.onRodapeTap,
    this.onVoltar,
    this.loading = false,
  });

  Widget _marca() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: local.AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Phosphor.scissors,
        color: local.AppColors.primary,
        size: 26,
      ),
    );
  }

  Widget _botaoVoltar() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.medium),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onVoltar,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Icon(
            Phosphor.arrowLeft,
            color: local.AppColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _conteudoCabecalho(BuildContext context, double altura) {
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppEstilo.raioFolha,
          MediaQuery.of(context).padding.top + AppSpacing.normal,
          AppSpacing.medium + 4,
          AppSpacing.big + 6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onVoltar != null) _botaoVoltar(),
            const Spacer(),
            _marca(),
            appSizedBox(height: AppSpacing.medium),
            appHeaderTitulo(titulo: titulo, subtitulo: subtitulo),
          ],
        ),
      ),
    );
  }

  Widget _rodape() {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: loading ? null : onRodapeTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.normal),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: AppFontSizes.verySmall + 1,
                  color: local.AppColors.textSecondary,
                ),
                children: [
                  TextSpan(text: '$rodapePergunta '),
                  TextSpan(
                    text: rodapeAcao,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: local.AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        appText(
          'Powered by Convertix',
          fontSize: 11,
          color: local.AppColors.textSecondary.withValues(alpha: 0.6),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _folha() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: local.AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(AppEstilo.raioFolha)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium + 4,
        AppSpacing.normal + 2,
        AppSpacing.medium + 4,
        AppSpacing.medium,
      ),
      child: Column(
        children: [
          appFolhaAlca(),
          appSizedBox(height: AppSpacing.medium),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: loading
                ? SizedBox(height: 240, child: appLoadingRazor())
                : conteudo,
          ),
          const Spacer(),
          appSizedBox(height: AppSpacing.medium),
          _rodape(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size tela = MediaQuery.of(context).size;
    final double alturaCabecalho = math.max(tela.height * 0.38, 290);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: local.AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: local.AppColors.white,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: appHeaderFundo(
                          altura: alturaCabecalho + AppEstilo.raioFolha,
                        ),
                      ),
                      Column(
                        children: [
                          _conteudoCabecalho(context, alturaCabecalho),
                          Expanded(
                            child: SafeArea(top: false, child: _folha()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Linha de aceite dos termos com switch, no padrão das telas de autenticação.
class AppAuthTermos extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppAuthTermos({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.normal),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: AppFontSizes.verySmall,
                    color: local.AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(text: 'Aceito os '),
                    TextSpan(
                      text: 'termos de uso e a política de privacidade',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: local.AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            appSizedBox(width: AppSpacing.normal),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: local.AppColors.white,
                activeTrackColor: local.AppColors.primary,
                inactiveThumbColor: local.AppColors.white,
                inactiveTrackColor: const Color(0xFFD5DAE1),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link de texto centralizado no padrão das telas de autenticação.
Widget appAuthLink({required String texto, required VoidCallback onTap}) {
  return Center(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.medium - 4),
        child: appText(
          texto,
          bold: true,
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.primaryLight,
        ),
      ),
    ),
  );
}

/// Configuração visual padrão dos campos das telas de autenticação.
AppFormField appAuthFormField({
  required BuildContext context,
  required String hint,
  required IconData icon,
  required TextInputType textInputType,
  String? Function(String? value)? validator,
  bool senha = false,
}) {
  final Color iconeCor = AppEstilo.campoIcone;

  return AppFormField(
    context: context,
    hint: hint,
    paddingHeight: 18,
    maxLines: 1,
    fontSize: 15,
    errorFontSize: 11,
    radius: AppEstilo.raioCampo,
    textInputType: textInputType,
    backgroundColor: AppEstilo.campoFundo,
    inputColor: local.AppColors.text,
    hintColor: iconeCor,
    borderColor: AppEstilo.campoFundo,
    hoverBorderColor: local.AppColors.primary,
    textErrorColor: local.AppColors.danger,
    iconColor: iconeCor,
    icon: Icon(icon, color: iconeCor, size: 20),
    validator: validator,
    showContent: senha ? false : null,
  );
}
