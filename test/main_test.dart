import 'dart:async';

import 'package:app_razor/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> capturar(bool producao) {
    final List<String> linhas = <String>[];
    runZoned(
      // ignore: avoid_print
      () => silenciarPrintsEmProducao(() => print('[200] - BODY: {"token":"jwt-secreto"}'), producao: producao),
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String linha) => linhas.add(linha),
      ),
    );
    return linhas;
  }

  test('na versão de loja o corpo das respostas (com token) não vai para o log', () {
    expect(capturar(true), isEmpty);
  });

  test('em desenvolvimento os prints continuam aparecendo', () {
    expect(capturar(false), hasLength(1));
  });
}
