import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/barbearias/barbearias_bloc.dart';
import 'package:app_razor/pages/barbearias/barbearias_event.dart';
import 'package:app_razor/pages/barbearias/barbearias_state.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros_modal.dart';
import 'package:app_razor/pages/barbearias/widgets/barbearia_grid_card.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_page.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class BarbeariasPage extends StatefulWidget {
  const BarbeariasPage({super.key});

  @override
  State<BarbeariasPage> createState() => _BarbeariasPageState();
}

class _BarbeariasPageState extends State<BarbeariasPage> {
  BarbeariasBloc bloc = BarbeariasBloc();

  final ScrollController _scrollController = ScrollController();
  BarbeariasFiltros _filtros = BarbeariasFiltros.empty();

  Future<void> _loadBarbearias({bool forceRefresh = false}) async {
    final Future<BarbeariasState> done = bloc.stream.firstWhere(
      (BarbeariasState state) =>
          state is BarbeariasSuccessState || state is BarbeariasErrorState,
    );

    bloc.add(
      BarbeariasLoadEvent(
        filtros: _filtros,
        forceRefresh: forceRefresh,
      ),
    );

    await done;
  }

  void _loadMoreBarbearias() {
    bloc.add(BarbeariasLoadMoreEvent());
  }

  void _openPesquisa() {
    open(screen: const PesquisaBarbeariasPage());
  }

  void _openFiltros() {
    showBarbeariasFiltrosModal(
      context: context,
      filtros: _filtros,
      onApply: _applyFiltros,
      temLocalizacao: bloc.state.latitude != null && bloc.state.longitude != null,
    );
  }

  void _applyFiltros(BarbeariasFiltros filtros) {
    _filtros = filtros;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _loadBarbearias();
  }

  void _openBarbearia(BarbeariaModel barbearia) {
    final int? id = barbearia.id;

    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }

    openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
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
      _loadMoreBarbearias();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadBarbearias();
  }

  Widget _campoPesquisa() {
    return GestureDetector(
      onTap: _openPesquisa,
      child: appContainer(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.normal),
        backgroundColor: local.AppColors.inputBackground,
        radius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: local.AppColors.border),
        child: Row(
          children: [
            Icon(
              Phosphor.magnifyingGlass,
              size: 18,
              color: local.AppColors.iconMuted,
            ),
            appSizedBox(width: AppSpacing.normal),
            Expanded(
              child: appText(
                AppStrings.digiteAlgoParaPesquisar,
                color: local.AppColors.textSecondary,
                fontSize: 15,
                maxLines: 1,
                overflow: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoFiltros() {
    return GestureDetector(
      onTap: _openFiltros,
      child: Tooltip(
        message: AppStrings.abrirFiltros,
        child: appContainer(
          width: 48,
          height: 48,
          backgroundColor: _filtros.hasFiltros
              ? local.AppColors.primaryDark
              : local.AppColors.primary,
          radius: BorderRadius.circular(AppRadius.medium),
          child: Icon(Phosphor.funnel, color: local.AppColors.white),
        ),
      ),
    );
  }

  Widget _headerBusca() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal,
        AppSpacing.medium,
        AppSpacing.normal,
      ),
      child: Row(
        children: [
          Expanded(child: _campoPesquisa()),
          appSizedBox(width: AppSpacing.normal),
          _botaoFiltros(),
        ],
      ),
    );
  }

  Widget _footerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: appLoadingRazor(size: 40),
    );
  }

  Widget _listaVazia() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.normal,
          AppSpacing.medium,
          kBottomNavigationBarHeight,
        ),
        child: Center(
          child: homeEmptyState(
            message: AppStrings.nenhumaBarbeariaEncontrada,
            icon: Phosphor.storefront,
            iconSize: 48,
          ),
        ),
      ),
    );
  }

  Widget _listaItens(BarbeariasState state) {
    final double larguraCard =
        (MediaQuery.sizeOf(context).width -
            AppSpacing.medium * 2 -
            AppSpacing.normal) /
        2;
    const double alturaTextoCard = 100;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal,
        AppSpacing.medium,
        AppSpacing.giant + kBottomNavigationBarHeight,
      ),
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.normal,
              crossAxisSpacing: AppSpacing.normal,
              mainAxisExtent: larguraCard + alturaTextoCard,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final BarbeariaModel barbearia = state.itens[index];

                return barbeariaGridCard(
                  barbearia: barbearia,
                  onTap: () => _openBarbearia(barbearia),
                );
              },
              childCount: state.itens.length,
            ),
          ),
          if (state.loadingMore)
            SliverToBoxAdapter(
              child: _footerLoading(),
            ),
        ],
      ),
    );
  }

  Widget _conteudoLista(BarbeariasState state) {
    if (state is BarbeariasInitialState || state is BarbeariasLoadingState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: appLoadingRazor(),
      );
    }

    if (state is BarbeariasErrorState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: appError(
          state.errorModel,
          function: () {
            _loadBarbearias();
          },
        ),
      );
    }

    if (state.itens.isEmpty) {
      return _listaVazia();
    }

    return _listaItens(state);
  }

  Widget _bodyTela(BarbeariasState state) {
    return RefreshIndicator(
      color: local.AppColors.primary,
      onRefresh: () => _loadBarbearias(forceRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _headerBusca()),
          _conteudoLista(state),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: AppStrings.barbearias,
      hideBackIcon: true,
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: BlocBuilder<BarbeariasBloc, BarbeariasState>(
        bloc: bloc,
        builder: (BuildContext context, BarbeariasState state) {
          return _bodyTela(state);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }
}
