import 'dart:async';
import 'dart:io';

import 'package:app_razor/app_config/const/app_endpoints.dart';
import 'package:app_razor/functions/http_cache.dart';
import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/models/notificacao_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Configuração do Firebase vinda do build (`--dart-define`), sem arquivo do Firebase no repositório:
///
/// ```
/// flutter run --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_API_KEY=...
///   --dart-define=FIREBASE_SENDER_ID=... --dart-define=FIREBASE_APP_ID_ANDROID=...
///   --dart-define=FIREBASE_APP_ID_IOS=... [--dart-define=FIREBASE_IOS_BUNDLE_ID=...]
/// ```
///
/// Sem esses valores o push fica desligado e o app segue só com os avisos buscados na API.
class ConfigFirebase {
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const String appIdAndroid = String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static const String appIdIos = String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const String iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  /// Opções para o aparelho atual, ou nulo quando falta algum valor (push desligado).
  static FirebaseOptions? opcoes({
    String projeto = projectId,
    String chave = apiKey,
    String remetente = senderId,
    String? appId,
    String bundleIos = iosBundleId,
  }) {
    final String app = appId ?? (_ios ? appIdIos : appIdAndroid);
    if (projeto.isEmpty || chave.isEmpty || remetente.isEmpty || app.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: chave,
      appId: app,
      messagingSenderId: remetente,
      projectId: projeto,
      iosBundleId: bundleIos.isEmpty ? null : bundleIos,
    );
  }

  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// Para onde o toque num push leva.
enum DestinoAviso {
  /// Aviso que abre na própria tela (avaliar o atendimento, horário cancelado pela barbearia).
  avisoNaTela,

  /// Lista de agendamentos: confirmação, lembrete, alteração, pagamento e devolução.
  agendamentos,

  /// Tipo desconhecido (versão nova do servidor): só abre o app.
  inicio,
}

/// Destino a partir dos dados do push (`tipo`, `id_notificacao`, `id_agendamento`).
DestinoAviso destinoDoAviso(Map<String, dynamic> dados) {
  switch (dados['tipo']) {
    case NotificacaoModel.tipoAtendimentoConcluido:
    case NotificacaoModel.tipoCanceladoPelaBarbearia:
      return DestinoAviso.avisoNaTela;
    case 'AGENDAMENTO_CONFIRMADO':
    case 'LEMBRETE_AGENDAMENTO':
    case 'NAO_COMPARECIMENTO':
    case 'PAGAMENTO_CONFIRMADO':
    case 'PAGAMENTO_RECUSADO':
    case 'REEMBOLSO_SOLICITADO':
    case 'REEMBOLSO_CONFIRMADO':
    case 'REEMBOLSO_FALHOU':
      return DestinoAviso.agendamentos;
    default:
      return DestinoAviso.inicio;
  }
}

int? idNotificacaoDoAviso(Map<String, dynamic> dados) {
  return int.tryParse('${dados['id_notificacao'] ?? ''}');
}

/// O que o app usa do Firebase Messaging. Separado para os testes rodarem sem Firebase.
abstract class PlataformaPush {
  Future<String?> token();
  Stream<String> get tokenRenovado;
  Future<void> apagarToken();
  Future<PermissaoStatus> statusPermissao();
  Future<PermissaoStatus> pedirPermissao();
  Stream<Map<String, dynamic>> get recebidoEmPrimeiroPlano;
  Stream<Map<String, dynamic>> get abertoPeloToque;
  Future<Map<String, dynamic>?> abertoComAppFechado();
}

/// Usa o token de registro clássico, que a API manda em `message.token` do FCM HTTP v1. O firebase_messaging 17
/// marcou esse caminho como obsoleto em favor do ID de instalação (register/onRegistered, envio direto), que
/// ainda não foi validado com a API; a troca fica como pendência do RAZ-11.
// ignore_for_file: deprecated_member_use
class _PlataformaFirebase implements PlataformaPush {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<String?> token() => _fcm.getToken();

  @override
  Stream<String> get tokenRenovado => _fcm.onTokenRefresh;

  @override
  Future<void> apagarToken() => _fcm.deleteToken();

