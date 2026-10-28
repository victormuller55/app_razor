import 'dart:async';
import 'dart:convert';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/notificacao_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

typedef BuscarAvisos = Future<AppResponse> Function();
typedef MarcarAvisoLido = Future<AppResponse> Function({required int id});
typedef AbrirAvaliacao =
    Future<void> Function(BuildContext context, AgendamentoModel agendamento);

Future<void> _abrirAvaliacaoPadrao(
  BuildContext context,
  AgendamentoModel agendamento,
) async {
  await showAvaliarServicoModal(context: context, agendamento: agendamento);
}

/// "Como foi seu atendimento?" quando o barbeiro conclui o serviço (ou o servidor
/// conclui sozinho no prazo). O aviso fica guardado na API: o app confere ao abrir
/// e ao voltar para a tela, e "Avaliar" abre a avaliação daquele atendimento.
///
/// Não é push: com o app fechado o cliente só vê o aviso quando abrir o app.
class AvisosAtendimento with WidgetsBindingObserver {
  AvisosAtendimento({
    BuscarAvisos? buscar,
    MarcarAvisoLido? marcarLida,
    AbrirAvaliacao? abrirAvaliacao,
    BuildContext? Function()? contexto,
  }) : _buscar = buscar ?? getNotificacoesNaoLidas,
       _marcarLida = marcarLida ?? marcarNotificacaoLida,
       _abrirAvaliacao = abrirAvaliacao ?? _abrirAvaliacaoPadrao,
       _contexto = contexto ?? (() => AppContext.navigatorKey.currentContext);

  final BuscarAvisos _buscar;
  final MarcarAvisoLido _marcarLida;
  final AbrirAvaliacao _abrirAvaliacao;
  final BuildContext? Function() _contexto;

  /// Já mostrados nesta sessão: se marcar como lido falhar, não pergunta de novo.
  final Set<int> _mostrados = <int>{};
  bool _verificando = false;
  bool _ativo = false;

  void iniciar() {
    if (_ativo) {
      return;
    }
    _ativo = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(verificar());
  }

  void parar() {
    _ativo = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(verificar());
    }
  }

  Future<void> _lido(int id) async {
    try {
      await _marcarLida(id: id);
    } catch (_) {}
  }

  /// Mostra no máximo um aviso por vez; os outros ficam para a próxima conferida.
  Future<void> verificar() async {
    if (_verificando) {
      return;
    }
    _verificando = true;
    try {
      final AppResponse response = await _buscar();
      final List<NotificacaoModel> avisos = NotificacaoModel.listaFromJson(
        jsonDecode(response.body),
      );

      for (final NotificacaoModel aviso in avisos) {
        if (!aviso.atendimentoConcluido || _mostrados.contains(aviso.id)) {
          continue;
        }
        _mostrados.add(aviso.id);

        final AgendamentoModel? agendamento = aviso.agendamentoParaAvaliar;
        if (agendamento == null) {
          // Já avaliou as duas notas (pela agenda, por exemplo): não há o que perguntar.
          await _lido(aviso.id);
          continue;
        }

        final BuildContext? context = _contexto();
        if (context == null || !context.mounted) {
          _mostrados.remove(aviso.id);
          return;
        }

        final bool avaliar =
            await showAvisoAtendimentoConcluido(
              context: context,
              aviso: aviso,
            ) ??
            false;
        await _lido(aviso.id);
        if (avaliar && context.mounted) {
          await _abrirAvaliacao(context, agendamento);
        }
        return;
      }
    } catch (_) {
      // Sem rede ou sessão: tenta de novo quando o app voltar para a tela.
    } finally {
      _verificando = false;
    }
  }
}

/// Devolve true em "Avaliar", false em "Agora não" e null se fechou arrastando.
Future<bool?> showAvisoAtendimentoConcluido({
  required BuildContext context,
  required NotificacaoModel aviso,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return appContainer(
        width: double.infinity,
        backgroundColor: local.AppColors.surface,
        radius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.normal + MediaQuery.viewPaddingOf(modalContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                PhosphorFill.star,
                size: 40,
                color: corEstrelaAvaliacao,
              ),
              appSizedBox(height: AppSpacing.small),
              appText(
                aviso.titulo,
                bold: true,
                fontSize: AppFontSizes.medium,
                color: local.AppColors.text,
                textAlign: TextAlign.center,
              ),
              if (aviso.mensagem != null) ...[
                appSizedBox(height: 4),
                appText(
                  aviso.mensagem!,
                  color: local.AppColors.textSecondary,
                  fontSize: AppFontSizes.verySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              appElevatedButtonRazor(
                title: 'Avaliar',
                padding: AppSpacing.normal,
                height: 46,
                onTap: () => Navigator.of(modalContext).pop(true),
              ),
              appElevatedButtonRazorTransparent(
                title: 'Agora não',
                padding: AppSpacing.small,
                height: 46,
                onTap: () => Navigator.of(modalContext).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
}
