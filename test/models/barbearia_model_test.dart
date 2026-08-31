import 'package:app_razor/models/barbearia_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarbeariaModel', () {
    test('fromJson mapeia campos da UI', () {
      final BarbeariaModel barbearia = BarbeariaModel.fromJson(<String, dynamic>{
        'id': 1,
        'nome': 'Navalha do Batel',
        'logo': '',
        'nota': 4.8,
        'distancia_km': 0.8,
        'bairro': 'Batel',
        'cidade': 'Curitiba',
        'aberto': true,
        'nome_servico': 'Corte clássico',
        'preco_servico': 45,
        'latitude': -25.4412,
        'longitude': -49.2768,
      });

      expect(barbearia.id, 1);
      expect(barbearia.nome, 'Navalha do Batel');
      expect(barbearia.nota, 4.8);
      expect(barbearia.distanciaKm, 0.8);
      expect(barbearia.bairro, 'Batel');
      expect(barbearia.cidade, 'Curitiba');
      expect(barbearia.aberto, isTrue);
      expect(barbearia.nomeServico, 'Corte clássico');
      expect(barbearia.precoServico, 45);
      expect(barbearia.latitude, -25.4412);
      expect(barbearia.longitude, -49.2768);
      expect(barbearia.localDescricao, 'Batel, Curitiba');
    });

    test('fromJson mapeia contrato da API (imagem, nota_media, id int)', () {
      final BarbeariaModel barbearia = BarbeariaModel.fromJson(<String, dynamic>{
        'id': 1,
        'nome': 'Razor Centro',
        'imagem': '/uploads/barbearias/abc.jpg',
        'bairro': 'Centro',
        'cidade': 'São Paulo',
        'nota_media': 4.50,
        'total_avaliacoes': 12,
        'distancia_km': 1.23,
        'aberto': true,
        'hora_abertura': '09:00:00',
        'hora_fechamento': '18:00:00',
        'fechado': false,
        'latitude': -23.5505,
        'longitude': -46.6333,
      });

      expect(barbearia.id, 1);
      expect(barbearia.nome, 'Razor Centro');
      expect(barbearia.logo, 'http://192.168.0.105:5000/uploads/barbearias/abc.jpg');
      expect(barbearia.nota, 4.5);
      expect(barbearia.distanciaKm, 1.23);
      expect(barbearia.bairro, 'Centro');
      expect(barbearia.cidade, 'São Paulo');
      expect(barbearia.aberto, isTrue);
      expect(barbearia.horaAbertura, '09:00:00');
      expect(barbearia.horaFechamento, '18:00:00');
      expect(barbearia.totalAvaliacoes, 12);
      expect(barbearia.horarioHoje, '09:00 – 18:00');
      expect(barbearia.latitude, -23.5505);
      expect(barbearia.longitude, -46.6333);
      expect(barbearia.localDescricao, 'Centro, São Paulo');
    });

    test('fromJson aceita distancia_km nula nas favoritas sem geo', () {
      final BarbeariaModel barbearia = BarbeariaModel.fromJson(<String, dynamic>{
        'id': 1,
        'nome': 'Razor Centro',
        'imagem': '/uploads/barbearias/abc.jpg',
        'nota_media': 4,
        'distancia_km': null,
      });

      expect(barbearia.distanciaKm, isNull);
      expect(barbearia.nota, 4);
    });

    test('toJson round-trip preserva os campos', () {
      final BarbeariaModel original = BarbeariaModel.fromJson(<String, dynamic>{
        'id': 2,
        'nome': 'Studio Água Verde',
        'nota': 4.6,
        'distancia_km': 1.4,
        'bairro': 'Água Verde',
        'cidade': 'Curitiba',
        'aberto': false,
        'latitude': -25.4551,
        'longitude': -49.2765,
      });

      final BarbeariaModel copia = BarbeariaModel.fromJson(original.toJson());

      expect(copia.id, original.id);
      expect(copia.nome, original.nome);
      expect(copia.nota, original.nota);
      expect(copia.aberto, isFalse);
      expect(copia.latitude, original.latitude);
      expect(copia.longitude, original.longitude);
    });
  });
}
