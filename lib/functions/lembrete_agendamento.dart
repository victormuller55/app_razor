import 'dart:async';
import 'dart:convert';

import 'package:app_razor/app_config/const/app_ambiente.dart' as ambiente;
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Quanto antes do serviço o lembrete aparece na Dynamic Island.
const Duration antecedenciaLembrete = Duration(hours: 1);

/// Confirmado (QR lido) e o barbeiro ainda não iniciou: o lembrete fica até este tempo depois do fim.
const Duration toleranciaConfirmado = Duration(minutes: 30);

/// Depois de concluído, o convite para avaliar fica este tempo.
const Duration permanenciaFinalizado = Duration(minutes: 15);

/// Estados da Live Activity. O `name` é o mesmo valor do `Estado` em Swift e do que a API manda por push.
enum EstadoAtividade { aguardando, confirmado, emAtendimento, finalizado }

/// Em que estado o agendamento aparece no lembrete agora, ou null quando não aparece. A mesma regra está na
/// API (`AtividadeAoVivoService`), que atualiza o lembrete com o app fechado.
EstadoAtividade? estadoDaAtividade(AgendamentoModel item, DateTime agora) {
  final DateTime? inicio = item.dataHora;
  final DateTime? fim = item.dataHoraFim;

  if (item.id == null || inicio == null || fim == null) {
    return null;
  }

  final bool naJanela = !agora.isBefore(inicio.subtract(antecedenciaLembrete));

  switch (item.status) {
    case 'AGENDADO':
      return naJanela && agora.isBefore(fim)
          ? EstadoAtividade.aguardando
          : null;
    case 'CONFIRMADO':
      return naJanela && agora.isBefore(fim.add(toleranciaConfirmado))
          ? EstadoAtividade.confirmado
          : null;
    case 'EM_ATENDIMENTO':
      return EstadoAtividade.emAtendimento;
    case 'CONCLUIDO':
      final DateTime? conclusao = DateTime.tryParse(item.dataConclusao ?? '');
      return conclusao != null &&
              agora.isBefore(conclusao.add(permanenciaFinalizado))
          ? EstadoAtividade.finalizado
          : null;
    default:
      return null;
  }
}

/// O agendamento que deve estar no lembrete agora. Com mais de um: o que está acontecendo (em atendimento,
/// depois confirmado, depois aguardando, por último o convite para avaliar) e, empatando, o que começa primeiro.
AgendamentoModel? agendamentoParaLembrete(
  List<AgendamentoModel> itens,
  DateTime agora,
) {
  const List<EstadoAtividade> prioridade = <EstadoAtividade>[
    EstadoAtividade.emAtendimento,
    EstadoAtividade.confirmado,
    EstadoAtividade.aguardando,
    EstadoAtividade.finalizado,
  ];
  AgendamentoModel? escolhido;
  int? rankEscolhido;

  for (final AgendamentoModel item in itens) {
    final EstadoAtividade? estado = estadoDaAtividade(item, agora);
    if (estado == null) {
      continue;
    }
    final int rank = prioridade.indexOf(estado);
    if (escolhido == null ||
        rank < rankEscolhido! ||
        (rank == rankEscolhido &&
            item.dataHora!.isBefore(escolhido.dataHora!))) {
      escolhido = item;
      rankEscolhido = rank;
    }
  }

  return escolhido;
}

/// O que vai para o iOS: atributos e estado da atividade. Datas em milissegundos.
Map<String, dynamic>? dadosDaAtividade(AgendamentoModel? item, DateTime agora) {
  final EstadoAtividade? estado = item == null
      ? null
      : estadoDaAtividade(item, agora);
  if (item == null || estado == null) {
    return null;
  }
  final DateTime? inicioAtendimento = DateTime.tryParse(
    item.dataInicioAtendimento ?? '',
  );
  return <String, dynamic>{
    'id': item.id,
    'servico': item.nomeServico,
    'barbearia': item.nomeBarbearia,
    'profissional': item.nomeFuncionario,
    'foto': item.fotoFuncionario,
    'chave': item.chaveAtividade,
    'estado': estado.name,
    'inicio': item.dataHora!.millisecondsSinceEpoch,
    'fim': item.dataHoraFim!.millisecondsSinceEpoch,
    'inicio_atendimento': estado == EstadoAtividade.emAtendimento
        ? inicioAtendimento?.millisecondsSinceEpoch
        : null,
  };
}

/// Link tocado na Live Activity: `razor://agendamento/{id}`, `/qrcode` ou `/avaliar`.
class LinkAtividade {
  const LinkAtividade(this.idAgendamento, this.acao);

  final int idAgendamento;
  final AcaoLink acao;

