import 'package:app_razor/app_config/const/app_ambiente.dart';
import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_bloc.dart';
import 'package:app_razor/pages/pagamento/pagamento_event.dart';
import 'package:app_razor/pages/pagamento/pagamento_service.dart';
import 'package:app_razor/pages/pagamento/pagamento_state.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pagamento pelo app com Pix. Mostra o QR Code e o código copia e cola gerados pela API e
/// confere o status com ela enquanto o Pix está aberto (e quando o app volta para a frente).
/// Devolve true se a API confirmou o pagamento.
Future<bool> showPagamentoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
}) async {
  final int? id = agendamento.id;
  if (id == null) {
    return false;
  }

  return _abrir(
    context: context,
    descricao: agendamento.nomeServico ?? 'Serviço',
    valorPrevisto: agendamento.valorAPagar ?? agendamento.preco,
    bloc: PagamentoBloc(idAgendamento: id),
  );
}

/// Um Pix só para todos os serviços da ordem de serviço [idOrdem].
Future<bool> showPagamentoOrdemModal({
  required BuildContext context,
  required int idOrdem,
  required int servicos,
  double? valorPrevisto,
}) {
  return _abrir(
    context: context,
    descricao: servicos == 1 ? '1 serviço' : '$servicos serviços',
    valorPrevisto: valorPrevisto,
    // O bloc só repassa o id: aqui ele é o da ordem.
    bloc: PagamentoBloc(
      idAgendamento: idOrdem,
      iniciar: ({required int idAgendamento}) =>
          iniciarPagamentoOrdem(idOrdem: idAgendamento),
      consultar: ({required int idAgendamento}) =>
          consultarPagamentoOrdem(idOrdem: idAgendamento),
    ),
  );
}

Future<bool> _abrir({
  required BuildContext context,
  required String descricao,
  required double? valorPrevisto,
  required PagamentoBloc bloc,
}) async {
  final bool? pago = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) => _PagamentoSheet(
      descricao: descricao,
      valorPrevisto: valorPrevisto,
      bloc: bloc,
    ),
  );
  return pago ?? false;
}

class _PagamentoSheet extends StatefulWidget {
  const _PagamentoSheet({
    required this.descricao,
    required this.valorPrevisto,
    required this.bloc,
  });

  /// O que está sendo pago (nome do serviço ou "N serviços").
  final String descricao;

  /// Valor mostrado antes de a API devolver o da cobrança.
  final double? valorPrevisto;
  final PagamentoBloc bloc;

  @override
  State<_PagamentoSheet> createState() => _PagamentoSheetState();
}

