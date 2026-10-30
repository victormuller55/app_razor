import 'dart:async';

import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/functions/push_notificacoes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase de mentira: nada sai do teste e os tokens são valores fictícios.
class PlataformaFalsa implements PlataformaPush {
  String? tokenAtual = 'token-a';
  PermissaoStatus status = PermissaoStatus.concedida;
  PermissaoStatus respostaAoPedido = PermissaoStatus.concedida;
  Map<String, dynamic>? inicial;
  int apagados = 0;
  int pedidos = 0;

  final StreamController<String> renovado = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> recebido =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> tocado =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<String?> token() async => tokenAtual;

  @override
  Stream<String> get tokenRenovado => renovado.stream;

  @override
  Future<void> apagarToken() async => apagados++;

  @override
  Future<PermissaoStatus> statusPermissao() async => status;

  @override
  Future<PermissaoStatus> pedirPermissao() async {
    pedidos++;
    status = respostaAoPedido;
    return status;
  }

  @override
  Stream<Map<String, dynamic>> get recebidoEmPrimeiroPlano => recebido.stream;

  @override
  Stream<Map<String, dynamic>> get abertoPeloToque => tocado.stream;

  @override
  Future<Map<String, dynamic>?> abertoComAppFechado() async => inicial;
}

void main() {
  late PlataformaFalsa plataforma;
  late List<Map<String, dynamic>> registrados;
  late List<Map<String, dynamic>> removidos;
  late String? tokenSalvo;

  setUp(() {
    plataforma = PlataformaFalsa();
    registrados = <Map<String, dynamic>>[];
    removidos = <Map<String, dynamic>>[];
    tokenSalvo = null;
  });

  PushNotificacoes push({bool disponivel = true, bool apiFalha = false, String? tokenInicio}) {
    return PushNotificacoes(
      plataforma: plataforma,
      disponivel: disponivel,
      tokenInicioAtividade: () async => tokenInicio,
      registrar: (Map<String, dynamic> corpo) async {
        if (apiFalha) {
          throw Exception('sem rede');
        }
        registrados.add(corpo);
      },
      remover: (Map<String, dynamic> corpo) async {
        if (apiFalha) {
          throw Exception('sem rede');
        }
        removidos.add(corpo);
      },
      lerTokenSalvo: () async => tokenSalvo,
      salvarToken: (String? token) async => tokenSalvo = token,
    );
  }

  group('destinoDoAviso', () {
    test('avaliação e cancelamento pela barbearia abrem o aviso na tela', () {
      expect(
        destinoDoAviso(<String, dynamic>{'tipo': 'ATENDIMENTO_CONCLUIDO'}),
        DestinoAviso.avisoNaTela,
      );
      expect(
        destinoDoAviso(<String, dynamic>{'tipo': 'AGENDAMENTO_CANCELADO_BARBEARIA'}),
        DestinoAviso.avisoNaTela,
      );
    });

    test('lembrete, confirmação, pagamento e devolução abrem os agendamentos', () {
      for (final String tipo in <String>[
        'AGENDAMENTO_CONFIRMADO',
        'LEMBRETE_AGENDAMENTO',
        'NAO_COMPARECIMENTO',
        'PAGAMENTO_CONFIRMADO',
        'PAGAMENTO_RECUSADO',
        'REEMBOLSO_SOLICITADO',
        'REEMBOLSO_CONFIRMADO',
        'REEMBOLSO_FALHOU',
      ]) {
        expect(destinoDoAviso(<String, dynamic>{'tipo': tipo}), DestinoAviso.agendamentos, reason: tipo);
      }
    });

    test('tipo desconhecido só abre o app', () {
      expect(destinoDoAviso(<String, dynamic>{'tipo': 'NOVO_TIPO'}), DestinoAviso.inicio);
      expect(destinoDoAviso(<String, dynamic>{}), DestinoAviso.inicio);
    });

    test('id da notificação vem como texto no push', () {
      expect(idNotificacaoDoAviso(<String, dynamic>{'id_notificacao': '15'}), 15);
      expect(idNotificacaoDoAviso(<String, dynamic>{}), isNull);
    });
  });

  test('sem configuração do Firebase no build, não há opções (push desligado)', () {
    expect(ConfigFirebase.opcoes(), isNull);
    expect(
      ConfigFirebase.opcoes(projeto: 'p', chave: 'k', remetente: 's', appId: 'a'),
      isNotNull,
    );
  });

  test('cadastra o aparelho e, quando o token troca, informa o anterior', () async {
    final PushNotificacoes servico = push();

    await servico.registrarAparelho();
    expect(registrados.single, <String, dynamic>{'token': 'token-a', 'plataforma': 'ANDROID'});
    expect(tokenSalvo, 'token-a');

    await servico.iniciarSessao(aoReceber: (_) {}, aoTocar: (_) {});
    plataforma.renovado.add('token-b');
    await pumpEventQueue();

    expect(registrados.last, <String, dynamic>{
      'token': 'token-b',
      'plataforma': 'ANDROID',
      'token_anterior': 'token-a',
    });
    expect(tokenSalvo, 'token-b');
    await servico.encerrarSessao();
  });

  test('com o token de início da Live Activity (iOS 17.2+), manda junto no cadastro', () async {
    await push(tokenInicio: 'inicio-a').registrarAparelho();
    expect(registrados.single, <String, dynamic>{
      'token': 'token-a',
      'plataforma': 'ANDROID',
      'token_inicio_atividade': 'inicio-a',
    });
  });

  test('sem permissão não cadastra nada; ao liberar na tela de permissões, cadastra', () async {
    plataforma.status = PermissaoStatus.pendente;
    final PushNotificacoes servico = push();

    await servico.registrarAparelho();
    expect(registrados, isEmpty);

    plataforma.respostaAoPedido = PermissaoStatus.bloqueada;
    expect(await servico.pedirPermissao(), PermissaoStatus.bloqueada);
    expect(registrados, isEmpty);

    plataforma.respostaAoPedido = PermissaoStatus.concedida;
    expect(await servico.pedirPermissao(), PermissaoStatus.concedida);
    expect(registrados, hasLength(1));
  });

  test('Firebase indisponível: nada é chamado e o app segue', () async {
    final PushNotificacoes servico = push(disponivel: false);

    expect(servico.disponivel, isFalse);
    expect(await servico.pedirPermissao(), PermissaoStatus.pendente);
    await servico.iniciarSessao(aoReceber: (_) {}, aoTocar: (_) {});
    await servico.registrarAparelho();

    expect(plataforma.pedidos, 0);
    expect(registrados, isEmpty);
  });

  test('push recebido e tocado chegam aos ouvintes; o de app fechado só uma vez', () async {
    plataforma.inicial = <String, dynamic>{'tipo': 'LEMBRETE_AGENDAMENTO', 'id_notificacao': '3'};
    final PushNotificacoes servico = push();
    final List<Map<String, dynamic>> recebidos = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> tocados = <Map<String, dynamic>>[];

    await servico.iniciarSessao(aoReceber: recebidos.add, aoTocar: tocados.add);
    plataforma.recebido.add(<String, dynamic>{'tipo': 'PAGAMENTO_CONFIRMADO'});
    plataforma.tocado.add(<String, dynamic>{'tipo': 'REEMBOLSO_CONFIRMADO'});
    await pumpEventQueue();

    expect(recebidos.single['tipo'], 'PAGAMENTO_CONFIRMADO');
    expect(tocados.map((Map<String, dynamic> d) => d['tipo']), <String>[
      'LEMBRETE_AGENDAMENTO',
      'REEMBOLSO_CONFIRMADO',
    ]);

    // O menu remontou (ex.: voltou da tela de permissões): não reabre o push que abriu o app.
    await servico.iniciarSessao(aoReceber: recebidos.add, aoTocar: tocados.add);
    await pumpEventQueue();
    expect(tocados, hasLength(2));
    await servico.encerrarSessao();
  });

  test('depois de encerrar a sessão, pushes não chegam mais', () async {
    final PushNotificacoes servico = push();
    final List<Map<String, dynamic>> recebidos = <Map<String, dynamic>>[];

    await servico.iniciarSessao(aoReceber: recebidos.add, aoTocar: (_) {});
    await servico.encerrarSessao();
    plataforma.recebido.add(<String, dynamic>{'tipo': 'PAGAMENTO_CONFIRMADO'});
    await pumpEventQueue();

    expect(recebidos, isEmpty);
  });

  test('ao sair da conta: desvincula na API, apaga o token do aparelho e o guardado', () async {
    tokenSalvo = 'token-a';
    final PushNotificacoes servico = push();

    await servico.desvincular();

    expect(removidos.single, <String, dynamic>{'token': 'token-a'});
    expect(plataforma.apagados, 1);
    expect(tokenSalvo, isNull);
  });

  test('sem rede ao sair: ainda apaga o token local para a próxima conta não receber', () async {
    tokenSalvo = 'token-a';
    final PushNotificacoes servico = push(apiFalha: true);

    await servico.desvincular();

    expect(plataforma.apagados, 1);
    expect(tokenSalvo, isNull);
  });

  test('conta excluída: só esquece o aparelho, sem chamar a API', () async {
    tokenSalvo = 'token-a';
    final PushNotificacoes servico = push();

    await servico.esquecerAparelho();

    expect(removidos, isEmpty);
    expect(plataforma.apagados, 1);
    expect(tokenSalvo, isNull);
  });
}
