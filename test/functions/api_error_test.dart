import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  group('errorModelFromApi', () {
    test('monta a mensagem a partir de message', () {
      final ErrorModel error = errorModelFromApi(
        ApiException(
          AppResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{
              'timestamp': '2026-08-26T21:00:00',
              'status': 401,
              'error': 'Unauthorized',
              'message': 'Credenciais inválidas',
            }),
          ),
        ),
      );

      expect(error.mensagem, 'Credenciais inválidas');
      expect(error.erro, 'Unauthorized');
      expect(error.tipo, '401');
    });

    test('concatena errors por campo à message', () {
      final ErrorModel error = errorModelFromApi(
        ApiException(
          AppResponse(
            statusCode: 400,
            body: jsonEncode(<String, dynamic>{
              'timestamp': '2026-08-26T21:00:00',
              'status': 400,
              'error': 'Bad Request',
              'message': 'Erro de validação',
              'errors': <String, dynamic>{
                'email': 'E-mail inválido',
                'senha': 'A senha deve ter entre 8 e 128 caracteres',
              },
            }),
          ),
        ),
      );

      expect(error.mensagem, contains('Erro de validação'));
      expect(error.mensagem, contains('E-mail inválido'));
      expect(
        error.mensagem,
        contains('A senha deve ter entre 8 e 128 caracteres'),
      );
    });
  });
}
