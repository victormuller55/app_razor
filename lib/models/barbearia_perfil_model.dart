import 'package:app_razor/functions/media_url.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/promocao_model.dart';

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
    return value;
  }

  return null;
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

class BarbeariaHorarioModel {
  String? diaSemana;
  String? horaAbertura;
  String? horaFechamento;
  bool? fechado;

  BarbeariaHorarioModel({
    this.diaSemana,
    this.horaAbertura,
    this.horaFechamento,
    this.fechado,
  });

  factory BarbeariaHorarioModel.fromJson(Map<String, dynamic> json) {
    return BarbeariaHorarioModel(
      diaSemana: json['dia_semana'] as String?,
      horaAbertura: _asNonEmptyString(json['hora_abertura']),
      horaFechamento: _asNonEmptyString(json['hora_fechamento']),
      fechado: json['fechado'] as bool?,
    );
  }

  String get diaLabel {
    return switch (diaSemana) {
      'SEGUNDA' => 'Segunda',
      'TERCA' => 'Terça',
      'QUARTA' => 'Quarta',
      'QUINTA' => 'Quinta',
      'SEXTA' => 'Sexta',
      'SABADO' => 'Sábado',
      'DOMINGO' => 'Domingo',
      _ => diaSemana ?? '',
    };
  }

  String get horarioLabel {
    if (fechado == true) {
      return 'Fechado';
    }

    final String? abertura = _formatHora(horaAbertura);
    final String? fechamento = _formatHora(horaFechamento);

    if (abertura == null || fechamento == null) {
      return 'Fechado';
    }

    return '$abertura – $fechamento';
  }
}

class BarbeariaServicoModel {
  int? id;
  String? nome;
  String? descricao;
  String? imagem;
  double? preco;
  int? duracaoMinutos;

  BarbeariaServicoModel({
    this.id,
    this.nome,
    this.descricao,
    this.imagem,
    this.preco,
    this.duracaoMinutos,
  });

