import 'package:app_razor/models/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginModel.fromMap', () {
    test('mapeia usuario e token', () {
      final LoginModel login = LoginModel.fromMap(<String, dynamic>{
        'token': 'eyJhbGciOiJIUzI1NiJ9...',
        'usuario': <String, dynamic>{
          'id': 1,
          'nome': 'Maria Silva',
          'email': 'maria@exemplo.com',
          'tipo': 'user_app',
          'ativo': true,
          'data_criacao': '2026-08-26T21:00:00',
          'data_edicao': '2026-08-26T21:00:00',
        },
      });

      expect(login.token, 'eyJhbGciOiJIUzI1NiJ9...');
      expect(login.usuario?.id, 1);
      expect(login.usuario?.nome, 'Maria Silva');
      expect(login.usuario?.email, 'maria@exemplo.com');
      expect(login.usuario?.tipo, 'user_app');
      expect(login.usuario?.ativo, isTrue);
      expect(login.usuario?.dataCriacao, '2026-08-26T21:00:00');
      expect(login.usuario?.dataEdicao, '2026-08-26T21:00:00');
    });
  });
}
