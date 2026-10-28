import 'dart:async';

import 'package:app_razor/pages/recuperar_senha/recuperar_senha_bloc.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_event.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

const String mensagemGenerica =
    'Se existir uma conta com este e-mail, enviaremos um código de recuperação em instantes.';

ApiException erro400(String mensagem) {
  return ApiException(AppResponse(
    statusCode: 400,
    body: '{"status":400,"error":"Bad Request","message":"$mensagem","code":"REGRA_NEGOCIO"}',
  ));
}

Future<RecuperarSenhaState> pronto(RecuperarSenhaBloc bloc) {
  return bloc.stream.firstWhere((RecuperarSenhaState s) => !s.carregando);
}

void main() {
  group('RecuperarSenhaBloc', () {
    test('fluxo completo: código, autorização em memória e volta ao login sem token', () async {
      final List<String> chamadas = <String>[];
      final RecuperarSenhaBloc bloc = RecuperarSenhaBloc(
        solicitar: ({required String email}) async {
          chamadas.add('solicitar:$email');
          return <String, dynamic>{'mensagem': mensagemGenerica, 'reenviar_em_segundos': 60, 'validade_minutos': 10};
        },
        verificar: ({required String email, required String codigo}) async {
          chamadas.add('verificar:$email:$codigo');
          return <String, dynamic>{'mensagem': 'ok', 'token': 'tok-123'};
        },
        redefinir: ({required String token, required String senha, required String confirmacao}) async {
          chamadas.add('redefinir:$token:$senha:$confirmacao');
          return <String, dynamic>{'mensagem': 'Senha redefinida. Entre com a nova senha.'};
        },
      );

      bloc.add(RecuperarSenhaSolicitarEvent(email: '  ana@exemplo.com '));
      RecuperarSenhaState s = await pronto(bloc);
      expect(s.passo, RecuperarSenhaPasso.codigo);
      expect(s.mensagem, mensagemGenerica);
      expect(s.reenviarEmSegundos, 60);
      expect(s.email, 'ana@exemplo.com');

      bloc.add(RecuperarSenhaVerificarEvent(codigo: '123456'));
      s = await pronto(bloc);
      expect(s.passo, RecuperarSenhaPasso.senha);
      expect(bloc.temAutorizacao, isTrue);

      bloc.add(RecuperarSenhaRedefinirEvent(senha: 'NovaSenha123', confirmacao: 'NovaSenha123'));
      s = await pronto(bloc);
      expect(s.passo, RecuperarSenhaPasso.concluido);
      expect(s.mensagem, 'Senha redefinida. Entre com a nova senha.');
      expect(bloc.temAutorizacao, isFalse);
      expect(chamadas, <String>[
        'solicitar:ana@exemplo.com',
        'verificar:ana@exemplo.com:123456',
        'redefinir:tok-123:NovaSenha123:NovaSenha123',
      ]);
      await bloc.close();
    });

    test('código inválido mostra a mensagem da API e continua no passo do código', () async {
      final RecuperarSenhaBloc bloc = RecuperarSenhaBloc(
        solicitar: ({required String email}) async => <String, dynamic>{'mensagem': mensagemGenerica},
        verificar: ({required String email, required String codigo}) async =>
            throw erro400('Código inválido ou expirado. Confira o código ou peça um novo.'),
      );
      bloc.add(RecuperarSenhaSolicitarEvent(email: 'ana@exemplo.com'));
      await pronto(bloc);

      bloc.add(RecuperarSenhaVerificarEvent(codigo: '000000'));
      final RecuperarSenhaState s = await pronto(bloc);
      expect(s.passo, RecuperarSenhaPasso.codigo);
      expect(s.erro, 'Código inválido ou expirado. Confira o código ou peça um novo.');
      expect(bloc.temAutorizacao, isFalse);
      await bloc.close();
    });

    test('valida código incompleto, senha curta e confirmação diferente sem chamar a API', () async {
      int chamadasApi = 0;
      final RecuperarSenhaBloc bloc = RecuperarSenhaBloc(
        solicitar: ({required String email}) async => <String, dynamic>{'mensagem': mensagemGenerica},
        verificar: ({required String email, required String codigo}) async {
          chamadasApi++;
          return <String, dynamic>{'token': 'tok'};
        },
        redefinir: ({required String token, required String senha, required String confirmacao}) async {
          chamadasApi++;
          return <String, dynamic>{};
        },
      );
      bloc.add(RecuperarSenhaSolicitarEvent(email: 'ana@exemplo.com'));
      await pronto(bloc);

      bloc.add(RecuperarSenhaVerificarEvent(codigo: '12a'));
      expect((await bloc.stream.first).erro, 'O código tem 6 números.');
      expect(chamadasApi, 0);

      bloc.add(RecuperarSenhaVerificarEvent(codigo: '123456'));
      await pronto(bloc);
      chamadasApi = 0;

      bloc.add(RecuperarSenhaRedefinirEvent(senha: 'curta', confirmacao: 'curta'));
      expect((await bloc.stream.first).erro, 'A senha deve ter entre 8 e 128 caracteres.');
      bloc.add(RecuperarSenhaRedefinirEvent(senha: 'NovaSenha123', confirmacao: 'Outra12345'));
      expect((await bloc.stream.first).erro, 'A confirmação não confere com a nova senha.');
      expect(chamadasApi, 0);
      await bloc.close();
    });

    test('recomeçar apaga a autorização e volta ao e-mail mantendo o endereço', () async {
      final RecuperarSenhaBloc bloc = RecuperarSenhaBloc(
        solicitar: ({required String email}) async => <String, dynamic>{'mensagem': mensagemGenerica},
        verificar: ({required String email, required String codigo}) async => <String, dynamic>{'token': 'tok'},
      );
      bloc.add(RecuperarSenhaSolicitarEvent(email: 'ana@exemplo.com'));
      await pronto(bloc);
      bloc.add(RecuperarSenhaVerificarEvent(codigo: '123456'));
      await pronto(bloc);

      bloc.add(RecuperarSenhaRecomecarEvent());
      final RecuperarSenhaState s = await bloc.stream.first;
      expect(s.passo, RecuperarSenhaPasso.email);
      expect(s.email, 'ana@exemplo.com');
      expect(bloc.temAutorizacao, isFalse);
      await bloc.close();
    });

    test('sem conexão ou tempo esgotado mostra mensagem clara', () async {
      final RecuperarSenhaBloc bloc = RecuperarSenhaBloc(
        solicitar: ({required String email}) async => throw TimeoutException('lento'),
      );
      bloc.add(RecuperarSenhaSolicitarEvent(email: 'ana@exemplo.com'));
      final RecuperarSenhaState s = await pronto(bloc);
      expect(s.passo, RecuperarSenhaPasso.email);
      expect(s.erro, isNotEmpty);
      expect(s.erro, isNot(contains('TimeoutException')));
      await bloc.close();
    });
  });
}
