import 'package:app_razor/models/promocao_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromocaoModel', () {
    test('fromJson mapeia oferta e barbearia', () {
      final PromocaoModel promocao = PromocaoModel.fromJson(<String, dynamic>{
        'nome': 'Combo corte e barba',
        'descricao': 'Corte clássico, barba e finalização.',
        'valor_original': 80,
        'valor_promocional': 56,
        'validade': '2026-09-30',
        'barbearia': <String, dynamic>{
          'id': 1,
          'nome': 'Navalha do Batel',
        },
      });

      expect(promocao.nome, 'Combo corte e barba');
      expect(promocao.descricao, 'Corte clássico, barba e finalização.');
      expect(promocao.valorOriginal, 80);
      expect(promocao.valorPromocional, 56);
      expect(promocao.validade, '2026-09-30');
      expect(promocao.barbearia?.nome, 'Navalha do Batel');
    });

    test('fromJson mapeia contrato da API (titulo, precos, data_fim)', () {
      final PromocaoModel promocao = PromocaoModel.fromJson(<String, dynamic>{
        'id': 1,
        'tipo': 'PROMOCAO',
        'titulo': 'Corte em dobro',
        'descricao': 'Corte clássico e barba.',
        'imagem': '/uploads/promocoes/promo.jpg',
        'preco_original': 80.00,
        'preco_promocional': 40.00,
        'percentual_desconto': 50.00,
        'data_inicio': '2026-08-01',
        'data_fim': '2026-08-31',
        'distancia_km': 0.85,
        'barbearia': <String, dynamic>{
          'id': 1,
          'nome': 'Razor Centro',
          'imagem': '/uploads/barbearias/abc.jpg',
          'bairro': 'Centro',
          'cidade': 'São Paulo',
          'latitude': -23.5505,
          'longitude': -46.6333,
        },
      });

      expect(promocao.id, 1);
      expect(promocao.tipo, 'PROMOCAO');
      expect(promocao.nome, 'Corte em dobro');
      expect(promocao.valorOriginal, 80);
      expect(promocao.valorPromocional, 40);
      expect(promocao.validade, '2026-08-31');
      expect(promocao.imagem, 'http://10.0.2.2:5000/uploads/promocoes/promo.jpg');
      expect(promocao.percentualDesconto, closeTo(50, 0.01));
      expect(promocao.badgeTexto, '50%');
      expect(promocao.barbearia?.nome, 'Razor Centro');
      expect(
        promocao.barbearia?.logo,
        'http://10.0.2.2:5000/uploads/barbearias/abc.jpg',
      );
    });

    test('ANUNCIO sem preços mostra Novidade e não 0%', () {
      final PromocaoModel promocao = PromocaoModel.fromJson(<String, dynamic>{
        'id': 2,
        'tipo': 'ANUNCIO',
        'titulo': 'Nova unidade',
        'descricao': 'Inauguração no Centro.',
        'preco_original': null,
        'preco_promocional': null,
        'percentual_desconto': null,
        'data_fim': '2026-09-30',
        'barbearia': <String, dynamic>{
          'id': 1,
          'nome': 'Razor Centro',
        },
      });

      expect(promocao.isAnuncio, isTrue);
      expect(promocao.valorOriginal, isNull);
      expect(promocao.valorPromocional, isNull);
      expect(promocao.percentualDesconto, 0);
      expect(promocao.badgeTexto, 'Novidade');
    });

    test('percentualDesconto deriva de original e promocional', () {
      final PromocaoModel promocao = PromocaoModel(
        valorOriginal: 80,
        valorPromocional: 56,
      );

      expect(promocao.percentualDesconto, closeTo(30, 0.01));
    });

    test('percentualDesconto é zero quando original é zero', () {
      final PromocaoModel promocao = PromocaoModel(
        valorOriginal: 0,
        valorPromocional: 10,
      );

      expect(promocao.percentualDesconto, 0);
      expect(promocao.badgeTexto, isNull);
    });

    test('toJson round-trip preserva os campos', () {
      final PromocaoModel original = PromocaoModel.fromJson(<String, dynamic>{
        'nome': 'Corte da semana',
        'descricao': 'Corte masculino com hidratação.',
        'valor_original': 50,
        'valor_promocional': 35,
        'validade': '2026-09-15',
        'barbearia': <String, dynamic>{
          'id': 3,
          'nome': 'Barbearia Centro Cívico',
        },
      });

      final PromocaoModel copia = PromocaoModel.fromJson(original.toJson());

      expect(copia.nome, original.nome);
      expect(copia.valorOriginal, original.valorOriginal);
      expect(copia.valorPromocional, original.valorPromocional);
      expect(copia.percentualDesconto, closeTo(30, 0.01));
      expect(copia.barbearia?.nome, 'Barbearia Centro Cívico');
    });
  });
}
