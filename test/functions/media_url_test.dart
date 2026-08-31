import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/functions/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveMediaUrl', () {
    test('prefixa caminho relativo com o server', () {
      expect(
        resolveMediaUrl('/uploads/barbearias/abc.jpg'),
        'http://10.0.2.2:5000/uploads/barbearias/abc.jpg',
      );
    });

    test('mantém URL absoluta', () {
      expect(
        resolveMediaUrl('https://cdn.exemplo.com/logo.jpg'),
        'https://cdn.exemplo.com/logo.jpg',
      );
    });

    test('retorna nulo para vazio', () {
      expect(resolveMediaUrl(null), isNull);
      expect(resolveMediaUrl(''), isNull);
      expect(resolveMediaUrl('   '), isNull);
    });
  });

  group('gpsErrorModel', () {
    test('usa a mensagem da GpsException', () {
      const GpsException error = GpsException(gpsMensagemPermissaoNegada);

      expect(gpsErrorModel(error).tipo, 'gps');
      expect(gpsErrorModel(error).mensagem, gpsMensagemPermissaoNegada);
    });
  });
}
