import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:app_razor/pages/home/home_state.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeState.todasSecoesVazias', () {
    test('é verdadeiro só quando as três seções vieram vazias', () {
      final HomeState vazio = HomeSuccessState(
        favoritas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        proximas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        promocoes: HomeSecao<PromocaoModel>.success(const <PromocaoModel>[]),
      );

      expect(vazio.todasSecoesVazias, isTrue);
    });

    test('é falso quando alguma seção ainda carrega', () {
      final HomeState carregando = HomeSuccessState(
        favoritas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        proximas: HomeSecao<BarbeariaModel>.loading(),
        promocoes: HomeSecao<PromocaoModel>.success(const <PromocaoModel>[]),
      );

      expect(carregando.todasSecoesVazias, isFalse);
      expect(carregando.carregando, isTrue);
    });

    test('carregando é falso quando as três seções já responderam', () {
      final HomeState pronto = HomeSuccessState(
        favoritas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        proximas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        promocoes: HomeSecao<PromocaoModel>.success(const <PromocaoModel>[]),
      );

      expect(pronto.carregando, isFalse);
    });

    test('é falso quando alguma seção tem item', () {
      final HomeState comFavorita = HomeSuccessState(
        favoritas: HomeSecao<BarbeariaModel>.success(
          <BarbeariaModel>[BarbeariaModel(nome: 'Razor')],
        ),
        proximas: HomeSecao<BarbeariaModel>.success(const <BarbeariaModel>[]),
        promocoes: HomeSecao<PromocaoModel>.success(const <PromocaoModel>[]),
      );

      expect(comFavorita.todasSecoesVazias, isFalse);
    });
  });

  group('homeEmptyState', () {
    testWidgets('mostra só o texto centralizado, sem ícone', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeEmptyState(message: 'Nenhuma barbearia favorita'),
          ),
        ),
      );

      expect(find.text('Nenhuma barbearia favorita'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('homeEmptyStateCentral', () {
    testWidgets('mostra a mensagem central sem ícone de seção', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: homeEmptyStateCentral(
              message: homeMensagemSemBarbeariasProximas,
              height: 240,
            ),
          ),
        ),
      );

      expect(find.text(homeMensagemSemBarbeariasProximas), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
