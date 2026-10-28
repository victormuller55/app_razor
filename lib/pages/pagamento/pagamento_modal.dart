import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app_razor/app_config/const/app_ambiente.dart';
import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/pagamento/pagamento_bloc.dart';
import 'package:app_razor/pages/pagamento/pagamento_event.dart';
import 'package:app_razor/pages/pagamento/pagamento_service.dart';
import 'package:app_razor/pages/pagamento/pagamento_state.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

/// Pagamento pelo app com Pix, em tela cheia. Gera o Pix ao abrir, mostra o QR Code e o código
/// copia e cola e confere o status com a API enquanto o Pix está aberto (e quando o app volta para
/// a frente). Devolve true se a API confirmou o pagamento.
Future<bool> showPagamentoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
}) async {
  final int? id = agendamento.id;
  if (id == null) {
    return false;
  }

  return abrirPagamentoPix(
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
  return abrirPagamentoPix(
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

/// Abre a tela do Pix com um [bloc] já montado (os testes passam um com a API falsa).
@visibleForTesting
Future<bool> abrirPagamentoPix({
  required BuildContext context,
  required String descricao,
  required double? valorPrevisto,
  required PagamentoBloc bloc,
}) async {
  final bool? pago = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (BuildContext pageContext) => _PagamentoPixPage(
        descricao: descricao,
        valorPrevisto: valorPrevisto,
        bloc: bloc,
      ),
    ),
  );
  // Voltar pela seta também conta como pago se a API já tinha confirmado.
  return pago ?? bloc.state.etapa == EtapaPagamento.aprovado;
}

/// Verde oficial do Pix.
const Color _corPix = Color(0xFF32BCAD);

/// O que o círculo do topo mostra.
enum _Indicador { aguardando, aprovado, alerta, neutro }

class _PagamentoPixPage extends StatefulWidget {
  const _PagamentoPixPage({
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
  State<_PagamentoPixPage> createState() => _PagamentoPixPageState();
}

class _PagamentoPixPageState extends State<_PagamentoPixPage>
    with WidgetsBindingObserver {
  PagamentoBloc get bloc => widget.bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // O cliente já escolheu pagar com Pix: gera direto, sem outro toque.
    if (bloc.state.etapa == EtapaPagamento.inicio) {
      bloc.add(PagamentoIniciarEvent());
    }
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
    return BlocConsumer<PagamentoBloc, PagamentoState>(
      bloc: bloc,
      listenWhen: (PagamentoState antes, PagamentoState depois) =>
          antes.etapa != depois.etapa &&
          depois.etapa == EtapaPagamento.aprovado,
      listener: (BuildContext context, PagamentoState state) =>
          HapticFeedback.mediumImpact(),
      builder: (BuildContext context, PagamentoState state) {
        final (Widget? principal, Widget? secundario, Widget? terciario) =
            _acoes(state);
        // Tudo tem lugar fixo: trocar de etapa só troca o conteúdo, nada muda de posição.
        return PopScope(
          canPop: !state.ocupado,
          child: scaffold(
            title: 'Pagamento',
            centerTitle: true,
            background: local.AppColors.surface,
            appBarColor: local.AppColors.primaryBrand,
            actions: [
              if (pixDeTeste && state.etapa == EtapaPagamento.aguardandoPix)
                TextButton(
                  onPressed: () => bloc.add(PagamentoSimularEvent()),
                  child: appText(
                    'Simular',
                    bold: true,
                    color: local.AppColors.white,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ),
            ],
            body: SafeArea(
              top: false,
              // Um bloco só, centralizado na tela: círculo, texto, detalhe e botões. Cada parte
              // tem altura fixa, então trocar de etapa não move nada.
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints limites) =>
                    SingleChildScrollView(
                      // As ondas e o confete do check passam da borda do círculo.
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: limites.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IndicadorPagamento(indicador: _indicador(state)),
                              appSizedBox(height: AppSpacing.big),
                              _titulo(state),
                              appSizedBox(height: AppSpacing.normal),
                              _detalhe(state),
                              appSizedBox(height: AppSpacing.medium),
                              _slot(principal),
                              _slot(secundario),
                              _slot(terciario),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  _Indicador _indicador(PagamentoState state) {
    return switch (state.etapa) {
      EtapaPagamento.aprovado => _Indicador.aprovado,
      EtapaPagamento.recusado ||
      EtapaPagamento.erro ||
      EtapaPagamento.erroConexao => _Indicador.alerta,
      EtapaPagamento.cancelado ||
      EtapaPagamento.expirado ||
      EtapaPagamento.reembolsado => _Indicador.neutro,
      _ => _Indicador.aguardando,
    };
  }

  String get _validade {
    final DateTime? expira = bloc.state.pagamento?.expiraEm;
    if (expira == null) {
      return '';
    }
    return ' Válido até ${expira.hour.toString().padLeft(2, '0')}:'
        '${expira.minute.toString().padLeft(2, '0')}.';
  }

  /// Título e explicação do momento do pagamento, num bloco de altura fixa.
  Widget _titulo(PagamentoState state) {
    final (String titulo, String texto) = switch (state.etapa) {
      EtapaPagamento.inicio ||
      EtapaPagamento.preparando => ('Gerando seu Pix', 'Só um instante...'),
      EtapaPagamento.aguardandoPix => (
        'Aguardando pagamento',
        'Copie o código e pague no app do seu banco. Esta tela atualiza sozinha.$_validade',
      ),
      EtapaPagamento.verificando => (
        'Confirmando pagamento',
        'Conferindo o Pix com o banco...',
      ),
      EtapaPagamento.processando => (
        'Pagamento em análise',
        'O Mercado Pago está analisando o pagamento. O status aparece na sua agenda.',
      ),
      EtapaPagamento.aprovado => (
        'Pagamento confirmado!',
        'Tudo certo! Seu horário está garantido.',
      ),
      EtapaPagamento.recusado => (
        'Pagamento não aprovado',
        'O Pix não foi aprovado. Você pode gerar um novo Pix.',
      ),
      EtapaPagamento.cancelado => (
        'Pix cancelado',
        'Este Pix foi cancelado e não pode mais ser pago.',
      ),
      EtapaPagamento.expirado => (
        'Pix expirado',
        'O prazo para pagar este Pix acabou. Gere um novo para pagar pelo app.',
      ),
      EtapaPagamento.reembolsado => (
        'Pagamento reembolsado',
        'Este pagamento foi devolvido pelo Mercado Pago.',
      ),
      EtapaPagamento.erroConexao => (
        'Sem conexão',
        state.mensagem ?? 'Tente novamente em instantes.',
      ),
      EtapaPagamento.erro => (
        'Não foi possível gerar o Pix',
        state.mensagem ?? 'Tente novamente em instantes.',
      ),
    };
    return SizedBox(
      height: 88,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: (Widget? atual, List<Widget> anteriores) => Stack(
          alignment: Alignment.topCenter,
          children: [...anteriores, ?atual],
        ),
        child: Column(
          key: ValueKey<String>(titulo),
          children: [
            appText(
              titulo,
              bold: true,
              fontSize: AppFontSizes.big,
              color: local.AppColors.text,
              textAlign: TextAlign.center,
            ),
            appSizedBox(height: AppSpacing.small),
            // Cabe sempre na altura fixa do bloco: texto longo vira reticências.
            Flexible(
              child: Text(
                texto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: local.AppColors.textSecondary,
                  fontSize: AppFontSizes.verySmall,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valorPill() {
    return appContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      backgroundColor: local.AppColors.background,
      radius: BorderRadius.circular(20),
      child: appText(
        _valor.isEmpty ? widget.descricao : '${widget.descricao} · $_valor',
        bold: true,
        color: local.AppColors.primary,
        fontSize: AppFontSizes.verySmall,
      ),
    );
  }

  /// Enquanto não pagou (ou se o Pix não deu certo), lembra que dá para pagar na barbearia.
  bool _mostraAvisoNoLocal(PagamentoState state) {
    return switch (state.etapa) {
      EtapaPagamento.aprovado ||
      EtapaPagamento.reembolsado ||
      EtapaPagamento.processando => false,
      _ => true,
    };
  }

  Widget _avisoPagarNoLocal() {
    return appContainer(
      padding: EdgeInsets.all(AppSpacing.normal),
      backgroundColor: local.AppColors.background,
      radius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Phosphor.storefront, color: local.AppColors.primary, size: 22),
          appSizedBox(width: AppSpacing.small + 2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  'Não vai pagar o Pix agora?',
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.verySmall,
                ),
                appSizedBox(height: 4),
                // Encolhe com reticências se a fonte do aparelho for grande.
                Flexible(
                  child: appText(
                    'Sem problema: seu horário continua reservado. É só pagar em dinheiro '
                    'ou Pix na barbearia, na hora do serviço.',
                    color: local.AppColors.textSecondary,
                    fontSize: AppFontSizes.verySmall,
                    maxLines: 4,
                    overflow: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Espaço fixo embaixo do título: o valor e o aviso de pagar na barbearia enquanto não pagou,
  /// o comprovante depois. Trocar um pelo outro não mexe no check nem nos botões.
  Widget _detalhe(PagamentoState state) {
    final Widget conteudo = state.etapa == EtapaPagamento.aprovado
        ? _comprovante(state)
        : Column(
            key: ValueKey<bool>(_mostraAvisoNoLocal(state)),
            children: [
              _valorPill(),
              if (_mostraAvisoNoLocal(state)) ...[
                appSizedBox(height: AppSpacing.medium),
                Flexible(child: _avisoPagarNoLocal()),
              ],
            ],
          );
    return SizedBox(
      height: 164,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
        layoutBuilder: (Widget? atual, List<Widget> anteriores) => Stack(
          alignment: Alignment.topCenter,
          children: [...anteriores, ?atual],
        ),
        child: conteudo,
      ),
    );
  }

  /// Comprovante do Pix confirmado, no formato de um ticket.
  Widget _comprovante(PagamentoState state) {
    final DateTime quando = state.pagamento?.dataConfirmacao ?? DateTime.now();
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final String data =
        '${doisDigitos(quando.day)}/${doisDigitos(quando.month)} às '
        '${doisDigitos(quando.hour)}:${doisDigitos(quando.minute)}';

    Widget linha(String rotulo, String valor, {bool destaque = false}) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            appText(
              rotulo,
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.verySmall,
            ),
            appSizedBox(width: AppSpacing.normal),
            Expanded(
              child: appText(
                valor,
                bold: true,
                color: destaque
                    ? local.AppColors.statusAberto
                    : local.AppColors.text,
                fontSize: destaque
                    ? AppFontSizes.small
                    : AppFontSizes.verySmall,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: true,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey<String>('comprovante'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal + 4,
        AppSpacing.medium,
        AppSpacing.normal + 4,
      ),
      decoration: BoxDecoration(
        color: local.AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: local.AppColors.border),
        boxShadow: [
          BoxShadow(
            color: local.AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(PhosphorFill.pixLogo, color: _corPix, size: 20),
              appSizedBox(width: AppSpacing.small + 2),
              Expanded(
                child: appText(
                  'Comprovante Pix',
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.small,
                  maxLines: 1,
                  overflow: true,
                ),
              ),
              appContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                backgroundColor: local.AppColors.statusAberto.withValues(
                  alpha: 0.12,
                ),
                radius: BorderRadius.circular(20),
                child: appText(
                  'PAGO',
                  bold: true,
                  color: local.AppColors.statusAberto,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _TracejadoPainter(cor: local.AppColors.border),
            ),
          ),
          linha('Serviço', widget.descricao),
          linha('Pago em', data),
          linha('Valor', _valor, destaque: true),
        ],
      ),
    );
  }

  /// Lugar fixo de um botão; vazio, guarda a altura.
  Widget _slot(Widget? botao) {
    return SizedBox(
      height: 46 + AppSpacing.small * 2,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              botao ??
              const SizedBox(key: ValueKey<String>('vazio'), height: 46),
        ),
      ),
    );
  }

  /// Até três botões, sempre nos mesmos lugares (o principal em cima).
  (Widget?, Widget?, Widget?) _acoes(PagamentoState state) {
    final String codigo = state.pagamento?.pixCopiaCola ?? '';
    final Widget pagarNoLocal = _botaoFechar('Pagar na hora do serviço');
    return switch (state.etapa) {
      EtapaPagamento.inicio ||
      EtapaPagamento.preparando ||
      EtapaPagamento.verificando => (null, null, pagarNoLocal),
      EtapaPagamento.aguardandoPix => (
        _botao(
          'Copiar código Pix',
          principal: true,
          onTap: () => _copiar(codigo),
        ),
        _botao('Já paguei', onTap: () => bloc.add(PagamentoConsultarEvent())),
        pagarNoLocal,
      ),
      EtapaPagamento.processando => (
        _botao(
          'Verificar de novo',
          principal: true,
          onTap: () => bloc.add(PagamentoConsultarEvent()),
        ),
        null,
        _botaoFechar('Fechar'),
      ),
      EtapaPagamento.aprovado => (
        _botaoFechar('Concluir', resultado: true, principal: true),
        null,
        null,
      ),
      EtapaPagamento.recusado || EtapaPagamento.expirado => (
        _botao(
          'Gerar novo Pix',
          principal: true,
          onTap: () => bloc.add(PagamentoIniciarEvent()),
        ),
        null,
        pagarNoLocal,
      ),
      EtapaPagamento.cancelado || EtapaPagamento.reembolsado => (
        _botaoFechar('Fechar', principal: true),
        null,
        null,
      ),
      EtapaPagamento.erroConexao || EtapaPagamento.erro => (
        _botao(
          'Tentar de novo',
          principal: true,
          onTap: () => bloc.add(
            state.pagamento == null
                ? PagamentoIniciarEvent()
                : PagamentoConsultarEvent(),
          ),
        ),
        null,
        pagarNoLocal,
      ),
    };
  }

  Widget _botao(
    String titulo, {
    required VoidCallback onTap,
    bool principal = false,
    Color? cor,
  }) {
    return KeyedSubtree(
      key: ValueKey<String>(titulo),
      child: principal
          ? appElevatedButtonRazor(
              title: titulo,
              padding: 0,
              height: 46,
              width: double.infinity,
              color: cor,
              onTap: onTap,
            )
          : appElevatedButtonRazorTransparent(
              title: titulo,
              padding: 0,
              height: 46,
              width: double.infinity,
              onTap: onTap,
            ),
    );
  }

  Widget _botaoFechar(
    String titulo, {
    bool resultado = false,
    bool principal = false,
  }) {
    return _botao(
      titulo,
      principal: principal,
      cor: principal && resultado ? local.AppColors.statusAberto : null,
      onTap: () => Navigator.of(
        context,
      ).pop(resultado || bloc.state.etapa == EtapaPagamento.aprovado),
    );
  }
}

/// Círculo do topo: gira enquanto espera o pagamento e vira um check quando a API confirma.
class _IndicadorPagamento extends StatefulWidget {
  const _IndicadorPagamento({required this.indicador});

  final _Indicador indicador;

  @override
  State<_IndicadorPagamento> createState() => _IndicadorPagamentoState();
}

class _IndicadorPagamentoState extends State<_IndicadorPagamento>
    with TickerProviderStateMixin {
  static const double _tamanho = 112;

  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Comemoração do pagamento: o check se desenha, as ondas abrem e o confete voa.
  late final AnimationController _festa = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _sincronizarGiro();
    if (widget.indicador == _Indicador.aprovado) {
      _festa.forward();
    }
  }

  @override
  void didUpdateWidget(_IndicadorPagamento antigo) {
    super.didUpdateWidget(antigo);
    _sincronizarGiro();
    if (widget.indicador == _Indicador.aprovado &&
        antigo.indicador != _Indicador.aprovado) {
      _festa.forward(from: 0);
    }
  }

  void _sincronizarGiro() {
    if (widget.indicador == _Indicador.aguardando) {
      if (!_giro.isAnimating) {
        _giro.repeat();
      }
    } else {
      _giro.stop();
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    _festa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _tamanho,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
            ),
        child: switch (widget.indicador) {
          _Indicador.aguardando => _aguardando(),
          _Indicador.aprovado => _aprovado(),
          _Indicador.alerta => _circulo(
            key: 'alerta',
            fundo: local.AppColors.danger.withValues(alpha: 0.1),
            icone: Phosphor.warningCircle,
            corIcone: local.AppColors.danger,
          ),
          _Indicador.neutro => _circulo(
            key: 'neutro',
            fundo: local.AppColors.background,
            icone: Phosphor.info,
            corIcone: local.AppColors.textSecondary,
          ),
        },
      ),
    );
  }

  Widget _aguardando() {
    return Stack(
      key: const ValueKey<String>('aguardando'),
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(_tamanho),
          painter: _AnelPainter(
            cor: local.AppColors.primary.withValues(alpha: 0.1),
            inicio: 0,
            arco: 2 * math.pi,
          ),
        ),
        RotationTransition(
          turns: _giro,
          child: CustomPaint(
            size: const Size.square(_tamanho),
            painter: _AnelPainter(
              cor: local.AppColors.primary,
              inicio: -math.pi / 2,
              arco: math.pi * 0.55,
            ),
          ),
        ),
        Container(
          width: _tamanho - 30,
          height: _tamanho - 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _corPix.withValues(alpha: 0.1),
          ),
          child: const Icon(PhosphorFill.pixLogo, color: _corPix, size: 44),
        ),
      ],
    );
  }

  /// Círculo verde com o check desenhado no meio, ondas e confete em volta.
  Widget _aprovado() {
    return AnimatedBuilder(
      key: const ValueKey<String>('aprovado'),
      animation: _festa,
      builder: (BuildContext context, Widget? child) {
        final double t = _festa.value;
        return CustomPaint(
          // Pintado fora da caixa do círculo: as ondas e o confete passam da borda.
          painter: _FestaPainter(progresso: t),
          child: Container(
            width: _tamanho,
            height: _tamanho,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1FA055), Color(0xFF157A3F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: local.AppColors.statusAberto.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CheckPainter(
                progresso: Curves.easeOutCubic.transform(
                  const Interval(0.12, 0.5).transform(t),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circulo({
    required String key,
    required Color fundo,
    required IconData icone,
    required Color corIcone,
    bool sombra = false,
  }) {
    return Container(
      key: ValueKey<String>(key),
      width: _tamanho,
      height: _tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fundo,
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: fundo.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(icone, color: corIcone, size: 60),
    );
  }
}

/// Check branco que se desenha da ponta curta para a longa.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progresso});

  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    if (progresso <= 0) {
      return;
    }
    final Path check = Path()
      ..moveTo(size.width * 0.30, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.38);
    final Path desenhado = Path();
    for (final ui.PathMetric parte in check.computeMetrics()) {
      desenhado.addPath(
        parte.extractPath(0, parte.length * progresso),
        Offset.zero,
      );
    }
    canvas.drawPath(
      desenhado,
      Paint()
        ..color = local.AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.075
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter antigo) => antigo.progresso != progresso;
}

/// Duas ondas que abrem a partir do círculo e confete que voa para fora e some.
class _FestaPainter extends CustomPainter {
  _FestaPainter({required this.progresso});

  final double progresso;

  static const List<Color> _cores = [
    Color(0xFF157A3F),
    _corPix,
    Color(0xFFF2B33D),
    local.AppColors.primaryLight,
  ];
  static const int _pedacos = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (progresso <= 0 || progresso >= 1) {
      return;
    }
    final Offset centro = size.center(Offset.zero);
    final double raio = size.width / 2;

    for (final double atraso in const [0.0, 0.18]) {
      final double t = const Interval(
        0,
        0.75,
      ).transform(((progresso - atraso) / (1 - atraso)).clamp(0, 1));
      if (t <= 0 || t >= 1) {
        continue;
      }
      canvas.drawCircle(
        centro,
        raio + Curves.easeOutCubic.transform(t) * 44,
        Paint()
          ..color = local.AppColors.statusAberto.withValues(
            alpha: (1 - t) * 0.28,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - t) + 1,
      );
    }

    final double voo = Curves.easeOutQuart.transform(
      const Interval(0.08, 0.85).transform(progresso),
    );
    final double some = 1 - const Interval(0.55, 1).transform(progresso);
    if (voo <= 0 || some <= 0) {
      return;
    }
    for (int i = 0; i < _pedacos; i++) {
      final double angulo =
          (i / _pedacos) * 2 * math.pi + (i.isEven ? 0.12 : -0.08);
      final double distancia = raio + 10 + voo * (i.isEven ? 52 : 38);
      final Offset ponto =
          centro + Offset(math.cos(angulo), math.sin(angulo)) * distancia;
      final Paint tinta = Paint()
        ..color = _cores[i % _cores.length].withValues(alpha: some);
      if (i % 3 == 0) {
        canvas.drawCircle(ponto, 3.5, tinta);
      } else {
        canvas.save();
        canvas.translate(ponto.dx, ponto.dy);
        canvas.rotate(angulo + voo * math.pi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -2, 10, 4),
            const Radius.circular(2),
          ),
          tinta,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_FestaPainter antigo) => antigo.progresso != progresso;
}

/// Linha tracejada que separa o cabeçalho do comprovante.
class _TracejadoPainter extends CustomPainter {
  _TracejadoPainter({required this.cor});

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint tinta = Paint()
      ..color = cor
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 5, size.width), 0),
        tinta,
      );
    }
  }

  @override
  bool shouldRepaint(_TracejadoPainter antigo) => antigo.cor != cor;
}

/// Arco (ou anel inteiro) do indicador de espera.
class _AnelPainter extends CustomPainter {
  _AnelPainter({required this.cor, required this.inicio, required this.arco});

  final Color cor;
  final double inicio;
  final double arco;
  static const double _espessura = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    canvas.drawArc(
      area.deflate(_espessura / 2),
      inicio,
      arco,
      false,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _espessura
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnelPainter antigo) =>
      antigo.cor != cor || antigo.inicio != inicio || antigo.arco != arco;
}
