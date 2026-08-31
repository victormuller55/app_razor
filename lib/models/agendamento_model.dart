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
  String? enderecoCompleto;
  double? latitude;
  double? longitude;

  AgendamentoModel({
    this.id,
    this.idBarbearia,
    this.nomeBarbearia,
    this.imagemBarbearia,
    this.idFuncionarioBarbearia,
    this.nomeFuncionario,
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
    this.enderecoCompleto,
    this.latitude,
    this.longitude,
  });

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoModel(
      id: _asInt(json['id']),
      idBarbearia: _asInt(json['id_barbearia']),
      nomeBarbearia: json['nome_barbearia'] as String?,
      imagemBarbearia: resolveMediaUrl(_asNonEmptyString(json['imagem_barbearia'])),
      idFuncionarioBarbearia: _asInt(json['id_funcionario_barbearia']),
      nomeFuncionario: json['nome_funcionario'] as String?,
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
      enderecoCompleto: _asNonEmptyString(json['endereco_completo']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
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

  String get horaLabel {
    return _horaCurta(horaInicio);
  }

  String get horaFimLabel {
    return _horaCurta(horaFim);
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

  bool get podeCancelar {
    return status == 'AGENDADO' || status == 'CONFIRMADO';
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
      servicos: _asMapList(json['servicos'])
          .map(AgendamentoServicoOpcao.fromJson)
          .toList(),
      funcionarios: _asMapList(json['funcionarios'])
          .map(AgendamentoFuncionarioOpcao.fromJson)
          .toList(),
    );
  }
}

class AgendamentoHorarioModel {
  String? horaInicio;
  String? horaFim;

  AgendamentoHorarioModel({
    this.horaInicio,
    this.horaFim,
  });

  factory AgendamentoHorarioModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoHorarioModel(
      horaInicio: _asNonEmptyString(json['hora_inicio']),
      horaFim: _asNonEmptyString(json['hora_fim']),
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
