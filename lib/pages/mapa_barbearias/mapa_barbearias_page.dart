import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_bloc.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_event.dart';
import 'package:app_razor/pages/mapa_barbearias/mapa_barbearias_state.dart';
import 'package:app_razor/pages/mapa_barbearias/widgets/barbearia_mapa_modal.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muller_package/muller_package.dart';

class MapaBarbeariasPage extends StatefulWidget {
  const MapaBarbeariasPage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<MapaBarbeariasPage> createState() => _MapaBarbeariasPageState();
}

class _MapaBarbeariasPageState extends State<MapaBarbeariasPage> {
  late final MapaBarbeariasBloc bloc;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    bloc = MapaBarbeariasBloc(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    bloc.add(MapaBarbeariasLoadEvent());
  }

  Future<void> _fitBounds(List<BarbeariaModel> itens) async {
    final GoogleMapController? controller = _controller;

    if (controller == null) {
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

    final MapaBarbeariasState state = bloc.state;
    if (state is MapaBarbeariasSuccessState) {
      _fitBounds(state.itens);
    }
  }

  void _abrirModal(BarbeariaModel barbearia) {
    showBarbeariaMapaModal(
      context: context,
      barbearia: barbearia,
      onVerBarbearia: () {
        final int? id = barbearia.id;

        if (id == null) {
          showSnackbarWarning(message: 'Barbearia indisponível');
          return;
        }

        openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
      },
    );
  }

  Widget _mapa(List<BarbeariaModel> itens) {
    return AppMaps.map(
      latitude: widget.latitude,
      longitude: widget.longitude,
      barbearias: itens,
      interactive: true,
      myLocationEnabled: true,
      zoom: 11,
      onMapCreated: _onMapCreated,
      onBarbeariaTap: _abrirModal,
    );
  }

  Widget _conteudo(MapaBarbeariasState state) {
    if (state is MapaBarbeariasErrorState) {
      return appError(
        state.errorModel,
        function: () => bloc.add(MapaBarbeariasLoadEvent(forceRefresh: true)),
      );
    }

    if (state is MapaBarbeariasSuccessState) {
      return _mapa(state.itens);
    }

    return Stack(
      children: [
        _mapa(const <BarbeariaModel>[]),
        ColoredBox(
          color: local.AppColors.background.withValues(alpha: 0.55),
          child: appLoadingRazor(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: 'Mapa',
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: BlocConsumer<MapaBarbeariasBloc, MapaBarbeariasState>(
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
    );
  }

  @override
  void dispose() {
    _controller = null;
    bloc.close();
    super.dispose();
  }
}
