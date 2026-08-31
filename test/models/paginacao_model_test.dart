import 'package:app_razor/models/paginacao_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginacaoModel', () {
    test('fromJson mapeia o envelope de paginação', () {
      final PaginacaoModel paginacao = PaginacaoModel.fromJson(
        <String, dynamic>{
          'itens': <Map<String, dynamic>>[],
          'num_pag': 0,
          'itens_pag': 30,
          'max_pag': 5,
          'max_itens': 142,
        },
      );

      expect(paginacao.numPag, 0);
      expect(paginacao.itensPag, 30);
      expect(paginacao.maxPag, 5);
      expect(paginacao.maxItens, 142);
      expect(paginacao.hasMore, isTrue);
      expect(paginacao.isLastPage, isFalse);
    });

    test('fromJson aceita números em string', () {
      final PaginacaoModel paginacao = PaginacaoModel.fromJson(
        <String, dynamic>{
          'num_pag': '2',
          'itens_pag': '12',
          'max_pag': '3',
          'max_itens': '72',
        },
      );

      expect(paginacao.numPag, 2);
      expect(paginacao.itensPag, 12);
      expect(paginacao.maxPag, 3);
      expect(paginacao.maxItens, 72);
      expect(paginacao.isLastPage, isTrue);
    });

    test('toJson round-trip preserva os campos', () {
      final PaginacaoModel original = PaginacaoModel.fromJson(
        <String, dynamic>{
          'num_pag': 1,
          'itens_pag': 30,
          'max_pag': 4,
          'max_itens': 100,
        },
      );

      final PaginacaoModel copia = PaginacaoModel.fromJson(original.toJson());

      expect(copia.numPag, original.numPag);
      expect(copia.itensPag, original.itensPag);
      expect(copia.maxPag, original.maxPag);
      expect(copia.maxItens, original.maxItens);
    });

    test('empty é última página e não tem mais itens', () {
      final PaginacaoModel paginacao = PaginacaoModel.empty();

      expect(paginacao.numPag, 0);
      expect(paginacao.maxPag, 0);
      expect(paginacao.maxItens, 0);
      expect(paginacao.hasMore, isFalse);
      expect(paginacao.isLastPage, isTrue);
    });

    test('hasMore é falso na última página 0-based', () {
      final PaginacaoModel ultima = PaginacaoModel(
        numPag: 4,
        itensPag: 22,
        maxPag: 5,
        maxItens: 142,
      );

      expect(ultima.hasMore, isFalse);
      expect(ultima.isLastPage, isTrue);
    });
  });
}
