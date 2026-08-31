import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/pages/home/widgets/home_favorita_card.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homeTextoDistanciaKm', () {
    test('retorna nulo quando a distância é nula', () {
      expect(homeTextoDistanciaKm(null), isNull);
    });

    test('não converte nulo em 0,0 km', () {
      expect(homeTextoDistanciaKm(null), isNot('0,0 km'));
    });

    test('formata distância com vírgula', () {
      expect(homeTextoDistanciaKm(1.23), '1,2 km');
      expect(homeTextoDistanciaKm(0), '0,0 km');
    });
  });

  group('homeNotaDistancia', () {
    testWidgets('oculta pin e km quando distanciaKm é nula', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeNotaDistancia(
              barbearia: BarbeariaModel(nome: 'Razor', nota: 4.5),
            ),
          ),
        ),
      );

      expect(find.text('0,0 km'), findsNothing);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('mostra km quando distanciaKm existe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeNotaDistancia(
              barbearia: BarbeariaModel(
                nome: 'Razor',
                nota: 4.5,
                distanciaKm: 1.2,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1,2 km'), findsOneWidget);
    });
  });

  group('homeFavoritaCard', () {
    testWidgets('oculta km quando distanciaKm é nula', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeFavoritaCard(
              barbearia: BarbeariaModel(nome: 'Razor', nota: 4.8),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('0,0 km'), findsNothing);
      expect(find.textContaining('km'), findsNothing);
    });
  });

  group('homeProximaCard', () {
    testWidgets('oculta km quando distanciaKm é nula', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeProximaCard(
              barbearia: BarbeariaModel(nome: 'Razor', nota: 4.3),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('0,0 km'), findsNothing);
      expect(find.textContaining('km'), findsNothing);
    });
  });
}
