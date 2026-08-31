import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarbeariaPerfilModel', () {
    test('fromJson mapeia perfil completo da API', () {
      final BarbeariaPerfilModel perfil = BarbeariaPerfilModel.fromJson(
        <String, dynamic>{
          'id': 1,
          'nome': 'Navalha Prime Centro',
          'descricao': 'Barbearia clássica',
          'imagem': '/uploads/barbearias/abc.jpg',
          'telefone': '41998010001',
          'endereco_completo': 'Rua X, 450 — Centro, Araucária - PR',
          'bairro': 'Centro',
          'cidade': 'Araucária',
          'nota_media': 4.8,
          'total_avaliacoes': 128,
          'distancia_km': 3.0,
          'aberto': false,
          'hora_abertura': '09:00:00',
          'hora_fechamento': '19:00:00',
          'favorito': true,
          'latitude': -25.5931,
          'longitude': -49.4104,
          'horarios': <Map<String, dynamic>>[
            <String, dynamic>{
              'dia_semana': 'SEGUNDA',
              'hora_abertura': '09:00:00',
              'hora_fechamento': '19:00:00',
              'fechado': false,
            },
            <String, dynamic>{
              'dia_semana': 'DOMINGO',
              'fechado': true,
            },
          ],
          'servicos': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 10,
              'nome': 'Corte',
              'imagem': '/uploads/servicos/corte.jpg',
              'preco': 45,
              'duracao_minutos': 40,
            },
          ],
          'funcionarios': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 20,
              'nome': 'João',
              'cargo': 'Barbeiro',
              'foto': '/uploads/funcionarios/joao.jpg',
              'servicos': <String>['Corte', 'Barba'],
            },
          ],
          'promocoes': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 30,
              'titulo': 'Corte em dobro',
              'preco_original': 80,
              'preco_promocional': 40,
            },
          ],
          'avaliacoes': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 40,
              'nota': 5,
              'comentario': 'Excelente',
              'nome_cliente': 'Ana',
              'data_criacao': '2026-08-26T21:00:00',
            },
          ],
        },
      );

      expect(perfil.id, 1);
      expect(perfil.nome, 'Navalha Prime Centro');
      expect(perfil.descricao, 'Barbearia clássica');
      expect(perfil.logo, 'http://10.0.2.2:5000/uploads/barbearias/abc.jpg');
      expect(perfil.telefone, '41998010001');
      expect(perfil.favorito, isTrue);
      expect(perfil.localDescricao, 'Centro, Araucária');
      expect(perfil.horarioHoje, '09:00 – 19:00');
      expect(perfil.horarios, hasLength(2));
      expect(perfil.horarios.first.diaLabel, 'Segunda');
      expect(perfil.horarios.first.horarioLabel, '09:00 – 19:00');
      expect(perfil.horarios.last.horarioLabel, 'Fechado');
      expect(perfil.servicos.single.nome, 'Corte');
      expect(
        perfil.servicos.single.imagem,
        'http://10.0.2.2:5000/uploads/servicos/corte.jpg',
      );
      expect(perfil.servicos.single.duracaoLabel, '40 min');
      expect(perfil.funcionarios.single.servicos, <String>['Corte', 'Barba']);
      expect(
        perfil.funcionarios.single.foto,
        'http://10.0.2.2:5000/uploads/funcionarios/joao.jpg',
      );
      expect(perfil.promocoes.single.nome, 'Corte em dobro');
      expect(perfil.promocoes.single.barbearia?.nome, 'Navalha Prime Centro');
      expect(perfil.avaliacoes.single.dataLabel, '26/08/2026');
      expect(perfil.asResumo.id, 1);
      expect(perfil.asResumo.latitude, -25.5931);
    });
  });
}