  static LinkAtividade? ler(String? url) {
    final Uri? uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'razor' || uri.host != 'agendamento') {
      return null;
    }
    final List<String> partes = uri.pathSegments
        .where((String p) => p.isNotEmpty)
        .toList();
    final int? id = partes.isEmpty ? null : int.tryParse(partes.first);
    if (id == null) {
      return null;
    }
    final AcaoLink acao = switch (partes.length > 1 ? partes[1] : '') {
      'qrcode' => AcaoLink.qrCode,
      'avaliar' => AcaoLink.avaliar,
      _ => AcaoLink.abrir,
    };
    return LinkAtividade(id, acao);
  }
}

enum AcaoLink { abrir, qrCode, avaliar }

/// Lembrete do agendamento na Dynamic Island e na tela bloqueada (iOS).
///
/// Com o app aberto, confere ao abrir, ao voltar para o app e a cada minuto. Com o app fechado, quem muda o
/// estado é a API, por push (ActivityKit pelo FCM), usando o token da atividade que o iOS entrega ao app
/// (ver `docs/LEMBRETE_DYNAMIC_ISLAND.md`).
class LembreteAgendamento with WidgetsBindingObserver {
  LembreteAgendamento._();

  static final LembreteAgendamento instance = LembreteAgendamento._();

  static const MethodChannel _canal = MethodChannel(
    'razor/lembrete_agendamento',
  );

  final StreamController<LinkAtividade> _links =
      StreamController<LinkAtividade>.broadcast();
  List<AgendamentoModel> _itens = <AgendamentoModel>[];
  Timer? _timer;
  String? _assinatura;
  bool _sincronizado = false;
  bool _iniciado = false;

  bool get _suportado => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Links tocados na atividade com o app aberto.
  Stream<LinkAtividade> get links => _links.stream;

  void iniciar() {
    if (!_suportado || _iniciado) {
      return;
    }

    _iniciado = true;
    _canal.setMethodCallHandler(_doIos);
    unawaited(
      _chamar<void>('configurar', <String, dynamic>{'api': ambiente.server}),
    );
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
    _canal.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  /// Link que abriu o app fechado (entregue uma vez).
  Future<LinkAtividade?> linkPendente() async {
    if (!_suportado) {
      return null;
    }
    return LinkAtividade.ler(await _chamar<String>('linkPendente'));
  }

  /// Token de push-to-start (iOS 17.2+), para a API iniciar o lembrete com o app fechado.
  Future<String?> tokenInicio() async {
    if (!_suportado) {
      return null;
    }
    return _chamar<String>('tokenInicio');
  }

  Future<dynamic> _doIos(MethodCall chamada) async {
    if (chamada.method == 'abrirLink') {
      final LinkAtividade? link = LinkAtividade.ler(
        (chamada.arguments as Map<dynamic, dynamic>?)?['url'] as String?,
      );
      if (link != null) {
        _links.add(link);
      }
    }
    return null;
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

    final List<AgendamentoModel>? itens = await _carregar();
    if (itens != null) {
      usarAgendamentos(itens);
    }
  }

  /// O agendamento de um link, com a situação atual da API (e o lembrete ajustado junto).
  Future<AgendamentoModel?> buscar(int id) async {
    final List<AgendamentoModel>? itens = await _carregar();
    if (itens == null) {
      return null;
    }
    usarAgendamentos(itens);
    for (final AgendamentoModel item in itens) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<List<AgendamentoModel>?> _carregar() async {
    try {
      final AppResponse response = await getAgendamentos(forceRefresh: true);
      final dynamic json = jsonDecode(response.body);
      final dynamic itens = json is Map ? json['itens'] : null;

      if (itens is List) {
        return itens
            .whereType<Map>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  AgendamentoModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    } catch (_) {
      // Sem rede, mantém o que já está na tela.
    }
    return null;
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
    final DateTime agora = DateTime.now();
    final Map<String, dynamic>? dados = dadosDaAtividade(
      agendamentoParaLembrete(_itens, agora),
      agora,
    );
    final String assinatura = jsonEncode(dados);

    // Nada mudou desde a última chamada.
    if (_sincronizado && assinatura == _assinatura) {
      return;
    }

    try {
      await _canal.invokeMethod<bool>('sincronizar', <String, dynamic>{
        'agendamento': dados,
      });
      _assinatura = assinatura;
      _sincronizado = true;
    } on MissingPluginException {
      // Build sem a extensão: nada a fazer.
    } on PlatformException {
      // Live Activities desligadas pelo usuário.
    }
  }

  Future<T?> _chamar<T>(String metodo, [Object? argumentos]) async {
    try {
      return await _canal.invokeMethod<T>(metodo, argumentos);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
