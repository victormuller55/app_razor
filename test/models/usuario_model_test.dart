import 'package:app_razor/models/usuario_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsuarioModel.fromMap', () {
    test('mapeia campos snake_case da API', () {
      final UsuarioModel usuario = UsuarioModel.fromMap(<String, dynamic>{
        'id': 1,
        'nome': 'Maria Silva',
        'email': 'maria@exemplo.com',
        'tipo': 'user_app',
        'foto': '/uploads/avatars/1.jpg',
        'ativo': true,
        'data_criacao': '2026-08-26T21:00:00',
        'data_edicao': '2026-08-26T21:00:00',
      });

      expect(usuario.id, 1);
      expect(usuario.nome, 'Maria Silva');
      expect(usuario.email, 'maria@exemplo.com');
      expect(usuario.tipo, 'user_app');
      expect(usuario.foto, '/uploads/avatars/1.jpg');
      expect(usuario.ativo, isTrue);
      expect(usuario.dataCriacao, '2026-08-26T21:00:00');
      expect(usuario.dataEdicao, '2026-08-26T21:00:00');
    });

    test('não inclui senha no toMap', () {
      final UsuarioModel usuario = UsuarioModel.fromMap(<String, dynamic>{
        'id': 1,
        'nome': 'Maria Silva',
        'email': 'maria@exemplo.com',
        'tipo': 'user_app',
        'ativo': true,
        'data_criacao': '2026-08-26T21:00:00',
        'data_edicao': '2026-08-26T21:00:00',
        'senha': 'nao-deve-aparecer',
      });

      final Map<String, dynamic> map = usuario.toMap();

      expect(map.containsKey('senha'), isFalse);
      expect(map['data_criacao'], '2026-08-26T21:00:00');
      expect(map['data_edicao'], '2026-08-26T21:00:00');
      expect(map['id'], 1);
      expect(map['nome'], 'Maria Silva');
      expect(map['email'], 'maria@exemplo.com');
      expect(map['tipo'], 'user_app');
      expect(map['foto'], isNull);
      expect(map['ativo'], isTrue);
    });
  });
}
