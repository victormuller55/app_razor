import 'package:app_razor/pages/agendamento/widgets/profissional_select_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inicialProfissional', () {
    test('usa a primeira letra do nome', () {
      expect(inicialProfissional('Gustavo Freitas'), 'G');
    });

    test('ignora espaços no início', () {
      expect(inicialProfissional('  leandro'), 'L');
    });

    test('usa interrogação quando o nome está vazio', () {
      expect(inicialProfissional(null), '?');
      expect(inicialProfissional('   '), '?');
    });
  });
}
