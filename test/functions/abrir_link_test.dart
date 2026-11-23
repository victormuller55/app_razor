import 'package:app_razor/functions/abrir_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('abrirPoliticaPrivacidade', () {
    test('abre a política no navegador dentro do app', () async {
      final List<(Uri, LaunchMode)> chamadas = [];

      final bool abriu = await abrirPoliticaPrivacidade(
        launch: (Uri uri, LaunchMode mode) async {
          chamadas.add((uri, mode));
          return true;
        },
      );

      expect(abriu, isTrue);
      expect(chamadas, [
        (
          Uri.parse('https://www.cortaro.com.br/privacidade.html'),
          LaunchMode.inAppBrowserView,
        ),
      ]);
    });

    test('usa o navegador do aparelho se o interno não abrir', () async {
      final List<LaunchMode> modos = [];

      final bool abriu = await abrirPoliticaPrivacidade(
        launch: (Uri uri, LaunchMode mode) async {
          modos.add(mode);
          if (mode == LaunchMode.inAppBrowserView) {
            throw Exception('sem navegador interno');
          }
          return true;
        },
      );

      expect(abriu, isTrue);
      expect(modos, [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]);
    });

    test('devolve false quando nenhum navegador abre', () async {
      final bool abriu = await abrirPoliticaPrivacidade(
        launch: (Uri uri, LaunchMode mode) async => false,
      );

      expect(abriu, isFalse);
    });
  });
}
