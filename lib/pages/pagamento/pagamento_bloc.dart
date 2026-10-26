import 'dart:async';
import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/pagamento_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_event.dart';
import 'package:app_razor/pages/pagamento/pagamento_service.dart';
import 'package:app_razor/pages/pagamento/pagamento_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef ChamadaPagamento =
    Future<AppResponse> Function({required int idAgendamento});

/// Pix de um agendamento: gera o QR Code pela API e só mostra "pago" quando a API confirmar com o
/// Mercado Pago. Enquanto o Pix está na tela, confere o status de tempos em tempos.
/// Toques repetidos enquanto algo está em andamento são ignorados.
class PagamentoBloc extends Bloc<PagamentoEvent, PagamentoState> {
  PagamentoBloc({
    required this.idAgendamento,
    ChamadaPagamento? iniciar,
    ChamadaPagamento? consultar,
    this.intervaloConsulta = const Duration(seconds: 5),
  }) : _iniciar = iniciar ?? iniciarPagamento,
       _consultar = consultar ?? consultarPagamento,
       super(PagamentoState.inicio()) {
    on<PagamentoIniciarEvent>(_iniciarPagamento);
    on<PagamentoRetornouEvent>(_consultarAgora);
    on<PagamentoConsultarEvent>(_consultarAgora);
  }

  final int idAgendamento;
  final ChamadaPagamento _iniciar;
  final ChamadaPagamento _consultar;

  /// De quanto em quanto tempo confere o Pix aberto (a API limita as consultas ao provedor).
  final Duration intervaloConsulta;
  bool _ocupado = false;
  DateTime? _ultimoInicio;
  Timer? _timer;
  static const Duration _intervaloMinimoInicio = Duration(seconds: 1);

  Future<void> _iniciarPagamento(
    PagamentoIniciarEvent event,
    Emitter<PagamentoState> emit,
  ) async {
    final DateTime agora = DateTime.now();
    final bool toqueRepetido =
        _ultimoInicio != null && agora.difference(_ultimoInicio!) < _intervaloMinimoInicio;
    if (_ocupado || toqueRepetido || state.etapa == EtapaPagamento.aprovado) {
      return;
    }
    _ultimoInicio = agora;
    _ocupado = true;
    emit(state.copiar(etapa: EtapaPagamento.preparando));

    try {
      emit(_estadoDe(_ler(await _iniciar(idAgendamento: idAgendamento))));
    } catch (e) {
      emit(_estadoDeErro(e));
    } finally {
      _ocupado = false;
      _acompanhar();
    }
  }

  /// Confere com a API. Falha de rede durante o Pix aberto não tira o QR Code da tela.
  Future<void> _consultarAgora(
    PagamentoEvent event,
    Emitter<PagamentoState> emit,
  ) async {
    if (_ocupado || state.pagamento == null || state.etapa == EtapaPagamento.aprovado) {
      return;
    }
    _ocupado = true;
    final bool pixNaTela = state.etapa == EtapaPagamento.aguardandoPix;
    if (!pixNaTela) {
      emit(state.copiar(etapa: EtapaPagamento.verificando));
    }

    try {
      emit(_estadoDe(_ler(await _consultar(idAgendamento: idAgendamento))));
    } catch (e) {
      if (!pixNaTela) {
        emit(_estadoDeErro(e));
      }
    } finally {
      _ocupado = false;
      _acompanhar();
    }
  }

  /// Enquanto o Pix estiver aberto, agenda a próxima conferência.
  void _acompanhar() {
    _timer?.cancel();
    if (isClosed || state.etapa != EtapaPagamento.aguardandoPix) {
      return;
    }
    _timer = Timer(intervaloConsulta, () {
      if (!isClosed) {
        add(PagamentoConsultarEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  PagamentoModel _ler(AppResponse response) {
    return PagamentoModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  PagamentoState _estadoDe(PagamentoModel pagamento) {
    final EtapaPagamento etapa = switch (pagamento.status) {
      StatusPagamento.aprovado => EtapaPagamento.aprovado,
      StatusPagamento.processando => EtapaPagamento.processando,
      StatusPagamento.pendente =>
        pagamento.pixCopiaCola == null ? EtapaPagamento.expirado : EtapaPagamento.aguardandoPix,
      StatusPagamento.recusado => EtapaPagamento.recusado,
      StatusPagamento.expirado => EtapaPagamento.expirado,
      StatusPagamento.cancelado => EtapaPagamento.cancelado,
      StatusPagamento.reembolsado ||
      StatusPagamento.reembolsoParcial => EtapaPagamento.reembolsado,
      _ => EtapaPagamento.erro,
    };
    return PagamentoState(etapa: etapa, pagamento: pagamento);
  }

  /// Sem resposta da API é erro de conexão; com resposta, mostra a mensagem dela.
  PagamentoState _estadoDeErro(Object e) {
    if (e is ApiException) {
      return state.copiar(
        etapa: EtapaPagamento.erro,
        mensagem: errorModelFromApi(e).mensagem,
      );
    }
    return state.copiar(
      etapa: EtapaPagamento.erroConexao,
      mensagem: 'Sem conexão com o servidor. Verifique sua internet.',
    );
  }
}
