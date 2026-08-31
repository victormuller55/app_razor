import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

void showBarbeariaMapaModal({
  required BuildContext context,
  required BarbeariaModel barbearia,
  required VoidCallback onVerBarbearia,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (BuildContext modalContext) {
      return _BarbeariaMapaCard(
        barbearia: barbearia,
        onVerBarbearia: () {
          Navigator.of(modalContext).pop();
          onVerBarbearia();
        },
      );
    },
  );
}

class _BarbeariaMapaCard extends StatelessWidget {
  const _BarbeariaMapaCard({
    required this.barbearia,
    required this.onVerBarbearia,
  });

  final BarbeariaModel barbearia;
  final VoidCallback onVerBarbearia;

  @override
  Widget build(BuildContext context) {
    final bool aberto = barbearia.aberto ?? false;
    final String status = aberto ? 'Aberto' : 'Fechado';
    final String? horario = barbearia.horarioHoje;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.medium + bottomInset,
      ),
      child: Material(
        color: local.AppColors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.normal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.normal),
                    child: homeBarbeariaFotoStatus(
                      barbearia: barbearia,
                      size: 56,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        appText(
                          barbearia.nome ?? AppStrings.vazio,
                          bold: true,
                          maxLines: 1,
                          overflow: true,
                          color: local.AppColors.text,
                          fontSize: AppFontSizes.small,
                        ),
                        appText(
                          barbearia.localDescricao,
                          maxLines: 1,
                          overflow: true,
                          color: local.AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        appSizedBox(height: 4),
                        Wrap(
                          spacing: AppSpacing.normal,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            homeNotaDistancia(barbearia: barbearia),
                            appText(
                              horario == null ? status : '$status · $horario',
                              color: aberto
                                  ? local.AppColors.statusAberto
                                  : local.AppColors.statusFechado,
                              fontSize: 11,
                              bold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return appElevatedButtonRazor(
                    title: 'Ver barbearia',
                    padding: AppSpacing.normal,
                    height: 44,
                    width: constraints.maxWidth,
                    onTap: onVerBarbearia,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