  factory BarbeariaServicoModel.fromJson(Map<String, dynamic> json) {
    return BarbeariaServicoModel(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      descricao: json['descricao'] as String?,
      imagem: resolveMediaUrl(
        _asNonEmptyString(json['imagem']) ??
            _asNonEmptyString(json['foto']) ??
            _asNonEmptyString(json['logo']),
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

class BarbeariaFuncionarioModel {
  int? id;
  String? nome;
  String? cargo;
  String? foto;
  List<String> servicos;

  BarbeariaFuncionarioModel({
    this.id,
    this.nome,
    this.cargo,
    this.foto,
    this.servicos = const <String>[],
  });

  factory BarbeariaFuncionarioModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['servicos'] is List
        ? json['servicos'] as List<dynamic>
        : const <dynamic>[];

    return BarbeariaFuncionarioModel(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      cargo: json['cargo'] as String?,
      foto: resolveMediaUrl(
        _asNonEmptyString(json['foto']) ??
            _asNonEmptyString(json['imagem']) ??
            _asNonEmptyString(json['logo']),
      ),
      servicos: raw
          .whereType<String>()
          .where((String item) => item.trim().isNotEmpty)
          .toList(),
    );
  }
}

class BarbeariaAvaliacaoModel {
  int? id;
  int? nota;
  String? comentario;
  String? nomeCliente;
  String? dataCriacao;

  BarbeariaAvaliacaoModel({
    this.id,
    this.nota,
    this.comentario,
    this.nomeCliente,
    this.dataCriacao,
  });

  factory BarbeariaAvaliacaoModel.fromJson(Map<String, dynamic> json) {
    return BarbeariaAvaliacaoModel(
      id: _asInt(json['id']),
      nota: _asInt(json['nota']),
      comentario: json['comentario'] as String?,
      nomeCliente: json['nome_cliente'] as String?,
      dataCriacao: _asNonEmptyString(json['data_criacao']),
    );
  }

  String? get dataLabel {
    final String? iso = dataCriacao;

    if (iso == null) {
      return null;
    }

    try {
      final DateTime data = DateTime.parse(iso);
      final String dia = data.day.toString().padLeft(2, '0');
      final String mes = data.month.toString().padLeft(2, '0');
      return '$dia/$mes/${data.year}';
    } catch (_) {
      return iso;
    }
  }
}

class BarbeariaPerfilModel {
  int? id;
  String? nome;
  String? descricao;
  String? logo;
  String? telefone;
  String? endereco;
  String? numero;
  String? complemento;
  String? bairro;
  String? cidade;
  String? estado;
  String? cep;
  String? enderecoCompleto;
  double? latitude;
  double? longitude;
  double? nota;
  int? totalAvaliacoes;
  double? distanciaKm;
  bool? aberto;
  String? horaAbertura;
  String? horaFechamento;
  bool? favorito;
  List<BarbeariaHorarioModel> horarios;
  List<BarbeariaServicoModel> servicos;
  List<BarbeariaFuncionarioModel> funcionarios;
  List<PromocaoModel> promocoes;
  List<BarbeariaAvaliacaoModel> avaliacoes;

  BarbeariaPerfilModel({
    this.id,
    this.nome,
    this.descricao,
    this.logo,
    this.telefone,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.enderecoCompleto,
    this.latitude,
    this.longitude,
    this.nota,
    this.totalAvaliacoes,
    this.distanciaKm,
    this.aberto,
    this.horaAbertura,
    this.horaFechamento,
    this.favorito,
    this.horarios = const <BarbeariaHorarioModel>[],
    this.servicos = const <BarbeariaServicoModel>[],
    this.funcionarios = const <BarbeariaFuncionarioModel>[],
    this.promocoes = const <PromocaoModel>[],
    this.avaliacoes = const <BarbeariaAvaliacaoModel>[],
  });

  factory BarbeariaPerfilModel.fromJson(Map<String, dynamic> json) {
    return BarbeariaPerfilModel(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      descricao: json['descricao'] as String?,
      logo: resolveMediaUrl(
        _asNonEmptyString(json['logo']) ?? _asNonEmptyString(json['imagem']),
      ),
      telefone: _asNonEmptyString(json['telefone']),
      endereco: json['endereco'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      cep: json['cep'] as String?,
      enderecoCompleto: _asNonEmptyString(json['endereco_completo']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      nota: _asDouble(json['nota'] ?? json['nota_media']),
      totalAvaliacoes: _asInt(json['total_avaliacoes']),
      distanciaKm: _asDouble(json['distancia_km']),
      aberto: json['aberto'] as bool?,
      horaAbertura: _asNonEmptyString(json['hora_abertura']),
      horaFechamento: _asNonEmptyString(json['hora_fechamento']),
      favorito: json['favorito'] as bool?,
      horarios: _asMapList(json['horarios'])
          .map(BarbeariaHorarioModel.fromJson)
          .toList(),
      servicos: _asMapList(json['servicos'])
          .map(BarbeariaServicoModel.fromJson)
          .toList(),
      funcionarios: _asMapList(json['funcionarios'])
          .map(BarbeariaFuncionarioModel.fromJson)
          .toList(),
      promocoes: _asMapList(json['promocoes']).map((Map<String, dynamic> item) {
        final PromocaoModel promocao = PromocaoModel.fromJson(item);
        promocao.barbearia ??= BarbeariaModel(
          id: _asInt(json['id']),
          nome: json['nome'] as String?,
        );
        return promocao;
      }).toList(),
      avaliacoes: _asMapList(json['avaliacoes'])
          .map(BarbeariaAvaliacaoModel.fromJson)
          .toList(),
    );
  }

  String get localDescricao {
    final String bairroAtual = bairro ?? '';
    final String cidadeAtual = cidade ?? '';

    if (bairroAtual.isEmpty) {
      return cidadeAtual;
    }

    if (cidadeAtual.isEmpty) {
      return bairroAtual;
    }

    return '$bairroAtual, $cidadeAtual';
  }

  String? get horarioHoje {
    final String? abertura = _formatHora(horaAbertura);
    final String? fechamento = _formatHora(horaFechamento);

    if (abertura == null || fechamento == null) {
      return null;
    }

    return '$abertura – $fechamento';
  }

  BarbeariaModel get asResumo {
    return BarbeariaModel(
      id: id,
      nome: nome,
      logo: logo,
      nota: nota,
      distanciaKm: distanciaKm,
      bairro: bairro,
      cidade: cidade,
      aberto: aberto,
      horaAbertura: horaAbertura,
      horaFechamento: horaFechamento,
      totalAvaliacoes: totalAvaliacoes,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

String? _formatHora(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final String trimmed = value.trim();

  if (trimmed.length >= 5) {
    return trimmed.substring(0, 5);
  }

  return trimmed;
}