class _PagamentoSheetState extends State<_PagamentoSheet>
    with WidgetsBindingObserver {
  PagamentoBloc get bloc => widget.bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltou do app do banco: só confere com a API, não decide nada sozinho.
    if (state == AppLifecycleState.resumed) {
      bloc.add(PagamentoRetornouEvent());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    bloc.close();
    super.dispose();
  }

  String get _valor {
    final double? valor =
        bloc.state.pagamento?.valorTotal ?? widget.valorPrevisto;
    if (valor == null) {
      return '';
    }
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _copiar(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Código Pix copiado')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagamentoBloc, PagamentoState>(
      bloc: bloc,
      builder: (BuildContext context, PagamentoState state) {
        return PopScope(
          canPop: !state.ocupado,
          child: appContainer(
            width: double.infinity,
            backgroundColor: local.AppColors.white,
            radius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 6,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.medium,
                        AppSpacing.small,
                        AppSpacing.medium,
                        AppSpacing.normal,
                      ),
                      child: _conteudo(state),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conteudo(PagamentoState state) {
    return switch (state.etapa) {
      EtapaPagamento.inicio => _tela(
        icone: Phosphor.pixLogo,
        titulo: 'Pagar com Pix',
        texto:
            '${widget.descricao} · $_valor\n'
            'Vamos gerar um QR Code Pix. Pague pelo app do seu banco, lendo o QR Code ou '
            'usando o código copia e cola.',
        acoes: [
          appElevatedButtonRazor(
            title: 'Gerar Pix',
            padding: 0,
            height: 46,
            onTap: () => bloc.add(PagamentoIniciarEvent()),
          ),
          _botaoFechar('Pagar depois'),
        ],
      ),
      EtapaPagamento.preparando => _carregando('Gerando Pix...'),
      EtapaPagamento.verificando => _carregando('Confirmando pagamento...'),
      EtapaPagamento.aguardandoPix => _pix(state),
      EtapaPagamento.processando => _tela(
        icone: Phosphor.hourglass,
        titulo: 'Pagamento em análise',
        texto:
            'O Mercado Pago está analisando o pagamento. O status aparece na sua agenda '
            'assim que for confirmado.',
        acoes: [
          appElevatedButtonRazorTransparent(
            title: 'Verificar de novo',
            padding: 0,
            height: 46,
            onTap: () => bloc.add(PagamentoConsultarEvent()),
          ),
          _botaoFechar('Fechar'),
        ],
      ),
      EtapaPagamento.aprovado => _tela(
        icone: Phosphor.checkCircle,
        cor: local.AppColors.statusAberto,
        titulo: 'Pagamento aprovado',
        texto: 'Pix de $_valor confirmado. Seu horário está garantido.',
        acoes: [_botaoFechar('Concluir', resultado: true, principal: true)],
      ),
      EtapaPagamento.recusado => _tela(
        icone: Phosphor.xCircle,
        cor: local.AppColors.danger,
        titulo: 'Pagamento não aprovado',
        texto: 'O Pix não foi aprovado. Você pode gerar um novo Pix.',
        acoes: [
          appElevatedButtonRazor(
            title: 'Gerar novo Pix',
            padding: 0,
            height: 46,
            onTap: () => bloc.add(PagamentoIniciarEvent()),
          ),
          _botaoFechar('Pagar depois'),
        ],
      ),
      EtapaPagamento.cancelado => _tela(
        icone: Phosphor.info,
        titulo: 'Pix cancelado',
        texto: 'Este Pix foi cancelado e não pode mais ser pago.',
        acoes: [_botaoFechar('Fechar', principal: true)],
      ),
      EtapaPagamento.expirado => _tela(
        icone: Phosphor.clock,
        titulo: 'Pix expirado',
        texto:
            'O prazo para pagar este Pix acabou. Gere um novo para pagar pelo app.',
        acoes: [
          appElevatedButtonRazor(
            title: 'Gerar novo Pix',
            padding: 0,
            height: 46,
            onTap: () => bloc.add(PagamentoIniciarEvent()),
          ),
          _botaoFechar('Fechar'),
        ],
      ),
      EtapaPagamento.reembolsado => _tela(
        icone: Phosphor.info,
        titulo: 'Pagamento reembolsado',
        texto: 'Este pagamento foi devolvido pelo Mercado Pago.',
        acoes: [_botaoFechar('Fechar', principal: true)],
      ),
      EtapaPagamento.erroConexao || EtapaPagamento.erro => _tela(
        icone: Phosphor.warningCircle,
        cor: local.AppColors.danger,
        titulo: state.etapa == EtapaPagamento.erroConexao
            ? 'Sem conexão'
            : 'Não foi possível gerar o Pix',
        texto: state.mensagem ?? 'Tente novamente em instantes.',
        acoes: [
          appElevatedButtonRazor(
            title: 'Tentar de novo',
            padding: 0,
            height: 46,
            onTap: () => bloc.add(
              state.pagamento == null
                  ? PagamentoIniciarEvent()
                  : PagamentoConsultarEvent(),
            ),
          ),
          _botaoFechar('Fechar'),
        ],
      ),
    };
  }

  /// QR Code e código copia e cola do Pix aberto. O status é conferido sozinho com a API.
  Widget _pix(PagamentoState state) {
    final String codigo = state.pagamento?.pixCopiaCola ?? '';
    final DateTime? expira = state.pagamento?.expiraEm;
    final String validade = expira == null
        ? ''
        : '\nVálido até ${expira.hour.toString().padLeft(2, '0')}:'
              '${expira.minute.toString().padLeft(2, '0')}.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho(Phosphor.pixLogo, 'Pague $_valor com Pix'),
        appSizedBox(height: AppSpacing.small),
        appText(
          'Leia o QR Code no app do seu banco ou copie o código.$validade',
          color: local.AppColors.textSecondary,
          fontSize: AppFontSizes.verySmall,
        ),
        appSizedBox(height: AppSpacing.normal),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: local.AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: local.AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                key: const ValueKey<String>('qr-pix'),
                data: codigo,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: local.AppColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF111111),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),
        ),
        appSizedBox(height: AppSpacing.normal),
        SelectableText(
          codigo,
          maxLines: 2,
          style: TextStyle(fontSize: 12, color: local.AppColors.textSecondary),
        ),
        appSizedBox(height: AppSpacing.normal),
        appElevatedButtonRazor(
          title: 'Copiar código Pix',
          padding: 0,
          height: 46,
          onTap: () => _copiar(codigo),
        ),
        appSizedBox(height: AppSpacing.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appLoadingRazor(size: 14),
            appSizedBox(width: AppSpacing.small),
            appText(
              'Aguardando confirmação do pagamento',
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.verySmall,
            ),
          ],
        ),
        appElevatedButtonRazorTransparent(
          title: 'Já paguei',
          padding: AppSpacing.small,
          height: 46,
          onTap: () => bloc.add(PagamentoConsultarEvent()),
        ),
        if (pixDeTeste)
          appElevatedButtonRazorTransparent(
            title: 'Simular pagamento (teste)',
            padding: AppSpacing.small,
            height: 46,
            onTap: () => bloc.add(PagamentoSimularEvent()),
          ),
        _botaoFechar('Pagar depois'),
      ],
    );
  }

  Widget _carregando(String texto) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          appLoadingRazor(size: 32),
          appSizedBox(height: AppSpacing.normal),
          appText(
            texto,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(IconData icone, String titulo, {Color? cor}) {
    return Row(
      children: [
        Icon(icone, color: cor ?? local.AppColors.primary, size: 26),
        appSizedBox(width: AppSpacing.small),
        Expanded(
          child: appText(
            titulo,
            bold: true,
            fontSize: AppFontSizes.medium,
            color: local.AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _tela({
    required IconData icone,
    required String titulo,
    required String texto,
    required List<Widget> acoes,
    Color? cor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho(icone, titulo, cor: cor),
        appSizedBox(height: AppSpacing.small),
        appText(
          texto,
          color: local.AppColors.textSecondary,
          fontSize: AppFontSizes.verySmall,
        ),
        appSizedBox(height: AppSpacing.medium),
        ...acoes,
      ],
    );
  }

  Widget _botaoFechar(
    String titulo, {
    bool resultado = false,
    bool principal = false,
  }) {
    void fechar() => Navigator.of(
      context,
    ).pop(resultado || bloc.state.etapa == EtapaPagamento.aprovado);
    if (principal) {
      return appElevatedButtonRazor(
        title: titulo,
        padding: 0,
        height: 46,
        onTap: fechar,
      );
    }
    return appElevatedButtonRazorTransparent(
      title: titulo,
      padding: AppSpacing.small,
      height: 46,
      onTap: fechar,
    );
  }
}
