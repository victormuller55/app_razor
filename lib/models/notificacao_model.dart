import 'package:app_razor/models/agendamento_model.dart';

/// Aviso do servidor para o cliente. Fica guardado na API até ser lido,
/// então chega mesmo que o app estivesse fechado quando o atendimento terminou.
class NotificacaoModel {
  static const String tipoAtendimentoConcluido = 'ATENDIMENTO_CONCLUIDO';
  static const String tipoCanceladoPelaBarbearia =
      'AGENDAMENTO_CANCELADO_BARBEARIA';

  final int id;
  final String? tipo;
  final String titulo;
  final String? mensagem;

  /// Atendimento a que o aviso se refere: o toque em "Avaliar" abre exatamente este.
  final int? idAgendamento;
  final AgendamentoModel? agendamento;

  const NotificacaoModel({
    required this.id,
    required this.titulo,
    this.tipo,
    this.mensagem,
    this.idAgendamento,
    this.agendamento,
  });

  static NotificacaoModel? fromJson(Map<String, dynamic> json) {
    final dynamic id = json['id'];
    if (id is! num) {
      return null;
    }

    final dynamic agendamento = json['agendamento'];
    final dynamic idAgendamento = json['id_agendamento'];
    return NotificacaoModel(
      id: id.toInt(),
      tipo: json['tipo'] as String?,
      titulo: (json['titulo'] as String?) ?? 'Como foi seu atendimento?',
      mensagem: json['mensagem'] as String?,
      idAgendamento: idAgendamento is num ? idAgendamento.toInt() : null,
      agendamento: agendamento is Map
          ? AgendamentoModel.fromJson(Map<String, dynamic>.from(agendamento))
          : null,
    );
  }

  static List<NotificacaoModel> listaFromJson(dynamic json) {
    if (json is! List) {
      return const <NotificacaoModel>[];
    }

    return json
        .whereType<Map>()
        .map((Map item) => fromJson(Map<String, dynamic>.from(item)))
        .whereType<NotificacaoModel>()
        .toList();
  }

  /// Título curto para mostrar dentro do app. O [titulo] do servidor é o texto do push, longo e com emojis.
  String get tituloNoApp {
    if (atendimentoConcluido) {
      return 'Como foi seu atendimento?';
    }
    if (canceladoPelaBarbearia) {
      return 'A barbearia cancelou seu horário';
    }
    final String? quando = _quando;
    return switch (tipo) {
      'AGENDAMENTO_CONFIRMADO' =>
        quando == null ? 'Agendamento confirmado' : 'Agendamento confirmado para $quando',
      'LEMBRETE_AGENDAMENTO' =>
        quando == null ? 'Seu horário está chegando' : 'Lembrete: seu horário é $quando',
      'NAO_COMPARECIMENTO' => 'Horário registrado como não comparecimento',
      'PAGAMENTO_CONFIRMADO' => 'Pagamento confirmado',
      'PAGAMENTO_RECUSADO' => 'Pagamento recusado',
      'REEMBOLSO_SOLICITADO' => 'Devolução do valor solicitada',
      'REEMBOLSO_CONFIRMADO' => 'Valor devolvido',
      'REEMBOLSO_FALHOU' => 'Não foi possível devolver o valor',
      _ => titulo.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '').trim(),
    };
  }

  /// Uma ou duas linhas abaixo do título nos avisos com tela própria; null nos informativos (só a faixa).
  String? get mensagemNoApp {
    final AgendamentoModel? item = agendamento;
    if (atendimentoConcluido) {
      return 'Conte o que achou do serviço e do profissional.';
    }
    if (!canceladoPelaBarbearia) {
      return null;
    }
    final String? quando = _quando;
    final String? motivo = item?.motivoCancelamento;
    final bool pago = item?.statusPagamento == 'APROVADO' || item?.statusReembolso != null;
    final List<String> linhas = <String>[
      if (quando != null) 'Horário de $quando',
      if (motivo != null && motivo.isNotEmpty) 'Motivo: $motivo',
      if (pago) 'O valor pago será devolvido.',
    ];
    return linhas.isEmpty ? null : linhas.join('\n');
  }

  /// "30/10 às 17:30", quando o aviso traz o agendamento.
  String? get _quando {
    final DateTime? inicio = agendamento?.dataHora;
    if (inicio == null) {
      return null;
    }
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(inicio.day)}/${dois(inicio.month)} às ${dois(inicio.hour)}:${dois(inicio.minute)}';
  }

  bool get atendimentoConcluido => tipo == tipoAtendimentoConcluido;

  bool get canceladoPelaBarbearia => tipo == tipoCanceladoPelaBarbearia;

  /// Aviso só para informar (confirmação, lembrete, pagamento, devolução...): sem tela própria no app.
  bool get informativo => !atendimentoConcluido && !canceladoPelaBarbearia;

  /// O agendamento cancelado, quando dá para marcar outro horário na mesma barbearia.
  AgendamentoModel? get agendamentoParaRemarcar {
    final AgendamentoModel? item = agendamento;
    if (!canceladoPelaBarbearia ||
        item == null ||
        item.id != idAgendamento ||
        item.idBarbearia == null) {
      return null;
    }

    return item;
  }

  /// O agendamento do aviso, se ainda tiver alguma nota por dar.
  AgendamentoModel? get agendamentoParaAvaliar {
    final AgendamentoModel? item = agendamento;
    if (!atendimentoConcluido || item == null || item.id != idAgendamento) {
      return null;
    }

    return item.podeAvaliar ? item : null;
  }
}
