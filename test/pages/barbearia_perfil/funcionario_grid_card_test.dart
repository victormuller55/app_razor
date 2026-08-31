import 'package:app_razor/pages/barbearia_perfil/widgets/funcionario_grid_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inicialFuncionario', () {
    test('usa a primeira letra do nome', () {
      expect(inicialFuncionario('Eduardo Pinto'), 'E');
    });

    test('ignora espaços no início', () {
      expect(inicialFuncionario('  henrique'), 'H');
    });

    test('usa interrogação quando o nome está vazio', () {
      expect(inicialFuncionario(null), '?');
      expect(inicialFuncionario('   '), '?');
    });
  });
}
