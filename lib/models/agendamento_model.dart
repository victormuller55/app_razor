import 'package:app_razor/functions/media_url.dart';

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

String? _asNonEmptyString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return null;
}

List<int> _asIntList(dynamic value) {
  if (value is! List) {
    return const <int>[];
  }

  return value.map(_asInt).whereType<int>().toList();
}

String _horaCurta(String? hora) {
  if (hora == null || hora.length < 5) {
    return '';
  }

  return hora.substring(0, 5);
}

class AgendamentoModel {
  int? id;
  int? idBarbearia;
  String? nomeBarbearia;
  String? imagemBarbearia;
  int? idFuncionarioBarbearia;
  String? nomeFuncionario;

  /// Foto do profissional (URL completa), para o lembrete na Dynamic Island.
  String? fotoFuncionario;
  int? idBarbeariaServico;
  String? nomeServico;
  String? imagemServico;
  String? dataAgendamento;
  String? horaInicio;
  String? horaFim;
  String? status;
  double? preco;
  int? duracaoMinutos;
  String? observacao;
  String? tokenConfirmacao;
  String? enderecoCompleto;
  double? latitude;
  double? longitude;

  /// Último pagamento pelo app (`APROVADO`, `PENDENTE`...), ou null quando não houve.
  String? statusPagamento;

  /// A barbearia recebe pagamento pelo app.
  bool pagamentoOnline;

  /// Ordem de serviço quando foi marcado junto com outros serviços.
  String? idOrdemServico;

  /// Nota (1 a 5) que o cliente deu à barbearia neste serviço; null enquanto não avaliou.
  int? notaAvaliacao;

  /// Nota (1 a 5) do serviço e do profissional; null enquanto não avaliou.
  int? notaAvaliacaoAtendimento;

  /// Diferença a pagar da reserva paga que ficou mais cara numa edição.
  double? valorAPagar;

  /// Situação do reembolso do que foi pago (`PROCESSANDO`, `CONFIRMADO`,
  /// `FALHOU`), ou null quando nada foi pedido. Só `CONFIRMADO` é dinheiro
  /// devolvido.
  String? statusReembolso;

  /// Reembolsado com confirmação do Mercado Pago.
  double? valorReembolsado;

  /// Reembolso pedido e ainda não confirmado pelo Mercado Pago.
  double? valorReembolsoPendente;

  /// Quem cancelou (`CLIENTE` ou `BARBEARIA`); null se não foi cancelado ou é antigo.
  String? canceladoPor;

  /// Data e hora do cancelamento (`2026-10-28T13:40:00`).
  String? dataCancelamento;

  String? motivoCancelamento;

  /// O cliente cancelou depois do prazo (1 hora antes, por padrão). Sem multa.
  bool cancelamentoTardio;

  /// Quando o horário foi registrado como não comparecimento.
  String? dataNoShow;

  /// Quando o barbeiro iniciou o atendimento (`2026-10-28T14:02:00`).
  String? dataInicioAtendimento;

  /// Quando o atendimento foi concluído.
  String? dataConclusao;

  /// Chave assinada pela API para a Live Activity deste horário receber atualizações por push.
  String? chaveAtividade;

