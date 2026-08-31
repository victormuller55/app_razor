import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/abrir_rota.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_bloc.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_event.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_state.dart';
import 'package:app_razor/pages/agendamentos/widgets/agendamento_lista_card.dart';
import 'package:app_razor/pages/agendamentos/widgets/cancelar_agendamento_modal.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
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

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal,
        AppSpacing.medium,
        AppSpacing.giant + kBottomNavigationBarHeight,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index >= state.itens.length) {
              return _footerLoading();
            }

            return agendamentoListaCard(
              agendamento: state.itens[index],
              onComoChegar: () => _abrirRota(state.itens[index]),
              onCancelar: () => _confirmarCancelamento(state.itens[index]),
              cancelando: state.cancelandoId == state.itens[index].id,
            );
          },
          childCount: state.itens.length + (state.loadingMore ? 1 : 0),
        ),
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
          slivers: <Widget>[_lista(state)],
        ),
      );
    }

    if (state is AgendamentosErrorState) {
      return appError(
        state.errorModel,
        function: () => _loadAgendamentos(forceRefresh: true),
      );
    }

    return appLoadingRazor();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgendamentosBloc, AgendamentosState>(
      bloc: bloc,
      builder: (BuildContext context, AgendamentosState state) {
        return scaffold(
          title: 'Agenda',
          hideBackIcon: true,
          background: local.AppColors.background,
          appBarColor: local.AppColors.primary,
          body: _conteudo(state),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }
}
