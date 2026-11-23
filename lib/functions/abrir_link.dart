import 'package:url_launcher/url_launcher.dart';

const String urlPoliticaPrivacidade =
    'https://www.cortaro.com.br/privacidade.html';

typedef LaunchLink = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _launchPadrao(Uri uri, LaunchMode mode) {
  return launchUrl(uri, mode: mode);
}

/// Abre o link no navegador dentro do app (Safari View Controller no iOS,
/// Custom Tabs no Android). Se não der, tenta o navegador do aparelho.
Future<bool> abrirLinkNoApp(String url, {LaunchLink? launch}) async {
  final LaunchLink launcher = launch ?? _launchPadrao;
  final Uri uri = Uri.parse(url);
  try {
    if (await launcher(uri, LaunchMode.inAppBrowserView)) {
      return true;
    }
  } catch (_) {
    // Sem navegador interno disponível: segue para o externo.
  }
  try {
    return await launcher(uri, LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> abrirPoliticaPrivacidade({LaunchLink? launch}) {
  return abrirLinkNoApp(urlPoliticaPrivacidade, launch: launch);
}
