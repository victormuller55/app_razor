import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/favoritas.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/functions/media_url.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:app_razor/pages/home/home_bloc.dart';
import 'package:app_razor/pages/home/home_event.dart';
import 'package:app_razor/pages/home/home_state.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/pages/home/widgets/home_favorita_card.dart';
import 'package:app_razor/pages/home/widgets/home_promocao_card.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_page.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_page.dart';
import 'package:app_razor/widgets/app_campo_busca.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onOpenPerfil,
  });

  final VoidCallback? onOpenPerfil;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _folhaRadius = AppRadii.externo;
  static const double _headerPaddingTop = 10;
  static const double _headerPaddingBottom = 12;
  static const double _headerAvatarDiameter = 28;

  HomeBloc bloc = HomeBloc();

  UsuarioModel usuario = UsuarioModel.empty();

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showTitle = ValueNotifier(false);
  final ValueNotifier<double> _folhaRadiusAtual = ValueNotifier(_folhaRadius);


  Future<void> _loadUsuario() async {
    final UsuarioModel local = await getLocalUserModel();

    if (!mounted) {
      return;
    }

    setState(() {
      usuario = local;
    });
  }

  Future<void> _loadHome({bool forceRefresh = false}) async {
    bloc.add(HomeLoadEvent(forceRefresh: forceRefresh));
  }

  double _alturaHeaderColapsado(double topInset) {
    return topInset +
        _headerPaddingTop +
        _headerAvatarDiameter +
        _headerPaddingBottom;
  }

  void _atualizarRaioFolha() {
    if (!_scrollController.hasClients || !mounted) {
      return;
    }

    final MediaQueryData media = MediaQuery.of(context);
    final double topInset = media.viewPadding.top;
    final double alturaMapa = media.size.height * 0.32 + topInset;
    final double headerBottom = _alturaHeaderColapsado(topInset);
    final double topoInicial = alturaMapa - _folhaRadius;
    final double gapInicial = topoInicial - headerBottom;

    if (gapInicial <= 0) {
      if (_folhaRadiusAtual.value != 0) {
        _folhaRadiusAtual.value = 0;
      }
      return;
    }

    final double topoAtual = topoInicial - _scrollController.offset;
    final double progresso =
        (1 - (topoAtual - headerBottom) / gapInicial).clamp(0.0, 1.0);
    final double radius = _folhaRadius * (1 - progresso);

    if ((_folhaRadiusAtual.value - radius).abs() >= 0.4) {
      _folhaRadiusAtual.value = radius;
    } else if (progresso >= 1 && _folhaRadiusAtual.value != 0) {
      _folhaRadiusAtual.value = 0;
    } else if (progresso <= 0 && _folhaRadiusAtual.value != _folhaRadius) {
      _folhaRadiusAtual.value = _folhaRadius;
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    _atualizarRaioFolha();

    final bool collapsed = _scrollController.offset > 100;

    if (collapsed && !_showTitle.value) {
      _showTitle.value = true;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
    } else if (!collapsed && _showTitle.value) {
      _showTitle.value = false;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    }
  }

  void _openAbaPerfil() {
    widget.onOpenPerfil?.call();
  }

  void _openBusca() {
    open(screen: const PesquisaBarbeariasPage());
  }

  void _openMapa(HomeState state) {
    final double? latitude = state.latitude;
    final double? longitude = state.longitude;

    if (latitude == null || longitude == null) {
      showSnackbarWarning(message: gpsMensagemIndisponivel);
      return;
    }

    open(
      screen: MapaBarbeariasPage(
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  void _openBarbearia(BarbeariaModel barbearia) {
    final int? id = barbearia.id;

    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }

    openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
  }

  void _openPromocao(PromocaoModel promocao) {
    final int? id = promocao.barbearia?.id;

    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }

    openBarbeariaPerfil(barbeariaId: id, nome: promocao.barbearia?.nome);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    favoritasAlteradas.addListener(_recarregarFavoritas);
    _loadUsuario();
    _loadHome();
  }

  void _recarregarFavoritas() {
    bloc.add(HomeFavoritasEvent());
  }

  Widget _avatarUsuario({double radius = 24}) {
    final String? url = resolveMediaUrl(usuario.foto);

    return CircleAvatar(
      radius: radius,
      backgroundColor: local.AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: url == null ? null : NetworkImage(url),
      child: url == null
          ? Icon(
              Phosphor.user,
              size: radius,
              color: local.AppColors.primary,
            )
          : null,
    );
  }

  Widget _rowTitulo() {
    return Row(
      children: [
        Expanded(
          child: appText(
            (usuario.nome ?? AppStrings.vazio).toUpperCase(),
            color: local.AppColors.white,
            fontSize: AppFontSizes.small,
            bold: true,
            maxLines: 1,
            overflow: true,
          ),
        ),
        _avatarUsuario(radius: 14),
      ],
    );
  }

  Widget _headerMapa(HomeState state) {
    final double? latitude = state.latitude;
    final double? longitude = state.longitude;

    if (latitude == null || longitude == null) {
      return ColoredBox(color: local.AppColors.primary);
    }

    return AppMaps.map(
      latitude: latitude,
      longitude: longitude,
      interactive: false,
      myLocationEnabled: true,
      padding: const EdgeInsets.only(bottom: _folhaRadius),
      barbearias: state.proximas.status == HomeSecaoStatus.success
          ? state.proximas.itens
          : const <BarbeariaModel>[],
    );
  }

  Widget _blocoPerfil() {
    final String nome = (usuario.nome ?? AppStrings.vazio).trim();
    final String primeiroNome = nome.split(' ').first;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openAbaPerfil,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  'Olá, $primeiroNome',
                  bold: true,
                  fontSize: 24,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.text,
                ),
                appSizedBox(height: 2),
                appText(
                  'Qual vai ser o corte de hoje?',
                  fontSize: AppFontSizes.verySmall,
                  color: local.AppColors.textSecondary,
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.normal),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppEstilo.campoFundo,
            ),
            child: _avatarUsuario(),
          ),
        ],
      ),
    );
  }

  Widget _campoBusca() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium, bottom: AppSpacing.medium),
      child: appCampoBusca(onTap: _openBusca),
    );
  }

  Widget _tituloSecao(String titulo) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal + 2),
      child: appText(
        titulo,
        bold: true,
        fontSize: 18,
        color: local.AppColors.text,
      ),
    );
  }

  Widget _estadoSecao(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 6),
      ),
      child: child,
    );
  }

  Widget _secaoStatus({
    required HomeSecaoStatus status,
    required ErrorModel errorModel,
    required bool isEmpty,
    required String emptyMessage,
    IconData? emptyIcon,
    required Widget lista,
  }) {
    if (status == HomeSecaoStatus.error) {
      return GestureDetector(
        onTap: () => _loadHome(forceRefresh: true),
        child: _estadoSecao(
          homeEmptyState(
            icon: Phosphor.warningCircle,
            message: errorModel.mensagem ?? AppStrings.ocorreuUmErro,
          ),
        ),
      );
    }

    if (isEmpty) {
      return _estadoSecao(
        homeEmptyState(
          icon: emptyIcon,
          iconSize: 28,
          message: emptyMessage,
        ),
      );
    }

    return lista;
  }

  Widget _listaFavoritas(List<BarbeariaModel> favoritas) {
    return appScrollHorizontal(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: favoritas
            .map(
              (BarbeariaModel barbearia) => homeFavoritaCard(
                barbearia: barbearia,
                onTap: () => _openBarbearia(barbearia),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _listaProximas(List<BarbeariaModel> proximas) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < proximas.length; i++)
          homeProximaCard(
            barbearia: proximas[i],
            onTap: () => _openBarbearia(proximas[i]),
            divisor: i < proximas.length - 1,
          ),
      ],
    );
  }

  Widget _listaPromocoes(List<PromocaoModel> promocoes) {
    return Column(
      children: promocoes
          .map(
            (PromocaoModel promocao) => homePromocaoCard(
              promocao: promocao,
              onTap: () => _openPromocao(promocao),
            ),
          )
          .toList(),
    );
  }

  Widget _secaoFavoritas() {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: bloc,
      buildWhen: (HomeState previous, HomeState current) {
        return previous.favoritas != current.favoritas;
      },
      builder: (BuildContext context, HomeState secaoState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSecao(AppStrings.barbeariasFavoritas),
            _secaoStatus(
              status: secaoState.favoritas.status,
              errorModel: secaoState.favoritas.errorModel,
              isEmpty: secaoState.favoritas.isEmpty,
              emptyMessage: AppStrings.nenhumaFavoritaEncontrada,
              emptyIcon: Phosphor.heart,
              lista: _listaFavoritas(secaoState.favoritas.itens),
            ),
          ],
        );
      },
    );
  }

  Widget _secaoProximas() {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: bloc,
      buildWhen: (HomeState previous, HomeState current) {
        return previous.proximas != current.proximas;
      },
      builder: (BuildContext context, HomeState secaoState) {
        return Padding(
          padding: EdgeInsets.only(top: AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSecao(AppStrings.barbeariasProximas),
              _secaoStatus(
                status: secaoState.proximas.status,
                errorModel: secaoState.proximas.errorModel,
                isEmpty: secaoState.proximas.isEmpty,
                emptyMessage: AppStrings.nenhumaBarbeariaEncontrada,
                emptyIcon: Phosphor.storefront,
                lista: _listaProximas(secaoState.proximas.itens),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _secaoPromocoes() {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: bloc,
      buildWhen: (HomeState previous, HomeState current) {
        return previous.promocoes != current.promocoes;
      },
      builder: (BuildContext context, HomeState secaoState) {
        return Padding(
          padding: EdgeInsets.only(top: AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSecao(AppStrings.promocoes),
              _secaoStatus(
                status: secaoState.promocoes.status,
                errorModel: secaoState.promocoes.errorModel,
                isEmpty: secaoState.promocoes.isEmpty,
                emptyMessage: AppStrings.nenhumaPromocaoEncontrada,
                emptyIcon: Phosphor.tag,
                lista: _listaPromocoes(secaoState.promocoes.itens),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _secoesListas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secaoFavoritas(),
        _secaoProximas(),
        _secaoPromocoes(),
      ],
    );
  }

  Widget _conteudoScroll({required double alturaMinima}) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: bloc,
      buildWhen: (HomeState previous, HomeState current) {
        return previous.favoritas != current.favoritas ||
            previous.proximas != current.proximas ||
            previous.promocoes != current.promocoes;
      },
      builder: (BuildContext context, HomeState state) {
        final bool secoesVazias = state.todasSecoesVazias;
        final bool carregando = state.carregando;
        final double paddingBottom =
            AppSpacing.giant + kBottomNavigationBarHeight;
        final double alturaCentro = (alturaMinima -
                AppSpacing.medium * 2 -
                paddingBottom -
                72)
            .clamp(180.0, 560.0);

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: alturaMinima),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              paddingBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _blocoPerfil(),
                if (carregando)
                  SizedBox(
                    height: alturaCentro,
                    width: double.infinity,
                    child: appLoadingRazor(),
                  )
                else if (secoesVazias)
                  homeEmptyStateCentral(
                    message: homeMensagemSemBarbeariasProximas,
                    height: alturaCentro,
                  )
                else ...[
                  _campoBusca(),
                  _secoesListas(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _folhaConteudo({required double alturaMinima}) {
    return ValueListenableBuilder<double>(
      valueListenable: _folhaRadiusAtual,
      builder: (BuildContext context, double radius, Widget? child) {
        final BorderRadius geometria = BorderRadius.vertical(
          top: Radius.circular(radius),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: local.AppColors.surface,
            borderRadius: geometria,
            boxShadow: radius < 0.5
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: geometria,
            child: child,
          ),
        );
      },
      child: _conteudoScroll(alturaMinima: alturaMinima),
    );
  }

  Widget _headerColapsado(double topInset) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTitle,
      builder: (BuildContext context, bool show, Widget? child) {
        return IgnorePointer(
          ignoring: !show,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: local.AppColors.primary,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  topInset + _headerPaddingTop,
                  AppSpacing.medium,
                  _headerPaddingBottom,
                ),
                child: _rowTitulo(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bodyTela(HomeState state) {
    final double topInset = MediaQuery.viewPaddingOf(context).top;
    final double alturaTela = MediaQuery.sizeOf(context).height;
    final double alturaMapa = alturaTela * 0.32 + topInset;
    final double alturaFolha = alturaTela - alturaMapa + _folhaRadius;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: alturaMapa,
          child: ClipRect(child: _headerMapa(state)),
        ),
        CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _openMapa(state),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(height: alturaMapa - _folhaRadius),
              ),
            ),
            SliverToBoxAdapter(
              child: _folhaConteudo(alturaMinima: alturaFolha),
            ),
          ],
        ),
        _headerColapsado(topInset),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.surface,
        body: BlocBuilder<HomeBloc, HomeState>(
          bloc: bloc,
          buildWhen: (HomeState previous, HomeState current) {
            return previous.latitude != current.latitude ||
                previous.longitude != current.longitude ||
                previous.proximas != current.proximas;
          },
          builder: (BuildContext context, HomeState state) {
            return _bodyTela(state);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    favoritasAlteradas.removeListener(_recarregarFavoritas);
    _scrollController.dispose();
    _showTitle.dispose();
    _folhaRadiusAtual.dispose();
    bloc.close();
    super.dispose();
  }
}
