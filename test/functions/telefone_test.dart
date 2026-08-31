import 'package:app_razor/functions/telefone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formataTelefone', () {
    test('formata celular com 11 dígitos', () {
      expect(formataTelefone('41998020006'), '(41) 99802-0006');
    });

    test('formata telefone fixo com 10 dígitos', () {
      expect(formataTelefone('4133334444'), '(41) 3333-4444');
    });

    test('remove o DDI 55 antes de formatar', () {
      expect(formataTelefone('5541998020006'), '(41) 99802-0006');
    });

    test('mantém o texto quando não dá para formatar', () {
      expect(formataTelefone('123'), '123');
    });
  });

  group('ehCelularWhatsApp', () {
    test('reconhece celular brasileiro', () {
      expect(ehCelularWhatsApp('41998020006'), isTrue);
      expect(ehCelularWhatsApp('55 41 99802-0006'), isTrue);
    });

    test('não trata fixo como WhatsApp', () {
      expect(ehCelularWhatsApp('4133334444'), isFalse);
    });
  });

  group('uris de contato', () {
    test('monta tel e WhatsApp para celular', () {
      expect(telefoneUri('41998020006')?.toString(), 'tel:+5541998020006');
      expect(whatsappUri('41998020006')?.toString(), 'https://wa.me/5541998020006');
    });

    test('não monta WhatsApp para telefone fixo', () {
      expect(whatsappUri('4133334444'), isNull);
      expect(telefoneUri('4133334444')?.toString(), 'tel:+554133334444');
    });
  });
}