  AgendamentoModel({
    this.id,
    this.idBarbearia,
    this.nomeBarbearia,
    this.imagemBarbearia,
    this.idFuncionarioBarbearia,
    this.nomeFuncionario,
    this.fotoFuncionario,
    this.idBarbeariaServico,
    this.nomeServico,
    this.imagemServico,
    this.dataAgendamento,
    this.horaInicio,
    this.horaFim,
    this.status,
    this.preco,
    this.duracaoMinutos,
    this.observacao,
    this.tokenConfirmacao,
    this.enderecoCompleto,
    this.latitude,
    this.longitude,
    this.statusPagamento,
    this.pagamentoOnline = false,
    this.idOrdemServico,
    this.notaAvaliacao,
    this.notaAvaliacaoAtendimento,
    this.valorAPagar,
    this.statusReembolso,
    this.valorReembolsado,
    this.valorReembolsoPendente,
    this.canceladoPor,
    this.dataCancelamento,
    this.motivoCancelamento,
    this.cancelamentoTardio = false,
    this.dataNoShow,
    this.dataInicioAtendimento,
    this.dataConclusao,
    this.chaveAtividade,
  });

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoModel(
      id: _asInt(json['id']),
      idBarbearia: _asInt(json['id_barbearia']),
      nomeBarbearia: json['nome_barbearia'] as String?,
      imagemBarbearia: resolveMediaUrl(
        _asNonEmptyString(json['imagem_barbearia']),
      ),
      idFuncionarioBarbearia: _asInt(json['id_funcionario_barbearia']),
      nomeFuncionario: json['nome_funcionario'] as String?,
      fotoFuncionario: resolveMediaUrl(
        _asNonEmptyString(json['foto_funcionario']),
      ),
      idBarbeariaServico: _asInt(json['id_barbearia_servico']),
      nomeServico: json['nome_servico'] as String?,
      imagemServico: resolveMediaUrl(_asNonEmptyString(json['imagem_servico'])),
      dataAgendamento: _asNonEmptyString(json['data_agendamento']),
      horaInicio: _asNonEmptyString(json['hora_inicio']),
      horaFim: _asNonEmptyString(json['hora_fim']),
      status: json['status'] as String?,
      preco: _asDouble(json['preco']),
      duracaoMinutos: _asInt(json['duracao_minutos']),
      observacao: _asNonEmptyString(json['observacao']),
      tokenConfirmacao: _asNonEmptyString(json['token_confirmacao']),
      enderecoCompleto: _asNonEmptyString(json['endereco_completo']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      statusPagamento: _asNonEmptyString(json['status_pagamento']),
      pagamentoOnline: json['pagamento_online'] == true,
      idOrdemServico: json['id_ordem_servico'] == null
          ? null
          : '${json['id_ordem_servico']}',
      notaAvaliacao: _asInt(json['nota_avaliacao']),
      notaAvaliacaoAtendimento: _asInt(json['nota_avaliacao_atendimento']),
      valorAPagar: _asDouble(json['valor_a_pagar']),
      statusReembolso: _asNonEmptyString(json['status_reembolso']),
      valorReembolsado: _asDouble(json['valor_reembolsado']),
      valorReembolsoPendente: _asDouble(json['valor_reembolso_pendente']),
      canceladoPor: _asNonEmptyString(json['cancelado_por']),
      dataCancelamento: _asNonEmptyString(json['data_cancelamento']),
      motivoCancelamento: _asNonEmptyString(json['motivo_cancelamento']),
      cancelamentoTardio: json['cancelamento_tardio'] == true,
      dataNoShow: _asNonEmptyString(json['data_no_show']),
      dataInicioAtendimento: _asNonEmptyString(json['data_inicio_atendimento']),
      dataConclusao: _asNonEmptyString(json['data_conclusao']),
      chaveAtividade: _asNonEmptyString(json['chave_atividade']),
    );
  }

