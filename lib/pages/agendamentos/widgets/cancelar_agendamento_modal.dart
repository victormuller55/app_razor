import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_folha_modal.dart';
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

  /// Âmbar do aviso de fora do prazo, mais claro no escuro para dar leitura.
  Color get _ambar => local.AppColors.escuro
      ? const Color(0xFFF5A524)
      : const Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final PoliticaAgendamentoModel politica = widget.politica;
    final bool foraDoPrazo = politica.foraDoPrazo(widget.inicio, widget.agora);
    final TextStyle estiloCampo = TextStyle(
      fontFamily: AppFonts.family,
      color: local.AppColors.text,
      fontSize: AppFontSizes.small,
    );

    return FolhaModal(
      titulo: 'Cancelar agendamento',
      subtitulo: 'O horário volta a ficar livre na agenda.',
      icone: Phosphor.calendarX,
      corIcone: local.AppColors.danger,
      conteudo: <Widget>[
        if (foraDoPrazo)
          AvisoModal(
            icone: Phosphor.warningCircle,
            cor: _ambar,
            destaque: true,
            texto:
                'Faltam menos de ${politica.prazoLabel} para o horário. '
                'Você ainda pode cancelar: fica registrado como '
                'cancelamento fora do prazo, sem multa.',
          )
        else
          AvisoModal(
            icone: Phosphor.checkCircle,
            cor: local.AppColors.statusAberto,
            texto:
                'Cancelamentos até ${politica.prazoLabel} antes do '
                'horário ficam no prazo. Sem multa.',
          ),
        if (widget.pagoPeloApp)
          const AvisoModal(
            icone: Phosphor.arrowCounterClockwise,
            texto:
                'Você pagou pelo app: o valor é devolvido pelo '
                'Mercado Pago. O reembolso aparece como concluído '
                'quando o Mercado Pago confirmar.',
          ),
        _regras(politica),
        TextField(
          key: const Key('motivo_cancelamento'),
          controller: _motivo,
          minLines: 1,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          style: estiloCampo,
          cursorColor: local.AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Motivo (opcional)',
            hintStyle: estiloCampo.copyWith(color: AppEstilo.campoIcone),
            counterText: '',
            filled: true,
            fillColor: AppEstilo.campoFundo,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: local.AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
      acoes: <Widget>[
        appElevatedButtonRazor(
          title: 'Sim, cancelar',
          padding: 0,
          height: 50,
          color: local.AppColors.danger,
          onTap: () {
            final String motivo = _motivo.text.trim();
            widget.onConfirmar(motivo.isEmpty ? null : motivo);
          },
        ),
        appElevatedButtonRazorTransparent(
          title: 'Voltar',
          padding: 0,
          height: 50,
          onTap: widget.onVoltar,
        ),
      ],
    );
  }

  /// "Ver todas as regras" abre a lista num bloco cinza logo abaixo.
  Widget _regras(PoliticaAgendamentoModel politica) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _verRegras = !_verRegras),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              appText(
                _verRegras ? 'Ocultar regras' : 'Ver todas as regras',
                bold: true,
                color: local.AppColors.primary,
                fontSize: AppFontSizes.verySmall,
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _verRegras ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Phosphor.caretDown,
                  size: 14,
                  color: local.AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_verRegras
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppEstilo.campoFundo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final String regra in politica.regrasParaExibir)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: appText(
                            '• $regra',
                            color: local.AppColors.textSecondary,
                            fontSize: AppFontSizes.verySmall,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