  @override
  Future<PermissaoStatus> statusPermissao() async =>
      _status((await _fcm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PermissaoStatus> pedirPermissao() async =>
      _status((await _fcm.requestPermission()).authorizationStatus);

  @override
  Stream<Map<String, dynamic>> get recebidoEmPrimeiroPlano =>
      FirebaseMessaging.onMessage.map((RemoteMessage m) => m.data);

  @override
  Stream<Map<String, dynamic>> get abertoPeloToque =>
      FirebaseMessaging.onMessageOpenedApp.map((RemoteMessage m) => m.data);

  @override
  Future<Map<String, dynamic>?> abertoComAppFechado() async => (await _fcm.getInitialMessage())?.data;

  static PermissaoStatus _status(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PermissaoStatus.concedida;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.deniedPermanently:
        return PermissaoStatus.bloqueada;
      case AuthorizationStatus.notDetermined:
        return PermissaoStatus.pendente;
    }
  }
}

typedef EnviarAparelho = Future<void> Function(Map<String, dynamic> corpo);

const FlutterSecureStorage _armazenamento = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
const String _chaveToken = 'push_token';

/// Recebido com o app em segundo plano ou fechado: o sistema já mostra a notificação; o app só age no
/// toque ([PushNotificacoes.iniciarSessao]). Precisa ser função de topo para o Firebase chamar.
@pragma('vm:entry-point')
Future<void> pushEmSegundoPlano(RemoteMessage mensagem) async {}

/// Push pelo Firebase Cloud Messaging (RAZ-11).
///
/// - O aparelho é cadastrado na API para a conta logada (o servidor usa o JWT, não um id do app).
/// - Token renovado pelo FCM: cadastra o novo e avisa qual era o anterior.
/// - Ao sair da conta: desvincula na API e apaga o token do aparelho antes de apagar o login.
/// - Permissão negada ou Firebase não configurado: o app funciona igual, só sem push.
/// - O token não é impresso nem guardado fora do armazenamento seguro.
class PushNotificacoes {
  PushNotificacoes({
    PlataformaPush? plataforma,
    EnviarAparelho? registrar,
    EnviarAparelho? remover,
    Future<String?> Function()? lerTokenSalvo,
    Future<void> Function(String? token)? salvarToken,
    bool disponivel = false,
  }) : _plataforma = plataforma,
       _registrar = registrar ?? _registrarNaApi,
       _remover = remover ?? _removerNaApi,
       _lerTokenSalvo = lerTokenSalvo ?? (() => _armazenamento.read(key: _chaveToken)),
       _salvarToken = salvarToken ?? _salvarTokenSeguro,
       _disponivel = disponivel;

  static final PushNotificacoes instance = PushNotificacoes();

  PlataformaPush? _plataforma;
  final EnviarAparelho _registrar;
  final EnviarAparelho _remover;
  final Future<String?> Function() _lerTokenSalvo;
  final Future<void> Function(String? token) _salvarToken;
  bool _disponivel;
  final List<StreamSubscription<dynamic>> _ouvintes = <StreamSubscription<dynamic>>[];
  bool _inicialConsumido = false;

  /// Firebase configurado e iniciado neste aparelho.
  bool get disponivel => _disponivel && _plataforma != null;

  String get _nomePlataforma => !kIsWeb && Platform.isIOS ? 'IOS' : 'ANDROID';

  /// Na abertura do app, antes do primeiro quadro. Falha ou falta de configuração só desliga o push.
  Future<void> inicializar() async {
    final FirebaseOptions? opcoes = ConfigFirebase.opcoes();
    if (opcoes == null || kIsWeb) {
      return;
    }
    try {
      await Firebase.initializeApp(options: opcoes);
      FirebaseMessaging.onBackgroundMessage(pushEmSegundoPlano);
      // Em primeiro plano o app mostra o aviso na própria tela; o banner do iOS duplicaria.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      _plataforma = _PlataformaFirebase();
      _disponivel = true;
    } catch (_) {
      _disponivel = false;
    }
  }

  Future<PermissaoStatus> statusPermissao() async {
    if (!disponivel) {
      return PermissaoStatus.pendente;
    }
    try {
      return await _plataforma!.statusPermissao();
    } catch (_) {
      return PermissaoStatus.pendente;
    }
  }

