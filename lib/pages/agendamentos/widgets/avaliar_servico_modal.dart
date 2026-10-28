import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

typedef EnviarAvaliacao =
    Future<AppResponse> Function({
      required int id,
      required int nota,
      String? comentario,
    });

const Color corEstrelaAvaliacao = Color(0xFFF2B01E);

const List<String> _rotulosNota = <String>[
  'Toque nas estrelas para dar a nota',
  'Ruim',
  'Poderia ser melhor',
  'Bom',
  'Muito bom',
  'Excelente!',
];

/// Nota de 1 a 5 e comentário para um serviço concluído. Devolve a nota dada,
/// ou null se o cliente fechou sem enviar.
Future<int?> showAvaliarServicoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
  EnviarAvaliacao enviar = avaliarAgendamento,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) =>
        AvaliarServicoSheet(agendamento: agendamento, enviar: enviar),
  );
}

class AvaliarServicoSheet extends StatefulWidget {
  const AvaliarServicoSheet({
    super.key,
    required this.agendamento,
    required this.enviar,
  });

  final AgendamentoModel agendamento;
  final EnviarAvaliacao enviar;

  @override
  State<AvaliarServicoSheet> createState() => _AvaliarServicoSheetState();
}

class _AvaliarServicoSheetState extends State<AvaliarServicoSheet> {
  final TextEditingController _comentario = TextEditingController();
  int _nota = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final int? id = widget.agendamento.id;
    if (_nota == 0 || _enviando || id == null) {
      return;
    }

    setState(() => _enviando = true);
    try {
      await widget.enviar(id: id, nota: _nota, comentario: _comentario.text);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_nota);
      try {
        showSnackbarSuccess(message: 'Obrigado pela avaliação!');
      } catch (_) {}
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _enviando = false);
      try {
        showSnackbarError(message: errorModelFromApi(e).mensagem);
      } catch (_) {}
    }
  }

  Widget _estrelas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (int index) {
        final int valor = index + 1;
        final bool cheia = valor <= _nota;
        return Semantics(
          button: true,
          selected: cheia,
          label: '$valor de 5 estrelas',
          child: InkResponse(
            radius: 28,
            onTap: _enviando ? null : () => setState(() => _nota = valor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedScale(
                scale: cheia ? 1.08 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  cheia ? PhosphorFill.star : Phosphor.star,
                  size: 40,
                  color: cheia ? corEstrelaAvaliacao : AppEstilo.campoIcone,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _campoComentario() {
    return TextField(
      controller: _comentario,
      enabled: !_enviando,
      minLines: 3,
      maxLines: 5,
      maxLength: 1000,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        fontFamily: AppFonts.family,
        color: local.AppColors.text,
        fontSize: AppFontSizes.small,
      ),
      decoration: InputDecoration(
        hintText: 'Conte como foi (opcional)',
        hintStyle: TextStyle(
          fontFamily: AppFonts.family,
          color: AppEstilo.campoIcone,
          fontSize: AppFontSizes.verySmall,
        ),
        counterText: '',
        filled: true,
        fillColor: AppEstilo.campoFundo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo - 4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo - 4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.externo - 4),
          borderSide: const BorderSide(color: local.AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AgendamentoModel agendamento = widget.agendamento;
    final String servico = agendamento.nomeServico ?? 'Serviço';
    final String? profissional = agendamento.nomeFuncionario;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: appContainer(
        width: double.infinity,
        backgroundColor: local.AppColors.white,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appText(
                        'Como foi o serviço?',
                        bold: true,
                        fontSize: AppFontSizes.medium,
                        color: local.AppColors.text,
                        textAlign: TextAlign.center,
                      ),
                      appSizedBox(height: 4),
                      appText(
                        [
                          servico,
                          if (profissional != null && profissional.isNotEmpty)
                            'com $profissional',
                          if (agendamento.nomeBarbearia != null)
                            agendamento.nomeBarbearia!,
                        ].join(' · '),
                        color: local.AppColors.textSecondary,
                        fontSize: AppFontSizes.verySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: true,
                      ),
                      appSizedBox(height: AppSpacing.normal),
                      _estrelas(),
                      appSizedBox(height: 2),
                      appText(
                        _rotulosNota[_nota],
                        bold: _nota > 0,
                        color: _nota > 0
                            ? local.AppColors.text
                            : AppEstilo.campoIcone,
                        fontSize: AppFontSizes.verySmall,
                        textAlign: TextAlign.center,
                      ),
                      appSizedBox(height: AppSpacing.normal),
                      _campoComentario(),
                      appSizedBox(height: AppSpacing.small),
                      appText(
                        'Sua nota e seu comentário aparecem no perfil da barbearia.',
                        color: local.AppColors.textSecondary,
                        fontSize: 11,
                        textAlign: TextAlign.center,
                      ),
                      if (_enviando)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.normal),
                          child: appLoadingRazor(size: 40),
                        )
                      else
                        Opacity(
                          opacity: _nota == 0 ? 0.5 : 1,
                          child: appElevatedButtonRazor(
                            title: 'Enviar avaliação',
                            padding: AppSpacing.normal,
                            height: 46,
                            onTap: _enviar,
                          ),
                        ),
                      appElevatedButtonRazorTransparent(
                        title: 'Agora não',
                        padding: AppSpacing.small,
                        height: 46,
                        onTap: () => Navigator.of(context).pop(),
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

/// Botão dos cards da agenda para avaliar um serviço concluído.
Widget botaoAvaliarServico({required VoidCallback onTap}) {
  return Material(
    color: corEstrelaAvaliacao.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorFill.star, size: 16, color: corEstrelaAvaliacao),
            appSizedBox(width: 6),
            appText(
              'Avaliar serviço',
              bold: true,
              color: local.AppColors.text,
              fontSize: AppFontSizes.verySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

/// "Sua avaliação" com as estrelas da nota que o cliente já deu.
Widget notaDadaAvaliacao(int nota) {
  return Row(
    children: [
      appText(
        'Sua avaliação',
        color: local.AppColors.textSecondary,
        fontSize: AppFontSizes.verySmall,
      ),
      const Spacer(),
      for (int i = 1; i <= 5; i++)
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            i <= nota ? PhosphorFill.star : Phosphor.star,
            size: 16,
            color: i <= nota ? corEstrelaAvaliacao : AppEstilo.campoIcone,
          ),
        ),
    ],
  );
}
