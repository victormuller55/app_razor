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

  bool get atendimentoConcluido => tipo == tipoAtendimentoConcluido;

  bool get canceladoPelaBarbearia => tipo == tipoCanceladoPelaBarbearia;

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
