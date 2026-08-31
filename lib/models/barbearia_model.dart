import 'package:app_razor/functions/media_url.dart';

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

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

String? _asNonEmptyString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return null;
}

class BarbeariaModel {
  int? id;
  String? nome;
  String? logo;
  double? nota;
  double? distanciaKm;
  String? bairro;
  String? cidade;
  bool? aberto;
  String? horaAbertura;
  String? horaFechamento;
  int? totalAvaliacoes;
  String? nomeServico;
  double? precoServico;
  double? latitude;
  double? longitude;

  BarbeariaModel({
    this.id,
    this.nome,
    this.logo,
    this.nota,
    this.distanciaKm,
    this.bairro,
    this.cidade,
    this.aberto,
    this.horaAbertura,
    this.horaFechamento,
    this.totalAvaliacoes,
    this.nomeServico,
    this.precoServico,
    this.latitude,
    this.longitude,
  });

  factory BarbeariaModel.fromJson(Map<String, dynamic> json) {
    return BarbeariaModel(
      id: _asInt(json['id']),
      nome: json['nome'] as String?,
      logo: resolveMediaUrl(
        _asNonEmptyString(json['logo']) ?? _asNonEmptyString(json['imagem']),
      ),
      nota: _asDouble(json['nota'] ?? json['nota_media']),
      distanciaKm: _asDouble(json['distancia_km']),
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      aberto: json['aberto'] as bool?,
      horaAbertura: _asNonEmptyString(json['hora_abertura']),
      horaFechamento: _asNonEmptyString(json['hora_fechamento']),
      totalAvaliacoes: _asInt(json['total_avaliacoes']),
      nomeServico: json['nome_servico'] as String?,
      precoServico: _asDouble(json['preco_servico']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'logo': logo,
      'nota': nota,
      'distancia_km': distanciaKm,
      'bairro': bairro,
      'cidade': cidade,
      'aberto': aberto,
      'hora_abertura': horaAbertura,
      'hora_fechamento': horaFechamento,
      'total_avaliacoes': totalAvaliacoes,
      'nome_servico': nomeServico,
      'preco_servico': precoServico,
      'latitude': latitude,
      'longitude': longitude,
    };
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
