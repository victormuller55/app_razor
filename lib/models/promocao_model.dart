import 'package:app_razor/functions/media_url.dart';
import 'package:app_razor/models/barbearia_model.dart';

class PromocaoModel {
  int? id;
  String? tipo;
  BarbeariaModel? barbearia;
  String? nome;
  String? descricao;
  double? valorOriginal;
  double? valorPromocional;
  String? validade;
  String? imagem;

  PromocaoModel({
    this.id,
    this.tipo,
    this.barbearia,
    this.nome,
    this.descricao,
    this.valorOriginal,
    this.valorPromocional,
    this.validade,
    this.imagem,
  });

  factory PromocaoModel.fromJson(Map<String, dynamic> json) {
    return PromocaoModel(
      id: _asPromocaoInt(json['id']),
      tipo: json['tipo'] as String?,
      barbearia: json['barbearia'] is Map
          ? BarbeariaModel.fromJson(
              Map<String, dynamic>.from(json['barbearia'] as Map),
            )
          : null,
      nome: _asNonEmptyString(json['nome']) ?? _asNonEmptyString(json['titulo']),
      descricao: json['descricao'] as String?,
      valorOriginal: _asPromocaoDouble(
        json['valor_original'] ?? json['preco_original'],
      ),
      valorPromocional: _asPromocaoDouble(
        json['valor_promocional'] ?? json['preco_promocional'],
      ),
      validade: _asNonEmptyString(json['validade']) ??
          _asNonEmptyString(json['data_fim']),
      imagem: resolveMediaUrl(
        _asNonEmptyString(json['imagem']) ?? _asNonEmptyString(json['logo']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'tipo': tipo,
      'barbearia': barbearia?.toJson(),
      'nome': nome,
      'descricao': descricao,
      'valor_original': valorOriginal,
      'valor_promocional': valorPromocional,
      'validade': validade,
      'imagem': imagem,
    };
  }

  bool get isAnuncio {
    return tipo?.toUpperCase() == 'ANUNCIO';
  }

  String? get badgeTexto {
    if (isAnuncio) {
      return 'Novidade';
    }

    final int percentual = percentualDesconto.round();

    if (percentual <= 0) {
      return null;
    }

    return '$percentual%';
  }

  double get percentualDesconto {
    final double original = valorOriginal ?? 0;
    final double promocional = valorPromocional ?? 0;

    if (original <= 0) {
      return 0;
    }

    return (1 - (promocional / original)) * 100;
  }
}

double? _asPromocaoDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

int? _asPromocaoInt(dynamic value) {
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
