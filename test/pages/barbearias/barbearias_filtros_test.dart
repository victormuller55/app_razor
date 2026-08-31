import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarbeariasFiltros', () {
    test('toQuery omite campos vazios', () {
      final Map<String, dynamic> query = BarbeariasFiltros.empty().toQuery();

      expect(query, isEmpty);
      expect(BarbeariasFiltros.empty().hasFiltros, isFalse);
    });

    test('toQuery serializa bairro, aberto, nota_minima e distancia_maxima', () {
      final BarbeariasFiltros filtros = BarbeariasFiltros(
        cidade: 'São Paulo',
        bairro: 'Centro',
        aberto: true,
        notaMinima: 4.5,
        distanciaMaxima: 12,
      );

      expect(
        filtros.toQuery(),
        <String, dynamic>{
          'cidade': 'São Paulo',
          'bairro': 'Centro',
          'aberto': true,
          'nota_minima': 4.5,
          'distancia_maxima': 12,
        },
      );
      expect(filtros.hasFiltros, isTrue);
    });

    test('toQuery ignora cidade e bairro em branco', () {
      final Map<String, dynamic> query = const BarbeariasFiltros(
        cidade: '   ',
        bairro: '',
        aberto: false,
      ).toQuery();

      expect(query.containsKey('cidade'), isFalse);
      expect(query.containsKey('bairro'), isFalse);
      expect(query.containsKey('distancia_maxima'), isFalse);
      expect(query['aberto'], isFalse);
    });

    test('fromQuery reconstrói os filtros da query', () {
      final BarbeariasFiltros filtros = BarbeariasFiltros.fromQuery(
        <String, dynamic>{
          'cidade': 'Campinas',
          'bairro': 'Cambuí',
          'aberto': 'false',
          'nota_minima': '4',
          'distancia_maxima': '8',
        },
      );

      expect(filtros.cidade, 'Campinas');
      expect(filtros.bairro, 'Cambuí');
      expect(filtros.aberto, isFalse);
      expect(filtros.notaMinima, 4);
      expect(filtros.distanciaMaxima, 8);
    });

    test('fromQuery aceita tipos nativos da API', () {
      final BarbeariasFiltros filtros = BarbeariasFiltros.fromQuery(
        <String, dynamic>{
          'aberto': true,
          'nota_minima': 3.5,
          'distancia_maxima': 20,
        },
      );

      expect(filtros.aberto, isTrue);
      expect(filtros.notaMinima, 3.5);
      expect(filtros.distanciaMaxima, 20);
      expect(filtros.cidade, isNull);
    });

    test('toQuery e fromQuery fazem round-trip', () {
      final BarbeariasFiltros original = BarbeariasFiltros(
        cidade: 'Curitiba',
        bairro: 'Batel',
        aberto: true,
        notaMinima: 4,
        distanciaMaxima: 15,
      );

      final BarbeariasFiltros copia = BarbeariasFiltros.fromQuery(
        original.toQuery(),
      );

      expect(copia.cidade, original.cidade);
      expect(copia.bairro, original.bairro);
      expect(copia.aberto, original.aberto);
      expect(copia.notaMinima, original.notaMinima);
      expect(copia.distanciaMaxima, original.distanciaMaxima);
    });
  });

  group('BarbeariasFiltrosOpcoes', () {
    test('slider de distância vai de 1 a 50 km', () {
      expect(BarbeariasFiltrosOpcoes.distanciaSliderMin, 1);
      expect(BarbeariasFiltrosOpcoes.distanciaSliderMax, 50);
      expect(
        BarbeariasFiltrosOpcoes.distanciaQueryDe(
          BarbeariasFiltrosOpcoes.distanciaSliderMax,
        ),
        50,
      );
      expect(BarbeariasFiltrosOpcoes.distanciaQueryDe(12), 12);
      expect(
        BarbeariasFiltrosOpcoes.distanciaSliderDe(null),
        BarbeariasFiltrosOpcoes.distanciaSliderMax,
      );
      expect(BarbeariasFiltrosOpcoes.rotuloDistancia(12), 'Até 12 km');
      expect(
        BarbeariasFiltrosOpcoes.rotuloDistancia(
          BarbeariasFiltrosOpcoes.distanciaSliderMax,
        ),
        'Até 50 km',
      );
    });

    test('slider de nota no mínimo não entra na query', () {
      expect(
        BarbeariasFiltrosOpcoes.notaQueryDe(
          BarbeariasFiltrosOpcoes.notaSliderMin,
        ),
        isNull,
      );
      expect(BarbeariasFiltrosOpcoes.notaQueryDe(4.5), 4.5);
      expect(
        BarbeariasFiltrosOpcoes.notaSliderDe(null),
        BarbeariasFiltrosOpcoes.notaSliderMin,
      );
      expect(BarbeariasFiltrosOpcoes.rotuloNota(4.5), 'A partir de 4,5');
      expect(BarbeariasFiltrosOpcoes.rotuloNota(0), 'Qualquer nota');
    });
  });
}