  String get dataLabel {
    final String? iso = dataAgendamento;

    if (iso == null || iso.length < 10) {
      return '';
    }

    final List<String> partes = iso.substring(0, 10).split('-');

    if (partes.length != 3) {
      return iso;
    }

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  /// "Ontem", "Hoje" ou "Amanhã" em relação a [agora]; nos outros dias, a data.
  String dataRelativaLabel(DateTime agora) {
    final DateTime? dia = DateTime.tryParse(
      (dataAgendamento ?? '').length >= 10
          ? dataAgendamento!.substring(0, 10)
          : '',
    );

    if (dia == null) {
      return dataLabel;
    }

    // Em dias de calendário: Duration.inDays erraria na troca de horário de verão.
    final int diferenca = DateTime.utc(
      dia.year,
      dia.month,
      dia.day,
    ).difference(DateTime.utc(agora.year, agora.month, agora.day)).inDays;

    return switch (diferenca) {
      -1 => 'Ontem',
      0 => 'Hoje',
      1 => 'Amanhã',
      _ => dataLabel,
    };
  }

  String get horaLabel {
    return _horaCurta(horaInicio);
  }

  String get horaFimLabel {
    return _horaCurta(horaFim);
  }

  DateTime? get dataHora {
    final String? data = dataAgendamento;

    if (data == null || data.length < 10) {
      return null;
    }

    final String dia = data.substring(0, 10);
    final String hora = horaInicio != null && horaInicio!.length >= 5
        ? horaInicio!.substring(0, 5)
        : '00:00';

    return DateTime.tryParse('${dia}T$hora:00');
  }

  /// Fim do serviço; sem hora de fim, usa a duração a partir do início.
  DateTime? get dataHoraFim {
    final DateTime? inicio = dataHora;
    final String? data = dataAgendamento;

    if (inicio == null || data == null) {
      return null;
    }

    if (horaFim != null && horaFim!.length >= 5) {
      final DateTime? fim = DateTime.tryParse(
        '${data.substring(0, 10)}T${horaFim!.substring(0, 5)}:00',
      );
      if (fim != null && fim.isAfter(inicio)) {
        return fim;
      }
    }

    return inicio.add(Duration(minutes: duracaoMinutos ?? 0));
  }

  String get periodoLabel {
    if (dataLabel.isEmpty) {
      return horarioFaixa;
    }

    if (horarioFaixa.isEmpty) {
      return dataLabel;
    }

    return '$dataLabel · $horarioFaixa';
  }

  String get horarioFaixa {
    if (horaLabel.isEmpty) {
      return horaFimLabel;
    }

    if (horaFimLabel.isEmpty) {
      return horaLabel;
    }

    return '$horaLabel – $horaFimLabel';
  }

  String? get duracaoLabel {
    final int? minutos = duracaoMinutos;

    if (minutos == null || minutos <= 0) {
      return null;
    }

    if (minutos < 60) {
      return '$minutos min';
    }

    final int horas = minutos ~/ 60;
    final int resto = minutos % 60;

    if (resto == 0) {
      return horas == 1 ? '1 h' : '$horas h';
    }

    return '${horas}h ${resto}min';
  }

  String? get foto {
    if (imagemServico != null && imagemServico!.isNotEmpty) {
      return imagemServico;
    }

    if (imagemBarbearia != null && imagemBarbearia!.isNotEmpty) {
      return imagemBarbearia;
    }

    return null;
  }

  bool get temRota {
    if (latitude != null && longitude != null) {
      return true;
    }

    if (enderecoCompleto != null && enderecoCompleto!.isNotEmpty) {
      return true;
    }

    return nomeBarbearia != null && nomeBarbearia!.isNotEmpty;
  }

  bool get cancelado {
    return status == 'CANCELADO';
  }

  bool get concluido {
    return status == 'CONCLUIDO';
  }

  bool get pendente {
    return !concluido && !cancelado && status != 'NO_SHOW';
  }

  /// Cancelado, concluído ou sem comparecimento: aparece esmaecido na agenda.
  bool get encerrado {
    return !pendente;
  }

  /// Presença confirmada pelo barbeiro (leitura do QR): o serviço já começou.
  bool get confirmado {
    return status == 'CONFIRMADO';
  }

  /// Ainda à espera do cliente: só aqui valem QR, "Como chegar" e cancelar.
  bool get aguardando {
    return status == 'AGENDADO';
  }

  bool get podeCancelar {
    return aguardando;
  }

  bool get canceladoPelaBarbearia {
    return cancelado && canceladoPor == 'BARBEARIA';
  }

  /// Quem cancelou, para o cliente; null quando não foi cancelado.
  String? get cancelamentoLabel {
    if (!cancelado) {
      return null;
    }

    return switch (canceladoPor) {
      'BARBEARIA' => 'Cancelado pela barbearia',
      'CLIENTE' when cancelamentoTardio => 'Você cancelou fora do prazo',
      'CLIENTE' => 'Você cancelou',
      _ => null,
    };
  }

  /// Ainda agendado e por vir: dá para trocar serviços, profissional e horário.
  bool podeEditarEm(DateTime agora) {
    final DateTime? inicio = dataHora;
    return aguardando && inicio != null && inicio.isAfter(agora);
  }

  /// O barbeiro iniciou o atendimento: o cliente está na cadeira.
  bool get emAtendimento {
    return status == 'EM_ATENDIMENTO';
  }

  /// Serviço concluído com alguma das duas notas (atendimento ou barbearia) por dar: mostra "Avaliar".
  bool get podeAvaliar {
    return concluido &&
        (notaAvaliacao == null || notaAvaliacaoAtendimento == null);
  }

  /// Pago pelo app, confirmado pela API. Cancelado não aparece como pago: o
  /// que vale para ele é a situação do reembolso.
  bool get pago {
    return statusPagamento == 'APROVADO' && !cancelado;
  }

  /// Reembolso pedido e ainda não confirmado: o dinheiro não voltou ainda.
  bool get reembolsoEmProcessamento {
    return statusReembolso == 'PROCESSANDO' || statusReembolso == 'SOLICITADO';
  }

  /// Selo do reembolso; null quando nada foi pedido.
  String? get reembolsoLabel {
    return switch (statusReembolso) {
      'PROCESSANDO' || 'SOLICITADO' => 'Reembolso em processamento',
      'CONFIRMADO' => 'Reembolsado',
      // Recusado pelo Mercado Pago: o valor continua a ser devolvido, a plataforma tenta de novo.
      'FALHOU' => 'Reembolso em nova tentativa',
      _ => null,
    };
  }

  /// Mostra "Pagar com Pix": aguardando, barbearia recebe e não há pagamento feito ou em análise.
  bool get podePagarPeloApp {
    return aguardando &&
        pagamentoOnline &&
        statusPagamento != 'APROVADO' &&
        statusPagamento != 'PROCESSANDO' &&
        statusPagamento != 'CONTESTADO' &&
        statusPagamento != 'REEMBOLSO_PARCIAL';
  }

  /// Texto do QR que o cliente mostra para o barbeiro confirmar presença e serviço.
  String? get codigoQr {
    final String? token = tokenConfirmacao?.trim();

    if (token == null || token.isEmpty || status != 'AGENDADO') {
      return null;
    }

    return 'razor-confirmacao:$token';
  }

  String get statusLabel {
    return switch (status) {
      'AGENDADO' => 'Agendado',
      'CONFIRMADO' => 'Confirmado',
      'EM_ATENDIMENTO' => 'Em atendimento',
      'CONCLUIDO' => 'Concluído',
      'CANCELADO' => 'Cancelado',
      'NO_SHOW' => 'Não compareceu',
      _ => status ?? '',
    };
  }
}

/// Grupos da agenda, na ordem em que aparecem na tela.
enum GrupoAgendamento {
  proximos('Próximos'),
  hoje('Hoje'),
  ontem('Ontem'),
  essaSemana('Essa semana'),
  maisAntigos('Mais antigos'),
  cancelados('Cancelados');

