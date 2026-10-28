import 'package:app_razor/pages/pagamento/pagamento_bloc.dart';
import 'package:app_razor/pages/pagamento/pagamento_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muller_package/muller_package.dart';

void main() {
  const String pix = '00020126580014br.gov.bcb.pix0136teste5204000053039865802BR6304ABCD';

  AppResponse resposta(String status, {String? codigo}) {
    return AppResponse(
      statusCode: 200,
      body:
          '{"id": 1, "id_agendamento": 7, "status": "$status", "valor_total": 1.0'
          '${codigo != null ? ', "pix_copia_cola": "$codigo"' : ''}}',
    );
  }

  testWidgets('gera o Pix ao abrir, gira esperando e vira check sem mudar nada de lugar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String consulta = 'PENDENTE';
    final PagamentoBloc bloc = PagamentoBloc(
      idAgendamento: 7,
      intervaloConsulta: const Duration(hours: 1),
      iniciar: ({required int idAgendamento}) async => resposta('PENDENTE', codigo: pix),
      consultar: ({required int idAgendamento}) async =>
          resposta(consulta, codigo: consulta == 'PENDENTE' ? pix : null),
      simular: ({required int idPagamento}) async {
        consulta = 'APROVADO';
        return AppResponse(statusCode: 204, body: '');
      },
    );
    bool? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              resultado = await abrirPagamentoPix(
                context: context,
                descricao: 'Barba',
                valorPrevisto: 1,
                bloc: bloc,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Aguardando pagamento'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('qr-pix')), findsNothing);
    expect(find.byKey(const ValueKey<String>('aguardando')), findsOneWidget);
    expect(find.text('COPIAR CÓDIGO PIX'), findsOneWidget);
    expect(find.textContaining('dinheiro ou Pix na barbearia'), findsOneWidget);
    final Offset indicadorAntes = tester.getCenter(find.byKey(const ValueKey<String>('aguardando')));
    final Offset botaoAntes = tester.getCenter(find.text('COPIAR CÓDIGO PIX'));
    // Botões ocupam a largura toda (390 menos as margens de 20), não só o texto.
    for (final String botao in <String>['COPIAR CÓDIGO PIX', 'JÁ PAGUEI', 'PAGAR NA HORA DO SERVIÇO']) {
      expect(tester.getSize(find.ancestor(of: find.text(botao), matching: find.byType(LayoutBuilder)).first).width, 350);
    }

    await tester.tap(find.text('Simular'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Pagamento confirmado!'), findsOneWidget);
    expect(find.text('Comprovante Pix'), findsOneWidget);
    expect(find.text('PAGO'), findsOneWidget);
    expect(find.textContaining('dinheiro ou Pix na barbearia'), findsNothing);
    // O check aparece onde estava o círculo girando e o botão principal fica no mesmo lugar.
    expect(tester.getCenter(find.byKey(const ValueKey<String>('aprovado'))), indicadorAntes);
    expect(tester.getCenter(find.text('CONCLUIR')), botaoAntes);

    await tester.tap(find.text('CONCLUIR'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
  });
}
