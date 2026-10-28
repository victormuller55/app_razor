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

/// As duas avaliações de um atendimento concluído, cada uma opcional e independente:
/// o serviço e o profissional (só a barbearia vê) e a barbearia (vai para o perfil e a média).
/// Devolve true se alguma nota foi enviada, ou null se o cliente fechou sem enviar.
Future<bool?> showAvaliarServicoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
  EnviarAvaliacao enviarAtendimento = avaliarAtendimento,
  EnviarAvaliacao enviarBarbearia = avaliarAgendamento,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) => AvaliarServicoSheet(
      agendamento: agendamento,
      enviarAtendimento: enviarAtendimento,
      enviarBarbearia: enviarBarbearia,
    ),
  );
}

/// Uma das duas notas da folha: a que o cliente já deu, ou a que está dando agora.
class _Secao {
  _Secao({required this.chave, required this.notaDada});

  final String chave;
  final TextEditingController comentario = TextEditingController();
  int nota = 0;

  /// Nota já registrada na API (antes ou neste envio): a seção só mostra as estrelas.
  int? notaDada;

  bool get pendente => notaDada == null && nota > 0;
}

class AvaliarServicoSheet extends StatefulWidget {
  const AvaliarServicoSheet({
    super.key,
    required this.agendamento,
    required this.enviarAtendimento,
    required this.enviarBarbearia,
  });

  final AgendamentoModel agendamento;
  final EnviarAvaliacao enviarAtendimento;
  final EnviarAvaliacao enviarBarbearia;

  @override
  State<AvaliarServicoSheet> createState() => _AvaliarServicoSheetState();
}

class _AvaliarServicoSheetState extends State<AvaliarServicoSheet> {
  late final _Secao _atendimento = _Secao(
    chave: 'atendimento',
    notaDada: widget.agendamento.notaAvaliacaoAtendimento,
  );
  late final _Secao _barbearia = _Secao(
    chave: 'barbearia',
    notaDada: widget.agendamento.notaAvaliacao,
  );
  bool _enviando = false;
  bool _enviouAlguma = false;

  bool get _temPendente => _atendimento.pendente || _barbearia.pendente;

  @override
  void dispose() {
    _atendimento.comentario.dispose();
    _barbearia.comentario.dispose();
    super.dispose();
  }

  /// Envia só as notas preenchidas. Se uma falhar, a que já foi fica registrada e
  /// a folha continua aberta para tentar de novo a outra.
  Future<void> _enviar() async {
    final int? id = widget.agendamento.id;
    if (!_temPendente || _enviando || id == null) {
      return;
    }

    setState(() => _enviando = true);
    try {
      for (final (_Secao secao, EnviarAvaliacao enviar)
          in <(_Secao, EnviarAvaliacao)>[
            (_atendimento, widget.enviarAtendimento),
            (_barbearia, widget.enviarBarbearia),
          ]) {
        if (!secao.pendente) {
          continue;
        }
        await enviar(
          id: id,
          nota: secao.nota,
          comentario: secao.comentario.text,
        );
        secao.notaDada = secao.nota;
        _enviouAlguma = true;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  Widget _estrelas(_Secao secao) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (int index) {
        final int valor = index + 1;
        final bool cheia = valor <= secao.nota;
        return Semantics(
          button: true,
          selected: cheia,
          label: '$valor de 5 estrelas',
          child: InkResponse(
            key: Key('estrela_${secao.chave}_$valor'),
            radius: 28,
            onTap: _enviando ? null : () => setState(() => secao.nota = valor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedScale(
                scale: cheia ? 1.08 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  cheia ? PhosphorFill.star : Phosphor.star,
                  size: 36,
                  color: cheia ? corEstrelaAvaliacao : AppEstilo.campoIcone,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _campoComentario(_Secao secao) {
    return TextField(
      key: Key('comentario_${secao.chave}'),
      controller: secao.comentario,
      enabled: !_enviando,
      minLines: 2,
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
          borderSide: BorderSide(color: local.AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _secao({
    required _Secao secao,
    required String titulo,
    required String aviso,
  }) {
    final int? notaDada = secao.notaDada;
    return appContainer(
      width: double.infinity,
      backgroundColor: AppEstilo.campoFundo,
      radius: BorderRadius.circular(AppRadii.externo - 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            appText(
              titulo,
              bold: true,
              color: local.AppColors.text,
              fontSize: AppFontSizes.small,
            ),
            appSizedBox(height: 2),
            appText(aviso, color: local.AppColors.textSecondary, fontSize: 11),
            appSizedBox(height: AppSpacing.small),
            if (notaDada != null)
              notaDadaAvaliacao(notaDada)
            else ...[
              _estrelas(secao),
              appText(
                _rotulosNota[secao.nota],
                bold: secao.nota > 0,
                color: secao.nota > 0
                    ? local.AppColors.text
                    : AppEstilo.campoIcone,
                fontSize: AppFontSizes.verySmall,
                textAlign: TextAlign.center,
              ),
              if (secao.nota > 0) ...[
                appSizedBox(height: AppSpacing.small),
                _campoComentario(secao),
              ],
            ],
          ],
        ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appText(
                        'Como foi seu atendimento?',
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
                      appSizedBox(height: 4),
                      appText(
                        'As duas avaliações são opcionais: dê só a que quiser.',
                        color: local.AppColors.textSecondary,
                        fontSize: 11,
                        textAlign: TextAlign.center,
                      ),
                      appSizedBox(height: AppSpacing.normal),
                      _secao(
                        secao: _atendimento,
                        titulo: 'O serviço e o profissional',
                        aviso: 'Só a barbearia vê esta nota.',
                      ),
                      appSizedBox(height: AppSpacing.small),
                      _secao(
                        secao: _barbearia,
                        titulo: 'A barbearia',
                        aviso:
                            'Sua nota e seu comentário aparecem no perfil da barbearia.',
                      ),
                      if (_enviando)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.normal),
                          child: appLoadingRazor(size: 40),
                        )
                      else
                        Opacity(
                          opacity: _temPendente ? 1 : 0.5,
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
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_enviouAlguma ? true : null),
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
