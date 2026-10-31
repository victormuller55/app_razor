String? _asNonEmptyString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    if (value.toLowerCase() == 'true') {
      return true;
    }

    if (value.toLowerCase() == 'false') {
      return false;
    }
  }

  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }

  return null;
}

class BarbeariasFiltrosOpcoes {
  static const double distanciaSliderMin = 1;
  static const double distanciaSliderMax = 50;
  static const double notaSliderMin = 0;
  static const double notaSliderMax = 5;

  static double distanciaSliderDe(double? distanciaMaxima) {
    if (distanciaMaxima == null) {
      return distanciaSliderMax;
    }
    return distanciaMaxima.clamp(distanciaSliderMin, distanciaSliderMax);
  }

  static double? distanciaQueryDe(double slider) {
    return slider.clamp(distanciaSliderMin, distanciaSliderMax);
  }

  static double notaSliderDe(double? notaMinima) {
    if (notaMinima == null) {
      return notaSliderMin;
    }
    return notaMinima.clamp(notaSliderMin, notaSliderMax);
  }

  static double? notaQueryDe(double slider) {
    if (slider <= notaSliderMin) {
      return null;
    }
    return slider;
  }

  static String rotuloDistancia(double slider) {
    return 'Até ${slider.toStringAsFixed(0)} km';
  }

  static String rotuloNota(double slider) {
    final double? nota = notaQueryDe(slider);
    if (nota == null) {
      return 'Qualquer nota';
    }
    final String valor = nota % 1 == 0
        ? nota.toStringAsFixed(0)
        : nota.toStringAsFixed(1).replaceAll('.', ',');
    return 'A partir de $valor';
  }
}

class OrdenacaoBusca {
  static const String relevancia = 'relevancia';
  static const String distancia = 'distancia';
  static const String precoAsc = 'preco_asc';
  static const String precoDesc = 'preco_desc';
  static const String avaliacao = 'avaliacao';
}

class BarbeariasFiltros {
  final String? busca;
  final String? cidade;
  final String? bairro;
  final String? servico;
  final String? profissional;
  final double? precoMin;
  final double? precoMax;
  final bool? aberto;
  final double? notaMinima;
  final double? distanciaMaxima;
  final String? ordenacao;

  const BarbeariasFiltros({
    this.busca,
    this.cidade,
    this.bairro,
    this.servico,
    this.profissional,
    this.precoMin,
    this.precoMax,
    this.aberto,
    this.notaMinima,
    this.distanciaMaxima,
    this.ordenacao,
  });

  factory BarbeariasFiltros.empty() {
    return const BarbeariasFiltros();
  }

  factory BarbeariasFiltros.fromQuery(Map<String, dynamic> query) {
    return BarbeariasFiltros(
      busca: _asNonEmptyString(query['busca']),
      cidade: _asNonEmptyString(query['cidade']),
      bairro: _asNonEmptyString(query['bairro']),
      servico: _asNonEmptyString(query['servico']),
      profissional: _asNonEmptyString(query['profissional']),
      precoMin: _asDouble(query['preco_min']),
      precoMax: _asDouble(query['preco_max']),
      aberto: _asBool(query['aberto']),
      notaMinima: _asDouble(query['nota_minima']),
      distanciaMaxima: _asDouble(query['distancia_maxima']),
      ordenacao: _asNonEmptyString(query['ordenacao']),
    );
  }

  Map<String, dynamic> toQuery() {
    final Map<String, dynamic> query = <String, dynamic>{};

    void texto(String chave, String? valor) {
      final String? atual = _asNonEmptyString(valor);
      if (atual != null) {
        query[chave] = atual;
      }
    }

    texto('busca', busca);
    texto('cidade', cidade);
    texto('bairro', bairro);
    texto('servico', servico);
    texto('profissional', profissional);

    if (precoMin != null) {
      query['preco_min'] = precoMin;
    }
    if (precoMax != null) {
      query['preco_max'] = precoMax;
    }
    if (aberto != null) {
      query['aberto'] = aberto;
    }
    if (notaMinima != null) {
      query['nota_minima'] = notaMinima;
    }
    if (distanciaMaxima != null) {
      query['distancia_maxima'] = distanciaMaxima;
    }
    texto('ordenacao', ordenacao);

    return query;
  }

  bool get hasFiltros {
    return toQuery().isNotEmpty;
  }

  /// Filtros além do texto digitado e da ordenação, para o selo do botão.
  bool get temRefino {
    return _asNonEmptyString(cidade) != null ||
        _asNonEmptyString(bairro) != null ||
        _asNonEmptyString(servico) != null ||
        _asNonEmptyString(profissional) != null ||
        precoMin != null ||
        precoMax != null ||
        aberto != null ||
        notaMinima != null ||
        distanciaMaxima != null;
  }

  BarbeariasFiltros comBusca(String? valor) {
    return BarbeariasFiltros(
      busca: _asNonEmptyString(valor),
      cidade: cidade,
      bairro: bairro,
      servico: servico,
      profissional: profissional,
      precoMin: precoMin,
      precoMax: precoMax,
      aberto: aberto,
      notaMinima: notaMinima,
      distanciaMaxima: distanciaMaxima,
      ordenacao: ordenacao,
    );
  }

  BarbeariasFiltros comOrdenacao(String? valor) {
    return BarbeariasFiltros(
      busca: busca,
      cidade: cidade,
      bairro: bairro,
      servico: servico,
      profissional: profissional,
      precoMin: precoMin,
      precoMax: precoMax,
      aberto: aberto,
      notaMinima: notaMinima,
      distanciaMaxima: distanciaMaxima,
      ordenacao: _asNonEmptyString(valor),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BarbeariasFiltros &&
        other.busca == busca &&
        other.cidade == cidade &&
        other.bairro == bairro &&
        other.servico == servico &&
        other.profissional == profissional &&
        other.precoMin == precoMin &&
        other.precoMax == precoMax &&
        other.aberto == aberto &&
        other.notaMinima == notaMinima &&
        other.distanciaMaxima == distanciaMaxima &&
        other.ordenacao == ordenacao;
  }

  @override
  int get hashCode {
    return Object.hash(
      busca,
      cidade,
      bairro,
      servico,
      profissional,
      precoMin,
      precoMax,
      aberto,
      notaMinima,
      distanciaMaxima,
      ordenacao,
    );
  }
}
