import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconeServico', () {
    test('usa tesoura para corte', () {
      expect(iconeServico('Corte masculino'), Phosphor.scissors);
    });

    test('usa usuário para barba', () {
      expect(iconeServico('Barba'), Phosphor.user);
    });

    test('usa tesoura para combo com corte', () {
      expect(iconeServico('Corte + Barba'), Phosphor.scissors);
    });

    test('usa gota para hidratação', () {
      expect(iconeServico('Hidratação capilar'), Phosphor.drop);
    });

    test('usa brilho para sobrancelha', () {
      expect(iconeServico('Sobrancelha'), Phosphor.sparkle);
    });
  });
}
