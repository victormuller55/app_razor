import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Pede confirmação mostrando o prazo; fora dele o cancelamento continua
/// possível, só fica registrado como fora do prazo (sem multa).
void showCancelarAgendamentoModal({
  required BuildContext context,
  required ValueChanged<String?> onConfirmar,
  DateTime? inicio,
  bool pagoPeloApp = false,
  PoliticaAgendamentoModel politica = PoliticaAgendamentoModel.padrao,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return CancelarAgendamentoSheet(
        onConfirmar: (String? motivo) {
          Navigator.of(modalContext).pop();
          onConfirmar(motivo);
        },
        onVoltar: () => Navigator.of(modalContext).pop(),
        inicio: inicio,
        pagoPeloApp: pagoPeloApp,
        politica: politica,
        agora: DateTime.now(),
      );
    },
  );
}

class CancelarAgendamentoSheet extends StatefulWidget {
  const CancelarAgendamentoSheet({
    super.key,
    required this.onConfirmar,
    required this.onVoltar,
    required this.politica,
    required this.agora,
    this.inicio,
    this.pagoPeloApp = false,
  });

  final ValueChanged<String?> onConfirmar;
  final VoidCallback onVoltar;
  final PoliticaAgendamentoModel politica;
  final DateTime agora;
  final DateTime? inicio;
  final bool pagoPeloApp;

  @override
  State<CancelarAgendamentoSheet> createState() =>
      _CancelarAgendamentoSheetState();
}

class _CancelarAgendamentoSheetState extends State<CancelarAgendamentoSheet> {
  final TextEditingController _motivo = TextEditingController();
  bool _verRegras = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Widget _texto(String texto, {Color? cor, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.small),
      child: appText(
        texto,
        bold: bold,
        color: cor ?? local.AppColors.textSecondary,
        fontSize: AppFontSizes.verySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PoliticaAgendamentoModel politica = widget.politica;
    final bool foraDoPrazo = politica.foraDoPrazo(widget.inicio, widget.agora);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: appContainer(
        width: double.infinity,
        backgroundColor: local.AppColors.surface,
        radius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    height: 6,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.medium,
                    AppSpacing.small,
                    AppSpacing.medium,
                    AppSpacing.normal,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appText(
                        'Cancelar agendamento',
                        bold: true,
                        fontSize: AppFontSizes.medium,
                        color: local.AppColors.text,
                      ),
                      appSizedBox(height: AppSpacing.small),
                      if (foraDoPrazo)
                        _texto(
                          'Faltam menos de ${politica.prazoLabel} para o horário. '
                          'Você ainda pode cancelar: fica registrado como '
                          'cancelamento fora do prazo, sem multa.',
                          cor: const Color(0xFFB45309),
                          bold: true,
                        )
                      else
                        _texto(
                          'Cancelamentos até ${politica.prazoLabel} antes do '
                          'horário ficam no prazo. Sem multa.',
                        ),
                      if (widget.pagoPeloApp)
                        _texto(
                          'Você pagou pelo app: o valor é devolvido pelo '
                          'Mercado Pago. O reembolso aparece como concluído '
                          'quando o Mercado Pago confirmar.',
                        ),
                      _texto('O horário volta a ficar livre na agenda.'),
                      if (_verRegras)
                        for (final String regra in politica.regrasParaExibir)
                          _texto('• $regra'),
                      GestureDetector(
                        onTap: () => setState(() => _verRegras = !_verRegras),
                        child: appText(
                          _verRegras ? 'Ocultar regras' : 'Ver todas as regras',
                          bold: true,
                          color: local.AppColors.primary,
                          fontSize: AppFontSizes.verySmall,
                        ),
                      ),
                      appSizedBox(height: AppSpacing.small),
                      TextField(
                        key: const Key('motivo_cancelamento'),
                        controller: _motivo,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 300,
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          color: local.AppColors.text,
                          fontSize: AppFontSizes.small,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Motivo (opcional)',
                          hintStyle: TextStyle(
                            fontFamily: AppFonts.family,
                            color: AppEstilo.campoIcone,
                            fontSize: AppFontSizes.verySmall,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: AppEstilo.campoFundo,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.externo - 4,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.externo - 4,
                            ),
                            borderSide: BorderSide(
                              color: local.AppColors.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      appSizedBox(height: AppSpacing.medium),
                      appElevatedButtonRazor(
                        title: 'Sim, cancelar',
                        padding: 0,
                        height: 46,
                        onTap: () {
                          final String motivo = _motivo.text.trim();
                          widget.onConfirmar(motivo.isEmpty ? null : motivo);
                        },
                      ),
                      appElevatedButtonRazorTransparent(
                        title: 'Voltar',
                        padding: AppSpacing.small,
                        height: 46,
                        onTap: widget.onVoltar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
