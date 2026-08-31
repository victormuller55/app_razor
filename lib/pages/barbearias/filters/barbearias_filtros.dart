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

class BarbeariasFiltros {
  final String? cidade;
  final String? bairro;
  final bool? aberto;
  final double? notaMinima;
  final double? distanciaMaxima;

  const BarbeariasFiltros({
    this.cidade,
    this.bairro,
    this.aberto,
    this.notaMinima,
    this.distanciaMaxima,
  });

  factory BarbeariasFiltros.empty() {
    return const BarbeariasFiltros();
  }

  factory BarbeariasFiltros.fromQuery(Map<String, dynamic> query) {
    return BarbeariasFiltros(
      cidade: _asNonEmptyString(query['cidade']),
      bairro: _asNonEmptyString(query['bairro']),
      aberto: _asBool(query['aberto']),
      notaMinima: _asDouble(query['nota_minima']),
      distanciaMaxima: _asDouble(query['distancia_maxima']),
    );
  }

  Map<String, dynamic> toQuery() {
    final Map<String, dynamic> query = <String, dynamic>{};

    final String? cidadeAtual = _asNonEmptyString(cidade);
    if (cidadeAtual != null) {
      query['cidade'] = cidadeAtual;
    }

    final String? bairroAtual = _asNonEmptyString(bairro);
    if (bairroAtual != null) {
      query['bairro'] = bairroAtual;
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

    return query;
  }

  bool get hasFiltros {
    return toQuery().isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BarbeariasFiltros &&
        other.cidade == cidade &&
        other.bairro == bairro &&
        other.aberto == aberto &&
        other.notaMinima == notaMinima &&
        other.distanciaMaxima == distanciaMaxima;
  }

  @override
  int get hashCode {
    return Object.hash(cidade, bairro, aberto, notaMinima, distanciaMaxima);
  }
}
