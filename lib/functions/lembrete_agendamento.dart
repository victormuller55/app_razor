import 'dart:async';
import 'dart:convert';

import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Quanto antes do serviço o lembrete aparece na Dynamic Island.
const Duration antecedenciaLembrete = Duration(hours: 1);

/// O agendamento que deve estar no lembrete agora: ainda aguardando o
/// cliente (presença não confirmada), começando em até
/// [antecedenciaLembrete] ou já no horário. Se houver mais de um, o que
/// começa primeiro.
AgendamentoModel? agendamentoParaLembrete(
  List<AgendamentoModel> itens,
  DateTime agora,
) {
  AgendamentoModel? escolhido;

  for (final AgendamentoModel item in itens) {
    final DateTime? inicio = item.dataHora;
    final DateTime? fim = item.dataHoraFim;

    if (!item.aguardando || item.id == null || inicio == null || fim == null) {
      continue;
    }

    final bool naJanela = !agora.isBefore(
      inicio.subtract(antecedenciaLembrete),
    );
    final bool terminou = !agora.isBefore(fim);

    if (naJanela &&
        !terminou &&
        (escolhido == null || inicio.isBefore(escolhido.dataHora!))) {
      escolhido = item;
    }
  }

  return escolhido;
}

/// Lembrete do próximo serviço na Dynamic Island (iOS). Só funciona com o app
/// aberto: confere ao abrir, ao voltar para o app e a cada minuto, e encerra
/// o lembrete quando o agendamento é cancelado ou termina.
class LembreteAgendamento with WidgetsBindingObserver {
  LembreteAgendamento._();

  static final LembreteAgendamento instance = LembreteAgendamento._();

  static const MethodChannel _canal = MethodChannel(
    'razor/lembrete_agendamento',
  );

  List<AgendamentoModel> _itens = <AgendamentoModel>[];
  Timer? _timer;
  int? _idMostrado;
  bool _sincronizado = false;
  bool _iniciado = false;

  bool get _suportado => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void iniciar() {
    if (!_suportado || _iniciado) {
      return;
    }

    _iniciado = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _aplicar());
    unawaited(atualizar());
  }

  /// Ao sair da conta: tira o lembrete e para de conferir.
  void parar() {
    if (!_iniciado) {
      return;
    }

    _itens = <AgendamentoModel>[];
    unawaited(_aplicar());
    _iniciado = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(atualizar());
    }
  }

  /// Busca os agendamentos de novo e ajusta o lembrete.
  Future<void> atualizar() async {
    if (!_suportado) {
      return;
    }

    try {
      final AppResponse response = await getAgendamentos(forceRefresh: true);
      final dynamic json = jsonDecode(response.body);
      final dynamic itens = json is Map ? json['itens'] : null;

      if (itens is List) {
        usarAgendamentos(
          itens
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    AgendamentoModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
      }
    } catch (_) {
      // Sem rede, mantém o que já está na tela.
    }
  }

  /// Usa uma lista já carregada (ex.: a da Agenda) sem ir à API.
  void usarAgendamentos(List<AgendamentoModel> itens) {
    if (!_suportado) {
      return;
    }

    _itens = itens;
    unawaited(_aplicar());
  }

  Future<void> _aplicar() async {
    final AgendamentoModel? agendamento = agendamentoParaLembrete(
      _itens,
      DateTime.now(),
    );

    // Nada mudou desde a última chamada.
    if (_sincronizado && agendamento?.id == _idMostrado) {
      return;
    }

    try {
      await _canal.invokeMethod<bool>('sincronizar', <String, dynamic>{
        'agendamento': agendamento == null
            ? null
            : <String, dynamic>{
                'id': agendamento.id,
                'servico': agendamento.nomeServico,
                'barbearia': agendamento.nomeBarbearia,
                'profissional': agendamento.nomeFuncionario,
                'inicio': agendamento.dataHora!.millisecondsSinceEpoch,
                'fim': agendamento.dataHoraFim!.millisecondsSinceEpoch,
              },
      });
      _idMostrado = agendamento?.id;
      _sincronizado = true;
    } on MissingPluginException {
      // Build sem a extensão: nada a fazer.
    } on PlatformException {
      // Live Activities desligadas pelo usuário.
    }
  }
}
