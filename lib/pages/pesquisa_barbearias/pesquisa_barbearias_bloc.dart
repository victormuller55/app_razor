import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/paginacao_model.dart';
import 'package:app_razor/pages/barbearias/barbearias_bloc.dart';
import 'package:app_razor/pages/barbearias/barbearias_service.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_event.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

const String avisoLocalizacaoNegada =
    'Localização não autorizada. Você pode pesquisar por cidade, bairro ou nome.';

const String avisoLocalizacaoIndisponivel =
    'Localização indisponível. Você pode pesquisar por cidade, bairro ou nome.';

class PesquisaBarbeariasBloc
    extends Bloc<PesquisaBarbeariasEvent, PesquisaBarbeariasState> {
  PesquisaBarbeariasBloc({
    GetBarbearias? getLista,
    GetGpsPosition? getGps,
  })  : _getBarbearias = getLista ?? getBarbearias,
        _getGps = getGps ?? getCurrentGps,
        super(PesquisaInicialState()) {
    on<PesquisaCarregarEvent>(_carregar);
    on<PesquisaCarregarMaisEvent>(_carregarMais);
  }

  final GetBarbearias _getBarbearias;
  final GetGpsPosition _getGps;

  int _geracao = 0;
  bool _gpsConsultado = false;
  double? _latitude;
  double? _longitude;
  String? _avisoLocalizacao;

  /// Marca a consulta atual como a única válida. Chamado antes do evento,
  /// para uma resposta que ainda está em voo ser descartada.
  void prepararConsulta() {
    _geracao++;
  }

  Future<void> _carregar(
    PesquisaCarregarEvent event,
    Emitter<PesquisaBarbeariasState> emit,
  ) async {
    final int minha = _geracao;
    emit(
      PesquisaLoadingState(
        filtros: event.filtros,
        avisoLocalizacao: _avisoLocalizacao,
        latitude: _latitude,
        longitude: _longitude,
      ),
    );

    await _garantirGps();
    if (minha != _geracao) {
      return;
    }

    try {
      final _Envelope envelope = await _buscar(
        numPag: 0,
        filtros: event.filtros,
      );
      if (minha != _geracao) {
        return;
      }

      emit(
        PesquisaSuccessState(
          itens: envelope.itens,
          paginacao: envelope.paginacao,
          filtros: event.filtros,
          avisoLocalizacao: _avisoLocalizacao,
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
    } catch (e) {
      if (minha != _geracao) {
        return;
      }
      emit(
        PesquisaErrorState(
          errorModel: errorModelFromApi(e),
          filtros: event.filtros,
          avisoLocalizacao: _avisoLocalizacao,
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
    }
  }

  Future<void> _carregarMais(
    PesquisaCarregarMaisEvent event,
    Emitter<PesquisaBarbeariasState> emit,
  ) async {
    final PesquisaBarbeariasState atual = state;
    if (atual is! PesquisaSuccessState || atual.loadingMore || !atual.paginacao.hasMore) {
      return;
    }

    final int minha = _geracao;
    final List<BarbeariaModel> itensAtuais = atual.itens;
    emit(
      PesquisaSuccessState(
        itens: itensAtuais,
        paginacao: atual.paginacao,
        filtros: atual.filtros,
        loadingMore: true,
        avisoLocalizacao: atual.avisoLocalizacao,
        latitude: atual.latitude,
        longitude: atual.longitude,
      ),
    );

    try {
      final _Envelope envelope = await _buscar(
        numPag: atual.paginacao.numPag + 1,
        filtros: atual.filtros,
      );
      if (minha != _geracao) {
        return;
      }

      emit(
        PesquisaSuccessState(
          itens: _unir(itensAtuais, envelope.itens),
          paginacao: envelope.paginacao,
          filtros: atual.filtros,
          avisoLocalizacao: atual.avisoLocalizacao,
          latitude: atual.latitude,
          longitude: atual.longitude,
        ),
      );
    } catch (e) {
      if (minha != _geracao) {
        return;
      }
      emit(
        PesquisaSuccessState(
          itens: itensAtuais,
          paginacao: atual.paginacao,
          filtros: atual.filtros,
          avisoLocalizacao: atual.avisoLocalizacao,
          latitude: atual.latitude,
          longitude: atual.longitude,
        ),
      );
      _avisar(errorModelFromApi(e));
    }
  }

  Future<_Envelope> _buscar({
    required int numPag,
    required BarbeariasFiltros filtros,
  }) async {
    final AppResponse response = await _getBarbearias(
      numPag: numPag,
      itensPag: barbeariasItensPag,
      filtrosQuery: filtros.toQuery(),
      latitude: _latitude,
      longitude: _longitude,
      forceRefresh: true,
    );
    return _ler(response);
  }

  Future<void> _garantirGps() async {
    if (_gpsConsultado) {
      return;
    }
    _gpsConsultado = true;
    try {
      final GpsPosition gps = await _getGps();
      _latitude = gps.latitude;
      _longitude = gps.longitude;
      _avisoLocalizacao = null;
    } catch (e) {
      _latitude = null;
      _longitude = null;
      _avisoLocalizacao = e is GpsException && e.mensagem == gpsMensagemPermissaoNegada
          ? avisoLocalizacaoNegada
          : avisoLocalizacaoIndisponivel;
    }
  }

  List<BarbeariaModel> _unir(
    List<BarbeariaModel> atuais,
    List<BarbeariaModel> novos,
  ) {
    final Set<int> ids = atuais.map((BarbeariaModel item) => item.id).whereType<int>().toSet();
    return <BarbeariaModel>[
      ...atuais,
      ...novos.where((BarbeariaModel item) {
        final int? id = item.id;
        if (id == null) {
          return true;
        }
        return ids.add(id);
      }),
    ];
  }

  _Envelope _ler(AppResponse response) {
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Resposta inválida da API');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final dynamic itensJson = json['itens'];
    if (itensJson is! List) {
      throw const FormatException('Resposta inválida da API');
    }
    final List<BarbeariaModel> itens = itensJson
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              BarbeariaModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return _Envelope(itens: itens, paginacao: PaginacaoModel.fromJson(json));
  }

  void _avisar(ErrorModel erro) {
    try {
      if (AppContext.navigatorKey.currentContext == null) {
        return;
      }
      showSnackbarError(message: erro.mensagem);
    } catch (_) {
      // Sem navigator nos testes.
    }
  }
}

class _Envelope {
  final List<BarbeariaModel> itens;
  final PaginacaoModel paginacao;

  const _Envelope({required this.itens, required this.paginacao});
}
