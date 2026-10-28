import 'dart:async';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/abrir_rota.dart';
import 'package:app_razor/functions/lembrete_agendamento.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/ordem_servico_model.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_bloc.dart';
import 'package:app_razor/pages/agendamento/agendamento_page.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_bloc.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
import 'package:app_razor/pages/agendamentos/widgets/agendamento_lista_card.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/pages/agendamentos/widgets/cancelar_agendamento_modal.dart';
import 'package:app_razor/pages/agendamentos/widgets/ordem_servico_card.dart';
import 'package:app_razor/pages/agendamentos/widgets/qr_confirmacao_modal.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/pages/pagamento/pagamento_modal.dart';
import 'package:app_razor/pages/pagamento/pagar_ordem_servico.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  AgendamentosBloc bloc = AgendamentosBloc();
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<AgendamentosState> _lembrete;
  PoliticaAgendamentoModel _politica = PoliticaAgendamentoModel.padrao;

  Future<void> _loadAgendamentos({bool forceRefresh = false}) async {
    final Future<AgendamentosState> done = bloc.stream.firstWhere(
      (AgendamentosState state) =>
          state is AgendamentosSuccessState || state is AgendamentosErrorState,
    );

    bloc.add(AgendamentosLoadEvent(forceRefresh: forceRefresh));
    await done;
  }

  void _loadMoreAgendamentos() {
    bloc.add(AgendamentosLoadMoreEvent());
  }

  Future<void> _abrirRota(AgendamentoModel agendamento) async {
    try {
      await abrirRotaBarbearia(
        latitude: agendamento.latitude,
        longitude: agendamento.longitude,
        endereco: agendamento.enderecoCompleto,
        nome: agendamento.nomeBarbearia,
      );
    } catch (_) {
      showSnackbarWarning(message: rotaMensagemIndisponivel);
    }
  }

  void _confirmarCancelamento(AgendamentoModel agendamento) {
    final int? id = agendamento.id;

    if (id == null) {
      return;
    }

    showCancelarAgendamentoModal(
      context: context,
      inicio: agendamento.dataHora,
      pagoPeloApp: agendamento.statusPagamento == 'APROVADO',
      politica: _politica,
      onConfirmar: (String? motivo) =>
          bloc.add(AgendamentosCancelEvent(id, motivo: motivo)),
    );
  }

  /// Ao fechar o pagamento, recarrega: o status vem da API, não do checkout.
  Future<void> _pagar(AgendamentoModel agendamento) async {
    await showPagamentoModal(context: context, agendamento: agendamento);
    if (mounted) {
      await _loadAgendamentos(forceRefresh: true);
    }
  }

  void _confirmarCancelamentoOrdem(OrdemServicoGrupo ordem) {
    final int? idOrdem = ordem.idApi;
    final List<int> ids = ordem.cancelaveis
        .map((AgendamentoModel item) => item.id)
        .whereType<int>()
        .toList();

    if (idOrdem == null || ids.isEmpty) {
      return;
    }

    final List<DateTime> inicios = ordem.cancelaveis
        .map((AgendamentoModel item) => item.dataHora)
        .whereType<DateTime>()
        .toList()
      ..sort();

    showCancelarAgendamentoModal(
      context: context,
      inicio: inicios.firstOrNull,
      pagoPeloApp: ordem.itens.any(
        (AgendamentoModel item) => item.statusPagamento == 'APROVADO',
      ),
      politica: _politica,
      onConfirmar: (String? motivo) => bloc.add(
        AgendamentosCancelOrdemEvent(
          idOrdem: idOrdem,
          idPrimeiro: ids.first,
          motivo: motivo,
        ),
      ),
    );
  }

  Future<void> _pagarOrdem(OrdemServicoGrupo ordem) async {
    await pagarOrdemServico(context: context, ordem: ordem);
    if (mounted) {
      await _loadAgendamentos(forceRefresh: true);
    }
  }

  /// Troca serviços, profissionais e horários; na volta, a agenda recarrega
  /// (a API pode ter cobrado a diferença ou estornado).
  Future<void> _editar({
    required List<AgendamentoModel> editaveis,
    int? idOrdem,
  }) async {
    final AgendamentoModel? primeiro = editaveis.isEmpty
        ? null
        : editaveis.first;
    final int? idBarbearia = primeiro?.idBarbearia;
    if (primeiro == null || primeiro.id == null || idBarbearia == null) {
      return;
    }

    final bool alterada = await openEditarReserva(
      context,
      barbeariaId: idBarbearia,
      nomeBarbearia: primeiro.nomeBarbearia,
      edicao: AgendamentoEdicao(itens: editaveis, idOrdem: idOrdem),
    );
    if (alterada && mounted) {
      await _loadAgendamentos(forceRefresh: true);
    }
  }

  /// Nota e comentário de um serviço concluído; a nota vem da API ao recarregar.
  Future<void> _avaliar(AgendamentoModel agendamento) async {
    final bool? enviou = await showAvaliarServicoModal(
      context: context,
      agendamento: agendamento,
    );
    if (enviou == true && mounted) {
      await _loadAgendamentos(forceRefresh: true);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    if (position.maxScrollExtent <= 0) {
      return;
    }

    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMoreAgendamentos();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    // Cancelou ou atualizou a lista: o lembrete da Dynamic Island acompanha.
    _lembrete = bloc.stream.listen((AgendamentosState state) {
      if (state is AgendamentosSuccessState) {
        LembreteAgendamento.instance.usarAgendamentos(state.itens);
      }
    });
    _loadAgendamentos();
    getPoliticaAgendamento().then((PoliticaAgendamentoModel politica) {
      if (mounted) {
        _politica = politica;
      }
    });
  }

  Widget _footerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: appLoadingRazor(size: 40),
    );
  }

  Widget _lista(AgendamentosSuccessState state) {
    if (state.itens.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        // Centraliza no espaço restante, descontando a barra de navegação.
        child: Padding(
          padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: Center(
            child: homeEmptyState(
              message: 'Nenhum agendamento por aqui',
              icon: Phosphor.calendarBlank,
              iconSize: 48,
            ),
          ),
        ),
      );
    }

    // Cabeçalho de cada grupo (Próximos, Hoje, Ontem, ...) seguido dos cards
    // dele; serviços marcados juntos viram um card de ordem de serviço.
    final List<Object> linhas = <Object>[
      for (final ({GrupoAgendamento grupo, List<AgendamentoModel> itens}) bloco
          in agrupaAgendamentos(state.itens, DateTime.now())) ...[
        bloco.grupo,
        ...juntaOrdensServico(bloco.itens),
      ],
    ];

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.giant + kBottomNavigationBarHeight,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          if (index >= linhas.length) {
            return _footerLoading();
          }

          final Object linha = linhas[index];

          if (linha is GrupoAgendamento) {
            return _tituloGrupo(linha, primeiro: index == 0);
          }

          if (linha is OrdemServicoGrupo) {
            return ordemServicoCard(
              ordem: linha,
              onPagar: () => _pagarOrdem(linha),
              onComoChegar: () => _abrirRota(linha.primeiro),
              onCancelar: () => _confirmarCancelamentoOrdem(linha),
              onMostrarQr: (AgendamentoModel item) =>
                  showQrConfirmacaoModal(context: context, agendamento: item),
              onAvaliar: _avaliar,
              onEditar: linha.editaveisEm(DateTime.now()).isEmpty
                  ? null
                  : () => _editar(
                      editaveis: linha.editaveisEm(DateTime.now()),
                      idOrdem: linha.idApi,
                    ),
              cancelando: linha.itens.any(
                (AgendamentoModel item) => item.id == state.cancelandoId,
              ),
            );
          }

          final AgendamentoModel agendamento = linha as AgendamentoModel;

          return agendamentoListaCard(
            agendamento: agendamento,
            onComoChegar: () => _abrirRota(agendamento),
            onCancelar: () => _confirmarCancelamento(agendamento),
            onMostrarQr: agendamento.codigoQr == null
                ? null
                : () => showQrConfirmacaoModal(
                    context: context,
                    agendamento: agendamento,
                  ),
            onPagar: () => _pagar(agendamento),
            onAvaliar: () => _avaliar(agendamento),
            onEditar: agendamento.podeEditarEm(DateTime.now())
                ? () => _editar(
                    editaveis: <AgendamentoModel>[agendamento],
                    idOrdem: int.tryParse(agendamento.idOrdemServico ?? ''),
                  )
                : null,
            cancelando: state.cancelandoId == agendamento.id,
          );
        }, childCount: linhas.length + (state.loadingMore ? 1 : 0)),
      ),
    );
  }

  Widget _tituloGrupo(GrupoAgendamento grupo, {required bool primeiro}) {
    return Padding(
      key: ValueKey<String>('grupo-${grupo.name}'),
      padding: EdgeInsets.only(
        top: primeiro ? 0 : AppSpacing.medium,
        bottom: AppSpacing.small,
        left: 2,
      ),
      child: appText(
        grupo.titulo,
        bold: true,
        fontSize: AppFontSizes.small,
        color: local.AppColors.textSecondary,
      ),
    );
  }

  Widget _conteudo(AgendamentosState state) {
    if (state is AgendamentosSuccessState) {
      return RefreshIndicator(
        color: local.AppColors.primary,
        onRefresh: () => _loadAgendamentos(forceRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // O título rola junto com a lista.
            SliverToBoxAdapter(child: _cabecalho()),
            _lista(state),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho(),
        Expanded(
          child: state is AgendamentosErrorState
              ? appError(
                  state.errorModel,
                  function: () => _loadAgendamentos(forceRefresh: true),
                )
              : appLoadingRazor(),
        ),
      ],
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium - 4,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            'Agenda',
            bold: true,
            fontSize: 26,
            color: local.AppColors.text,
          ),
          appSizedBox(height: 2),
          appText(
            'Acompanhe e gerencie seus horários',
            fontSize: AppFontSizes.verySmall,
            color: local.AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: local.AppColors.iconesBarraStatus,
        statusBarBrightness: local.AppColors.brilhoBarraStatus,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AgendamentosBloc, AgendamentosState>(
            bloc: bloc,
            builder: (BuildContext context, AgendamentosState state) {
              return _conteudo(state);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lembrete.cancel();
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }
}
