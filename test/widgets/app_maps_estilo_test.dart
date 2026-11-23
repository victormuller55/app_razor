import 'dart:convert';

import 'package:app_razor/widgets/app_maps_estilo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estilo escuro do mapa é um JSON válido do Google Maps', () {
    final List<dynamic> regras = jsonDecode(estiloMapaEscuro) as List<dynamic>;

    expect(regras, isNotEmpty);
    for (final dynamic regra in regras) {
      expect(regra, isA<Map<String, dynamic>>());
      expect((regra as Map<String, dynamic>)['stylers'], isA<List<dynamic>>());
    }
  });
}
