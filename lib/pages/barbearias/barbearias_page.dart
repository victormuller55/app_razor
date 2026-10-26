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
import 'package:app_razor/widgets/app_campo_busca.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';


/// Altura dos campos e botões do cabeçalho.
const double _alturaCampo = appCampoBuscaAltura;

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
    return appCampoBusca(onTap: _openPesquisa);
  }

  Widget _botaoFiltros() {
    final bool ativo = _filtros.hasFiltros;

    return GestureDetector(
      onTap: _openFiltros,
      child: Tooltip(
        message: AppStrings.abrirFiltros,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _alturaCampo,
              height: _alturaCampo,
              decoration: BoxDecoration(
                color: local.AppColors.primary,
                borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
              ),
              child: const Icon(
                Phosphor.slidersHorizontal,
                color: local.AppColors.white,
              ),
            ),
            if (ativo)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppEstilo.destaque,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: local.AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium - 4,
        AppSpacing.medium,
        AppSpacing.medium - 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            AppStrings.barbearias,
            bold: true,
            fontSize: 26,
            color: local.AppColors.text,
          ),
          appSizedBox(height: 2),
          appText(
            'Encontre a barbearia ideal perto de você',
            fontSize: AppFontSizes.verySmall,
            color: local.AppColors.textSecondary,
          ),
          appSizedBox(height: AppSpacing.medium - 4),
          Row(
            children: [
              Expanded(child: _campoPesquisa()),
              appSizedBox(width: AppSpacing.normal),
              _botaoFiltros(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: appLoadingRazor(size: 32),
    );
  }

  Widget _estadoCentral(Widget child) {
    // Ocupa o espaço restante abaixo da busca e centraliza o conteúdo nele,
    // descontando a barra de navegação que fica por cima do corpo.
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.medium,
          0,
          AppSpacing.medium,
          kBottomNavigationBarHeight,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _listaItens(BarbeariasState state) {
    final double espacoHorizontal = AppSpacing.medium - 6;
    final double larguraCard =
        (MediaQuery.sizeOf(context).width -
            AppSpacing.medium * 2 -
            espacoHorizontal) /
        2;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.giant + kBottomNavigationBarHeight,
      ),
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.medium,
              crossAxisSpacing: espacoHorizontal,
              mainAxisExtent: larguraCard + barbeariaGridCardAlturaTexto,
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
      return _estadoCentral(appLoadingRazor());
    }

    if (state is BarbeariasErrorState) {
      return _estadoCentral(
        appError(
          state.errorModel,
          function: () {
            _loadBarbearias();
          },
        ),
      );
    }

    if (state.itens.isEmpty) {
      return _estadoCentral(
        homeEmptyState(
          message: AppStrings.nenhumaBarbeariaEncontrada,
          icon: Phosphor.storefront,
          iconSize: 48,
        ),
      );
    }

    return _listaItens(state);
  }

  Widget _bodyTela(BarbeariasState state) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: local.AppColors.primary,
        onRefresh: () => _loadBarbearias(forceRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // O título e a busca rolam junto com a lista.
            SliverToBoxAdapter(child: _cabecalho()),
            SliverToBoxAdapter(
              child: appSizedBox(height: AppSpacing.small),
            ),
            _conteudoLista(state),
          ],
        ),
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
        body: BlocBuilder<BarbeariasBloc, BarbeariasState>(
          bloc: bloc,
          builder: (BuildContext context, BarbeariasState state) {
            return _bodyTela(state);
          },
        ),
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
