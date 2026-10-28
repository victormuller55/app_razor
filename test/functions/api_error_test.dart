import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  group('falhas de comunicação (RAZ-06)', () {
    test('tempo esgotado manda conferir o resultado antes de repetir', () {
      final ErrorModel error = errorModelFromApi(TimeoutException('demorou'));
      expect(error.tipo, tipoTempoEsgotado);
      expect(error.mensagem, mensagemTempoEsgotado);
    });

    test('servidor fora do ar ou rede caída vira mensagem de conexão', () {
      expect(errorModelFromApi(const SocketException('Connection refused')).mensagem, mensagemSemConexao);
      expect(errorModelFromApi(const HandshakeException('tls')).tipo, tipoSemConexao);
    });

    test('corpo de sem internet do muller_package não se perde', () {
      final ErrorModel error = errorModelFromApi(
        ApiException(
          AppResponse(
            statusCode: 502,
            body: jsonEncode(<String, dynamic>{
              'tipo': 'BAD GATEWAY',
              'mensagem': 'Verifique sua conexão com a internet',
              'erro': 'Sem conexão com a internet',
            }),
          ),
        ),
      );
      expect(error.tipo, tipoSemConexao);
      expect(error.mensagem, mensagemSemConexao);
    });

    test('500 da API e 502 em HTML não mostram texto técnico', () {
      final ErrorModel interno = errorModelFromApi(
        ApiException(
          AppResponse(
            statusCode: 500,
            body: jsonEncode(<String, dynamic>{
              'status': 500,
              'message': 'Bearer eyJsegredo.token',
              'error': 'access_token=secreto',
            }),
          ),
        ),
      );
      expect(interno.mensagem, mensagemServidor);
      expect(interno.tipo, '500');
      expect(interno.erro, isEmpty);
      expect(interno.mensagem, isNot(contains('eyJ')));

      final ErrorModel proxy = errorModelFromApi(
        ApiException(AppResponse(statusCode: 502, body: '<html>Bad Gateway</html>')),
      );
      expect(proxy.mensagem, mensagemServidor);
      expect(proxy.erro, isEmpty);
    });

    test('503 com motivo da API (Mercado Pago fora) mantém o motivo', () {
      final ErrorModel error = errorModelFromApi(
        ApiException(
          AppResponse(
            statusCode: 503,
            body: jsonEncode(<String, dynamic>{
              'status': 503,
              'message': 'Mercado Pago indisponível no momento. Tente novamente em instantes',
            }),
          ),
        ),
      );
      expect(error.mensagem, contains('Mercado Pago indisponível'));
    });

    test('resposta malformada ou erro de código não quebra nem mostra detalhe', () {
      expect(errorModelFromApi(const FormatException('Unexpected character')).mensagem, AppStrings.ocorreuUmErro);
      expect(errorModelFromApi(ApiException(AppResponse(statusCode: 400, body: '{quebrado'))).mensagem,
          AppStrings.ocorreuUmErro);
    });
  });
}
