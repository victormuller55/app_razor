int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

class PaginacaoModel {
  int numPag;
  int itensPag;
  int maxPag;
  int maxItens;

  PaginacaoModel({
    required this.numPag,
    required this.itensPag,
    required this.maxPag,
    required this.maxItens,
  });

  factory PaginacaoModel.empty() {
    return PaginacaoModel(
      numPag: 0,
      itensPag: 0,
      maxPag: 0,
      maxItens: 0,
    );
  }

  factory PaginacaoModel.fromJson(Map<String, dynamic> json) {
    return PaginacaoModel(
      numPag: _asInt(json['num_pag']),
      itensPag: _asInt(json['itens_pag']),
      maxPag: _asInt(json['max_pag']),
      maxItens: _asInt(json['max_itens']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'num_pag': numPag,
      'itens_pag': itensPag,
      'max_pag': maxPag,
      'max_itens': maxItens,
    };
  }

  bool get isLastPage {
    if (maxPag <= 0) {
      return true;
    }

    return numPag >= maxPag - 1;
  }

  bool get hasMore {
    return !isLastPage;
  }
}