  /// Pede a permissão do sistema (chamado pela tela de permissões, depois da explicação) e, se liberada,
  /// cadastra o aparelho.
  Future<PermissaoStatus> pedirPermissao() async {
    if (!disponivel) {
      return PermissaoStatus.pendente;
    }
    PermissaoStatus status;
    try {
      status = await _plataforma!.pedirPermissao();
    } catch (_) {
      return PermissaoStatus.pendente;
    }
    if (status == PermissaoStatus.concedida) {
      await registrarAparelho();
    }
    return status;
  }

  /// Cadastra o token atual para a conta logada. Sem permissão ou sem rede: tenta na próxima abertura.
  Future<void> registrarAparelho() async {
    if (!disponivel || await statusPermissao() != PermissaoStatus.concedida) {
      return;
    }
    try {
      final String? token = await _plataforma!.token();
      if (token == null || token.isEmpty) {
        return;
      }
      await _enviar(token);
    } catch (_) {}
  }

  Future<void> _enviar(String token) async {
    final String? anterior = await _lerTokenSalvo();
    await _registrar(<String, dynamic>{
      'token': token,
      'plataforma': _nomePlataforma,
      if (anterior != null && anterior.isNotEmpty && anterior != token) 'token_anterior': anterior,
    });
    await _salvarToken(token);
  }

  /// Logado no menu: cadastra o aparelho e passa a ouvir pushes e trocas de token.
  Future<void> iniciarSessao({
    required void Function(Map<String, dynamic> dados) aoReceber,
    required void Function(Map<String, dynamic> dados) aoTocar,
  }) async {
    if (!disponivel) {
      return;
    }
    await encerrarSessao();
    final PlataformaPush plataforma = _plataforma!;
    _ouvintes
      ..add(plataforma.tokenRenovado.listen((String token) async {
        try {
          await _enviar(token);
        } catch (_) {}
      }))
      ..add(plataforma.recebidoEmPrimeiroPlano.listen(aoReceber))
      ..add(plataforma.abertoPeloToque.listen(aoTocar));
    await registrarAparelho();
    if (!_inicialConsumido) {
      _inicialConsumido = true;
      try {
        final Map<String, dynamic>? inicial = await plataforma.abertoComAppFechado();
        if (inicial != null && inicial.isNotEmpty) {
          aoTocar(inicial);
        }
      } catch (_) {}
    }
  }

  Future<void> encerrarSessao() async {
    for (final StreamSubscription<dynamic> ouvinte in _ouvintes) {
      await ouvinte.cancel();
    }
    _ouvintes.clear();
  }

  /// Ao sair da conta, com o login ainda valendo: a API desvincula o aparelho desta conta e o token local é
  /// apagado, para a próxima pessoa que entrar neste aparelho não receber os avisos da anterior.
  Future<void> desvincular() async {
    try {
      final String? token = await _lerTokenSalvo();
      if (token != null && token.isNotEmpty) {
        await _remover(<String, dynamic>{'token': token});
      }
    } catch (_) {
      // Sem rede: o token é apagado abaixo e o FCM passa a recusá-lo; a API o desativa no próximo envio.
    }
    await esquecerAparelho();
  }

  /// Só no aparelho: para de ouvir e apaga o token (conta excluída, a API já desativou os aparelhos).
  Future<void> esquecerAparelho() async {
    await encerrarSessao();
    _inicialConsumido = false;
    try {
      if (disponivel) {
        await _plataforma!.apagarToken();
      }
    } catch (_) {}
    try {
      await _salvarToken(null);
    } catch (_) {}
  }

  static Future<void> _registrarNaApi(Map<String, dynamic> corpo) async {
    await HttpCache.putHTTPCached(endpoint: AppEndpoints.endpointDispositivos, body: corpo);
  }

  static Future<void> _removerNaApi(Map<String, dynamic> corpo) async {
    await HttpCache.postHTTPCached(endpoint: AppEndpoints.endpointDispositivosRemover, body: corpo);
  }

  static Future<void> _salvarTokenSeguro(String? token) async {
    if (token == null || token.isEmpty) {
      await _armazenamento.delete(key: _chaveToken);
      return;
    }
    await _armazenamento.write(key: _chaveToken, value: token);
  }
}