  const GrupoAgendamento(this.titulo);

  final String titulo;
}

/// Grupo pelo dia do agendamento em relação a [agora]: depois de hoje é
/// "Próximos"; de 2 a 6 dias atrás, "Essa semana"; sem data, "Mais antigos".
/// Os cancelados vão todos para "Cancelados", no fim da lista.
GrupoAgendamento grupoDoAgendamento(
  AgendamentoModel agendamento,
  DateTime agora,
) {
  if (agendamento.cancelado) {
    return GrupoAgendamento.cancelados;
  }

  final DateTime? dataHora = agendamento.dataHora;

  if (dataHora == null) {
    return GrupoAgendamento.maisAntigos;
  }

  final DateTime hoje = DateTime(agora.year, agora.month, agora.day);
  final DateTime dia = DateTime(dataHora.year, dataHora.month, dataHora.day);
  // Em dias de calendário: Duration.inDays erraria na troca de horário de verão.
  final int diasAtras = DateTime.utc(
    hoje.year,
    hoje.month,
    hoje.day,
  ).difference(DateTime.utc(dia.year, dia.month, dia.day)).inDays;

  if (diasAtras < 0) {
    return GrupoAgendamento.proximos;
  }

  return switch (diasAtras) {
    0 => GrupoAgendamento.hoje,
    1 => GrupoAgendamento.ontem,
    < 7 => GrupoAgendamento.essaSemana,
    _ => GrupoAgendamento.maisAntigos,
  };
}

/// Separa a lista (já ordenada, mais recente primeiro) nos grupos da agenda,
/// só com os grupos que têm agendamentos. Em cada grupo os pendentes vêm
/// primeiro; fora isso a ordem dos itens é mantida.
List<({GrupoAgendamento grupo, List<AgendamentoModel> itens})>
agrupaAgendamentos(List<AgendamentoModel> itens, DateTime agora) {
  final Map<GrupoAgendamento, List<AgendamentoModel>> porGrupo =
      <GrupoAgendamento, List<AgendamentoModel>>{};

  for (final AgendamentoModel item in <AgendamentoModel>[
    ...itens.where((AgendamentoModel item) => item.pendente),
    ...itens.where((AgendamentoModel item) => !item.pendente),
  ]) {
    porGrupo
        .putIfAbsent(
          grupoDoAgendamento(item, agora),
          () => <AgendamentoModel>[],
        )
        .add(item);
  }

  return <({GrupoAgendamento grupo, List<AgendamentoModel> itens})>[
    for (final GrupoAgendamento grupo in GrupoAgendamento.values)
      if (porGrupo[grupo] != null) (grupo: grupo, itens: porGrupo[grupo]!),
  ];
}

List<AgendamentoModel> ordenaAgendamentosMaisAtual(
  List<AgendamentoModel> itens,
) {
  final List<AgendamentoModel> ordenados = List<AgendamentoModel>.from(itens);
  ordenados.sort((AgendamentoModel a, AgendamentoModel b) {
    final DateTime? dataA = a.dataHora;
    final DateTime? dataB = b.dataHora;

    if (dataA == null && dataB == null) {
      return (b.id ?? 0).compareTo(a.id ?? 0);
    }

    if (dataA == null) {
      return 1;
    }

    if (dataB == null) {
      return -1;
    }

    final int porData = dataB.compareTo(dataA);

    if (porData != 0) {
      return porData;
    }

    return (b.id ?? 0).compareTo(a.id ?? 0);
  });

  return ordenados;
}

class AgendamentoServicoOpcao {
  int? id;
  String? nome;
  String? descricao;
  String? imagem;
  double? preco;
  int? duracaoMinutos;

