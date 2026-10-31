import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/abrir_rota.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_bloc.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_event.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_state.dart';
import 'package:app_razor/pages/mapa_barbearias/widgets/barbearia_mapa_modal.dart';
import 'package:app_razor/widgets/app_error_razor.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muller_package/muller_package.dart';

class MapaBarbeariasPage extends StatefulWidget {
  const MapaBarbeariasPage({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoomInicial = 11,
    this.centroInicial,
    this.barbeariasIniciais = const <BarbeariaModel>[],
  });

  /// Pinos mostrados enquanto a lista do mapa carrega (a home passa os que já mostra, para não piscarem).
  final List<BarbeariaModel> barbeariasIniciais;

  final double latitude;
  final double longitude;

  /// Zoom inicial do mapa.
  final double zoomInicial;

  /// Quando vem da home: abre exatamente onde o mapa da home estava (centro e zoom) e não enquadra as
  /// barbearias, para a troca de mapa não aparecer.
  final LatLng? centroInicial;

  @override
  State<MapaBarbeariasPage> createState() => _MapaBarbeariasPageState();
}

class _MapaBarbeariasPageState extends State<MapaBarbeariasPage> {
  late final MapaBarbeariasBloc bloc;
  GoogleMapController? _controller;
  BarbeariaModel? _selecionada;

  /// Vindo da home, a tela começa invisível (a home com o mapa expandido aparece por trás) e só aparece
  /// depois que o mapa desenhou, para não piscar em branco.
  late bool _visivel = widget.centroInicial == null;

  void _mostrar() {
    if (mounted && !_visivel) {
      setState(() {
        _visivel = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Garantia caso o mapa demore: aparece de qualquer jeito.
    Future<void>.delayed(const Duration(milliseconds: 1200), _mostrar);
    bloc = MapaBarbeariasBloc(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    bloc.add(MapaBarbeariasLoadEvent());
  }

  Future<void> _fitBounds(List<BarbeariaModel> itens) async {
    final GoogleMapController? controller = _controller;

    if (controller == null || widget.centroInicial != null) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          AppMaps.boundsFor(
            latitude: widget.latitude,
            longitude: widget.longitude,
            barbearias: itens,
          ),
          64,
        ),
      );
    } catch (_) {
      // Mapa ainda não tem tamanho.
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    // O controller chega antes dos tiles; a espera cobre o primeiro desenho do mapa.
    Future<void>.delayed(const Duration(milliseconds: 350), _mostrar);

    final MapaBarbeariasState state = bloc.state;
    if (state is MapaBarbeariasSuccessState) {
      _fitBounds(state.itens);
    }
  }

  void _selecionar(BarbeariaModel barbearia) {
    setState(() {
      _selecionada = barbearia;
    });

    final double? latitude = barbearia.latitude;
    final double? longitude = barbearia.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    // Centraliza e aproxima na barbearia tocada; o centro do mapa fica acima do card.
    _controller
        ?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 16),
        )
        .catchError((_) {});
  }

  void _fecharCard() {
    if (_selecionada == null) {
      return;
    }

    setState(() {
      _selecionada = null;
    });
  }

  void _verBarbearia(BarbeariaModel barbearia) {
    final int? id = barbearia.id;

    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }

    openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
  }

  Future<void> _comoChegar(BarbeariaModel barbearia) async {
    try {
      await abrirRotaBarbearia(
        latitude: barbearia.latitude,
        longitude: barbearia.longitude,
        nome: barbearia.nome,
      );
    } catch (_) {
      showSnackbarWarning(message: rotaMensagemIndisponivel);
    }
  }

  /// Card da barbearia selecionada, por cima do mapa e sem bloquear o resto dele.
  Widget _card() {
    final BarbeariaModel? barbearia = _selecionada;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: AppSpacing.medium,
      right: AppSpacing.medium,
      bottom: AppSpacing.medium + bottomInset,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: barbearia == null
            ? const SizedBox.shrink()
            : KeyedSubtree(
                key: ValueKey<int?>(barbearia.id),
                child: barbeariaMapaCard(
                  barbearia: barbearia,
                  onVerBarbearia: () => _verBarbearia(barbearia),
                  onComoChegar: () => _comoChegar(barbearia),
                  onFechar: _fecharCard,
                ),
              ),
      ),
    );
  }

  Widget _mapa(List<BarbeariaModel> itens) {
    return AppMaps.map(
      latitude: widget.centroInicial?.latitude ?? widget.latitude,
      longitude: widget.centroInicial?.longitude ?? widget.longitude,
      barbearias: itens,
      interactive: true,
      myLocationEnabled: true,
      zoom: widget.zoomInicial,
      onMapCreated: _onMapCreated,
      onBarbeariaTap: _selecionar,
      onTap: (_) => _fecharCard(),
    );
  }

  Widget _conteudo(MapaBarbeariasState state) {
    if (state is MapaBarbeariasErrorState) {
      return appErrorRazor(
        state.errorModel,
        function: () => bloc.add(MapaBarbeariasLoadEvent(forceRefresh: true)),
      );
    }

    // Sem loading por cima: o mapa aparece na hora e os pinos entram quando a lista chega. A mesma
    // árvore nos dois estados, para o GoogleMap não ser recriado.
    return Stack(
      fit: StackFit.expand,
      children: [
        _mapa(
          state is MapaBarbeariasSuccessState
              ? state.itens
              : widget.barbeariasIniciais,
        ),
        _card(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // Quase zero em vez de zero: com opacidade zero o mapa não é desenhado e não carrega.
      opacity: _visivel ? 1 : 0.01,
      duration: const Duration(milliseconds: 200),
      child: _tela(),
    );
  }

  /// Voltar flutuando sobre o mapa: liquid glass nativo no iOS, botão redondo no Android.
  Widget _botaoVoltar() {
    void voltar() => Navigator.of(context).maybePop();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return CNButton.icon(
        icon: const CNSymbol('chevron.left', size: 18),
        onPressed: voltar,
      );
    }

    return Material(
      color: local.AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: voltar,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Phosphor.arrowLeft,
            size: 20,
            color: local.AppColors.text,
          ),
        ),
      ),
    );
  }

  /// Mapa em tela cheia (inclusive atrás da barra de status e da área de baixo), sem app bar.
  Widget _tela() {
    final EdgeInsets inset = MediaQuery.viewPaddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            BlocConsumer<MapaBarbeariasBloc, MapaBarbeariasState>(
              bloc: bloc,
              listener: (BuildContext context, MapaBarbeariasState state) {
                if (state is MapaBarbeariasSuccessState) {
                  _fitBounds(state.itens);
                }
              },
              builder: (BuildContext context, MapaBarbeariasState state) {
                return _conteudo(state);
              },
            ),
            Positioned(
              top: inset.top + AppSpacing.small + 3,
              left: AppSpacing.medium,
              child: _botaoVoltar(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller = null;
    bloc.close();
    super.dispose();
  }
}
