import 'package:app_razor/functions/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  group('AppValidators.required', () {
    test('retorna erro quando o valor é nulo', () {
      expect(AppValidators.required(null), isNotNull);
    });

    test('retorna erro quando o valor está vazio', () {
      expect(AppValidators.required(''), isNotNull);
      expect(AppValidators.required('   '), isNotNull);
    });

    test('usa a mensagem customizada', () {
      expect(
        AppValidators.required('', errorMessage: 'Senha é obrigatória'),
        'Senha é obrigatória',
      );
    });

    test('retorna null quando o valor está preenchido', () {
      expect(AppValidators.required('abc'), isNull);
    });
  });

  group('AppValidators.email', () {
    test('retorna erro quando o valor é nulo ou vazio', () {
      expect(AppValidators.email(null), isNotNull);
      expect(AppValidators.email(''), isNotNull);
    });

    test('retorna erro quando o formato é inválido', () {
      expect(
        AppValidators.email('invalido', errorMessage: 'E-mail inválido'),
        'E-mail inválido',
      );
    });

    test('retorna null quando o e-mail é válido', () {
      expect(AppValidators.email('user@example.com'), isNull);
    });

    test('retorna erro quando o e-mail tem mais de 180 caracteres', () {
      final String localPart = 'a' * 170;
      expect(AppValidators.email('$localPart@exemplo.com'), isNotNull);
    });
  });

  group('AppValidators.nome', () {
    test('retorna erro quando o valor é nulo ou vazio', () {
      expect(AppValidators.nome(null), isNotNull);
      expect(AppValidators.nome(''), isNotNull);
      expect(AppValidators.nome('   '), isNotNull);
    });

    test('retorna erro quando o nome tem mais de 150 caracteres', () {
      expect(AppValidators.nome('a' * 151), isNotNull);
    });

    test('retorna null quando o nome está entre 1 e 150', () {
      expect(AppValidators.nome('M'), isNull);
      expect(AppValidators.nome('Maria Silva'), isNull);
      expect(AppValidators.nome('a' * 150), isNull);
    });
  });

  group('AppValidators.senhaCadastro', () {
    test('retorna erro quando a senha é nula ou vazia', () {
      expect(AppValidators.senhaCadastro(null), isNotNull);
      expect(AppValidators.senhaCadastro(''), isNotNull);
    });

    test('retorna erro quando a senha tem menos de 8 caracteres', () {
      expect(AppValidators.senhaCadastro('1234567'), isNotNull);
    });

    test('retorna erro quando a senha tem mais de 128 caracteres', () {
      expect(AppValidators.senhaCadastro('a' * 129), isNotNull);
    });

    test('retorna null quando a senha tem entre 8 e 128 caracteres', () {
      expect(AppValidators.senhaCadastro('senha123'), isNull);
      expect(AppValidators.senhaCadastro('a' * 128), isNull);
    });
  });

  group('AppValidators.confirmacaoSenha', () {
    test('retorna erro quando as senhas são diferentes', () {
      expect(
        AppValidators.confirmacaoSenha('outra', 'senha1234'),
        AppStrings.asSenhasNaoSaoIguais,
      );
    });

    test('retorna null quando as senhas são iguais', () {
      expect(
        AppValidators.confirmacaoSenha('senha1234', 'senha1234'),
        isNull,
      );
    });
  });
}