  AgendamentoServicoOpcao({
    this.id,
    this.nome,
    this.descricao,
    this.imagem,
    this.preco,
    this.duracaoMinutos,
  });

  factory AgendamentoServicoOpcao.fromJson(Map<String, dynamic> json) {
    return AgendamentoServicoOpcao(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      descricao: json['descricao'] as String?,
      imagem: resolveMediaUrl(
        _asNonEmptyString(json['imagem']) ?? _asNonEmptyString(json['foto']),
      ),
      preco: _asDouble(json['preco']),
      duracaoMinutos: _asInt(json['duracao_minutos']),
    );
  }

  String? get duracaoLabel {
    final int? minutos = duracaoMinutos;

    if (minutos == null || minutos <= 0) {
      return null;
    }

    if (minutos < 60) {
      return '$minutos min';
    }

    final int horas = minutos ~/ 60;
    final int resto = minutos % 60;

    if (resto == 0) {
      return horas == 1 ? '1 h' : '$horas h';
    }

    return '${horas}h ${resto}min';
  }
}

class AgendamentoFuncionarioOpcao {
  int? id;
  String? nome;
  String? cargo;
  String? foto;
  List<int> idsServicos;

  AgendamentoFuncionarioOpcao({
    this.id,
    this.nome,
    this.cargo,
    this.foto,
    this.idsServicos = const <int>[],
  });

  factory AgendamentoFuncionarioOpcao.fromJson(Map<String, dynamic> json) {
    return AgendamentoFuncionarioOpcao(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      cargo: json['cargo'] as String?,
      foto: resolveMediaUrl(
        _asNonEmptyString(json['foto']) ??
            _asNonEmptyString(json['imagem']) ??
            _asNonEmptyString(json['logo']),
      ),
      idsServicos: _asIntList(json['ids_servicos']),
    );
  }

  bool realizaServico(int? idServico) {
    if (idServico == null) {
      return true;
    }

    return idsServicos.contains(idServico);
  }
}

class AgendamentoContextoModel {
  int? idBarbearia;
  String? nomeBarbearia;
  List<AgendamentoServicoOpcao> servicos;
  List<AgendamentoFuncionarioOpcao> funcionarios;

  AgendamentoContextoModel({
    this.idBarbearia,
    this.nomeBarbearia,
    this.servicos = const <AgendamentoServicoOpcao>[],
    this.funcionarios = const <AgendamentoFuncionarioOpcao>[],
  });

  factory AgendamentoContextoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoContextoModel(
      idBarbearia: _asInt(json['id_barbearia']),
      nomeBarbearia: json['nome_barbearia'] as String?,
      servicos: _asMapList(
        json['servicos'],
      ).map(AgendamentoServicoOpcao.fromJson).toList(),
      funcionarios: _asMapList(
        json['funcionarios'],
      ).map(AgendamentoFuncionarioOpcao.fromJson).toList(),
    );
  }
}

class AgendamentoHorarioModel {
  String? horaInicio;
  String? horaFim;

  /// Falso quando o profissional não atende, o horário já passou ou está ocupado.
  bool disponivel;

  AgendamentoHorarioModel({
    this.horaInicio,
    this.horaFim,
    this.disponivel = true,
  });

  factory AgendamentoHorarioModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoHorarioModel(
      horaInicio: _asNonEmptyString(json['hora_inicio']),
      horaFim: _asNonEmptyString(json['hora_fim']),
      // A API antiga só mandava os livres, sem o campo.
      disponivel: json['disponivel'] != false,
    );
  }

  String get label {
    final String? hora = horaInicio;

    if (hora == null || hora.length < 5) {
      return '';
    }

    return hora.substring(0, 5);
  }
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList();
}
