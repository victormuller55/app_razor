import 'dart:async';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/abrir_rota.dart';
import 'package:app_razor/functions/lembrete_agendamento.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_bloc.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
import 'package:app_razor/pages/agendamentos/widgets/agendamento_lista_card.dart';
import 'package:app_razor/pages/agendamentos/widgets/cancelar_agendamento_modal.dart';
import 'package:app_razor/pages/agendamentos/widgets/qr_confirmacao_modal.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
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
      onConfirmar: () => bloc.add(AgendamentosCancelEvent(id)),
    );
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
        child: homeEmptyState(
          message: 'Nenhum agendamento por aqui',
          icon: Phosphor.calendarBlank,
        ),
      );
    }

    // Cabeçalho de cada grupo (Próximos, Hoje, Ontem, ...) seguido dos cards dele.
    final List<Object> linhas = <Object>[
      for (final ({GrupoAgendamento grupo, List<AgendamentoModel> itens}) bloco
          in agrupaAgendamentos(state.itens, DateTime.now())) ...[
        bloco.grupo,
        ...bloco.itens,
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.white,
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
