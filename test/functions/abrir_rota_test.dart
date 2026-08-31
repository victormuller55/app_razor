import 'package:app_razor/functions/abrir_rota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('destinoRotaBarbearia', () {
    test('prioriza coordenadas', () {
      expect(
        destinoRotaBarbearia(
          latitude: -25.5921,
          longitude: -49.4102,
          endereco: 'Rua das Industrias, 820',
        ),
        '-25.592100,-49.410200',
      );
    });

    test('usa o endereço quando não há coordenadas', () {
      expect(
        destinoRotaBarbearia(endereco: '  Rua das Industrias, 820  '),
        'Rua das Industrias, 820',
      );
    });

    test('usa o nome da barbearia quando não há coordenadas nem endereço', () {
      expect(
        destinoRotaBarbearia(nome: ' Classic Fade Costeira '),
        'Classic Fade Costeira',
      );
    });

    test('retorna nulo sem destino', () {
      expect(destinoRotaBarbearia(), isNull);
      expect(destinoRotaBarbearia(endereco: '   ', nome: '  '), isNull);
    });
  });

  group('rotaBarbeariaUri', () {
    test('monta a URL do Google Maps com destino', () {
      final Uri? uri = rotaBarbeariaUri(
        latitude: -25.5921,
        longitude: -49.4102,
      );

      expect(uri, isNotNull);
      expect(uri!.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '-25.592100,-49.410200');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('monta a URL do Apple Maps', () {
      final Uri? uri = rotaBarbeariaUri(
        latitude: -25.5921,
        longitude: -49.4102,
        appleMaps: true,
      );

      expect(uri, isNotNull);
      expect(uri!.host, 'maps.apple.com');
      expect(uri.queryParameters['daddr'], '-25.592100,-49.410200');
      expect(uri.queryParameters['dirflg'], 'd');
    });
  });

  group('abrirRotaBarbearia', () {
    test('abre a URI montada', () async {
      Uri? aberta;

      await abrirRotaBarbearia(
        latitude: -25.5921,
        longitude: -49.4102,
        appleMaps: false,
        launch: (Uri uri) async {
          aberta = uri;
          return true;
        },
      );

      expect(aberta?.queryParameters['destination'], '-25.592100,-49.410200');
    });

    test('lança erro sem destino', () async {
      expect(
        () => abrirRotaBarbearia(launch: (_) async => true),
        throwsA(isA<RotaException>()),
      );
    });

    test('lança erro quando o app de mapas não abre', () async {
      expect(
        () => abrirRotaBarbearia(
          latitude: -25.5921,
          longitude: -49.4102,
          launch: (_) async => false,
        ),
        throwsA(isA<RotaException>()),
      );
    });
  });
}
