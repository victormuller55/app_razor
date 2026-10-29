import 'dart:async';
import 'dart:convert';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/agendamentos_atualizados.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/notificacao_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_page.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

typedef BuscarAvisos = Future<AppResponse> Function();
typedef MarcarAvisoLido = Future<AppResponse> Function({required int id});
typedef AbrirAvaliacao =
    Future<void> Function(BuildContext context, AgendamentoModel agendamento);
typedef AbrirRemarcacao =
    Future<void> Function(BuildContext context, AgendamentoModel cancelado);

Future<void> _abrirAvaliacaoPadrao(
  BuildContext context,
  AgendamentoModel agendamento,
) async {
  await showAvaliarServicoModal(context: context, agendamento: agendamento);
}

Future<void> _abrirRemarcacaoPadrao(
  BuildContext context,
  AgendamentoModel cancelado,
) async {
  openAgendamento(
    barbeariaId: cancelado.idBarbearia!,
    nomeBarbearia: cancelado.nomeBarbearia,
    servicoId: cancelado.idBarbeariaServico,
  );
}

/// Avisos guardados na API que o cliente vê ao abrir o app:
/// - "Como foi seu atendimento?" quando o barbeiro conclui o serviço (ou o
///   servidor conclui sozinho no prazo); "Avaliar" abre a avaliação dele;
/// - "A barbearia cancelou seu horário", com o motivo; "Marcar outro horário"
///   abre a reserva na mesma barbearia;
/// - os demais (confirmação, lembrete, pagamento, devolução...) viram uma faixa
///   com o mais recente e são marcados como lidos (RAZ-11).
///
/// Com o push ligado (RAZ-11) o aviso também chega com o app fechado; sem ele,
/// o cliente vê o aviso quando abrir o app.
class AvisosAtendimento with WidgetsBindingObserver {
  AvisosAtendimento({
    BuscarAvisos? buscar,
    MarcarAvisoLido? marcarLida,
    AbrirAvaliacao? abrirAvaliacao,
    AbrirRemarcacao? abrirRemarcacao,
    void Function(String texto)? informar,
    BuildContext? Function()? contexto,
  }) : _buscar = buscar ?? getNotificacoesNaoLidas,
       _marcarLida = marcarLida ?? marcarNotificacaoLida,
       _abrirAvaliacao = abrirAvaliacao ?? _abrirAvaliacaoPadrao,
       _abrirRemarcacao = abrirRemarcacao ?? _abrirRemarcacaoPadrao,
       _informar = informar ?? ((String texto) => showSnackbarSuccess(message: texto)),
       _contexto = contexto ?? (() => AppContext.navigatorKey.currentContext);

  final BuscarAvisos _buscar;
  final MarcarAvisoLido _marcarLida;
  final AbrirAvaliacao _abrirAvaliacao;
  final AbrirRemarcacao _abrirRemarcacao;
  final void Function(String texto) _informar;
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

      await _avisarInformativos(
        avisos.where((NotificacaoModel a) => a.informativo && !_mostrados.contains(a.id)).toList(),
      );

      for (final NotificacaoModel aviso in avisos) {
        if (_mostrados.contains(aviso.id)) {
          continue;
        }

        if (aviso.canceladoPelaBarbearia) {
          await _avisarCancelamento(aviso);
          return;
        }

        if (!aviso.atendimentoConcluido) {
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

  /// Avisos sem tela própria: uma faixa com o mais recente (a lista vem do mais novo para o mais antigo) e
  /// todos marcados como lidos, para não ocuparem o lugar dos avisos que pedem uma ação.
  Future<void> _avisarInformativos(List<NotificacaoModel> informativos) async {
    if (informativos.isEmpty) {
      return;
    }
    _mostrados.addAll(informativos.map((NotificacaoModel a) => a.id));
    try {
      // Pagamento, devolução ou mudança no horário: a lista de agendamentos guardada está velha.
      await HttpCache.invalidateContaining('agendamentos');
    } catch (_) {}
    avisarAgendamentosAtualizados();
    final NotificacaoModel recente = informativos.first;
    _informar(
      recente.mensagem == null || recente.mensagem!.isEmpty
          ? recente.titulo
          : '${recente.titulo}: ${recente.mensagem}',
    );
    for (final NotificacaoModel aviso in informativos) {
      await _lido(aviso.id);
    }
  }

  Future<void> _avisarCancelamento(NotificacaoModel aviso) async {
    final BuildContext? context = _contexto();
    if (context == null || !context.mounted) {
      return;
    }
    _mostrados.add(aviso.id);

    // A agenda guardada no aparelho ainda mostra o horário como marcado.
    try {
      await HttpCache.invalidateContaining('agendamentos');
    } catch (_) {}
    if (!context.mounted) {
      _mostrados.remove(aviso.id);
      return;
    }

    final AgendamentoModel? cancelado = aviso.agendamentoParaRemarcar;
    final bool remarcar =
        await showAvisoCanceladoPelaBarbearia(
          context: context,
          aviso: aviso,
          podeRemarcar: cancelado != null,
        ) ??
        false;
    await _lido(aviso.id);
    if (remarcar && cancelado != null && context.mounted) {
      await _abrirRemarcacao(context, cancelado);
    }
  }
}

/// Devolve true em "Avaliar", false em "Agora não" e null se fechou arrastando.
Future<bool?> showAvisoAtendimentoConcluido({
  required BuildContext context,
  required NotificacaoModel aviso,
}) {
  return _showAviso(
    context: context,
    icone: const Icon(PhosphorFill.star, size: 40, color: corEstrelaAvaliacao),
    aviso: aviso,
    acao: 'Avaliar',
    recusa: 'Agora não',
  );
}

/// Devolve true em "Marcar outro horário"; false ou null nos outros casos.
Future<bool?> showAvisoCanceladoPelaBarbearia({
  required BuildContext context,
  required NotificacaoModel aviso,
  required bool podeRemarcar,
}) {
  return _showAviso(
    context: context,
    icone: Icon(
      Phosphor.calendarBlank,
      size: 40,
      color: local.AppColors.primary,
    ),
    aviso: aviso,
    acao: podeRemarcar ? 'Marcar outro horário' : null,
    recusa: podeRemarcar ? 'Agora não' : 'Entendi',
  );
}

Future<bool?> _showAviso({
  required BuildContext context,
  required Widget icone,
  required NotificacaoModel aviso,
  required String? acao,
  required String recusa,
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
              icone,
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
              if (acao != null)
                appElevatedButtonRazor(
                  title: acao,
                  padding: AppSpacing.normal,
                  height: 46,
                  onTap: () => Navigator.of(modalContext).pop(true),
                ),
              appElevatedButtonRazorTransparent(
                title: recusa,
                padding: acao != null ? AppSpacing.small : AppSpacing.normal,
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
