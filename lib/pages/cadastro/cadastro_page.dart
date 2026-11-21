import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/cadastro/cadastro_bloc.dart';
import 'package:app_razor/pages/cadastro/cadastro_event.dart';
import 'package:app_razor/pages/cadastro/cadastro_passo.dart';
import 'package:app_razor/pages/cadastro/cadastro_state.dart';
import 'package:app_razor/pages/cadastro/widgets/cadastro_campo.dart';
import 'package:app_razor/pages/cadastro/widgets/cadastro_extras.dart';
import 'package:app_razor/pages/cadastro/widgets/cadastro_tremor.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  CadastroBloc bloc = CadastroBloc();

  CadastroPasso _passo = CadastroPasso.nome;
  bool _avancando = true;
  bool _aceitouPolitica = false;
  final Set<CadastroPasso> _tentados = {};

  final Map<CadastroPasso, GlobalKey<CadastroTremorState>> _tremores = {
    for (final passo in CadastroPasso.values) passo: GlobalKey(),
  };
  final GlobalKey<CadastroTremorState> _tremorTermos = GlobalKey();

  final Map<CadastroPasso, TextEditingController> _controllers = {
    for (final passo in CadastroPasso.values) passo: TextEditingController(),
  };
  final Map<CadastroPasso, FocusNode> _focos = {
    for (final passo in CadastroPasso.values) passo: FocusNode(),
  };

  String _texto(CadastroPasso passo) => _controllers[passo]!.text;

  String? _validar(CadastroPasso passo) {
    switch (passo) {
      case CadastroPasso.nome:
        return AppValidators.nome(_texto(passo));
      case CadastroPasso.email:
        return AppValidators.email(
          _texto(passo),
          errorMessage: AppStrings.emailInvalido,
        );
      case CadastroPasso.senha:
        return AppValidators.senhaCadastro(_texto(passo));
      case CadastroPasso.confirmacao:
        if (_texto(passo).isEmpty) return 'Confirme sua senha';
        return AppValidators.confirmacaoSenha(
          _texto(passo),
          _texto(CadastroPasso.senha),
        );
    }
  }

  bool _valido(CadastroPasso passo) => _validar(passo) == null;

  String? _erro(CadastroPasso passo) =>
      _tentados.contains(passo) ? _validar(passo) : null;

  void _focarPasso() {
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      _focos[_passo]!.requestFocus();
    });
  }

  void _irPara(CadastroPasso passo) {
    setState(() {
      _avancando = passo.indice > _passo.indice;
      _passo = passo;
    });
    _focarPasso();
  }

  void _voltar() {
    final CadastroPasso? anterior = _passo.anterior;
    if (anterior == null) {
      _openLogin();
      return;
    }
    _irPara(anterior);
  }

  void _continuar() {
    if (!_valido(_passo)) {
      setState(() => _tentados.add(_passo));
      _tremores[_passo]!.currentState?.tremer();
      return;
    }

    final CadastroPasso? proximo = _passo.proximo;
    if (proximo != null) {
      HapticFeedback.selectionClick();
      _irPara(proximo);
      return;
    }

    _saveCadastro();
  }

  void _saveCadastro() {
    if (!_aceitouPolitica) {
      _tremorTermos.currentState?.tremer();
      showSnackbarWarning(
        message: AppStrings.concordeComOsTermosDeUsoEPoliticaDePrivacidade,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    bloc.add(
      CadastroSaveEvent(
        nome: _texto(CadastroPasso.nome).trim(),
        email: _texto(CadastroPasso.email).trim(),
        senha: _texto(CadastroPasso.senha),
      ),
    );
  }

  void _openLogin() {
    open(screen: const LoginPage(), closePrevious: true);
  }

  void _selecionarEmail(String email) {
    final TextEditingController controller = _controllers[CadastroPasso.email]!;
    HapticFeedback.selectionClick();
    setState(() {
      controller.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _focarPasso();
  }

  Widget _campo(CadastroPasso passo) {
    final bool senha =
        passo == CadastroPasso.senha || passo == CadastroPasso.confirmacao;

    return CadastroTremor(
      key: _tremores[passo],
      child: CadastroCampo(
        controller: _controllers[passo]!,
        focusNode: _focos[passo]!,
        rotulo: passo.rotulo,
        hint: switch (passo) {
          CadastroPasso.nome => 'Nome e sobrenome',
          CadastroPasso.email => 'voce@email.com',
          CadastroPasso.senha => 'Mínimo 8 caracteres',
          CadastroPasso.confirmacao => 'Repita a senha',
        },
        icone: passo.icone,
        senha: senha,
        valido: _valido(passo),
        erro: _erro(passo),
        keyboardType: switch (passo) {
          CadastroPasso.nome => TextInputType.name,
          CadastroPasso.email => TextInputType.emailAddress,
          _ => TextInputType.visiblePassword,
        },
        textCapitalization: passo == CadastroPasso.nome
            ? TextCapitalization.words
            : TextCapitalization.none,
        textInputAction:
            passo.ultimo ? TextInputAction.done : TextInputAction.next,
        autofillHints: switch (passo) {
          CadastroPasso.nome => const [AutofillHints.name],
          CadastroPasso.email => const [AutofillHints.email],
          _ => const [AutofillHints.newPassword],
        },
        onChanged: (_) => setState(() {}),
        onSubmitted: _continuar,
      ),
    );
  }

  Widget _extra(CadastroPasso passo) {
    switch (passo) {
      case CadastroPasso.nome:
        return const SizedBox.shrink();
      case CadastroPasso.email:
        return CadastroSugestoesEmail(
          texto: _texto(passo),
          onSelecionar: _selecionarEmail,
        );
      case CadastroPasso.senha:
        return CadastroForcaSenha(senha: _texto(passo));
      case CadastroPasso.confirmacao:
        return CadastroTremor(
          key: _tremorTermos,
          child: CadastroTermosCard(
            aceito: _aceitouPolitica,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _aceitouPolitica = value);
            },
          ),
        );
    }
  }

  Widget _conteudoPasso(CadastroPasso passo) {
    return Column(
      key: ValueKey(passo),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CadastroEntrada(child: _campo(passo)),
        appSizedBox(height: AppSpacing.big),
        CadastroEntrada(ordem: 2, child: _extra(passo)),
      ],
    );
  }

  Widget _transicaoPasso() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (atual, anteriores) => Stack(
        alignment: Alignment.topCenter,
        children: [...anteriores, ?atual],
      ),
      transitionBuilder: (child, animation) {
        final bool entrando = child.key == ValueKey(_passo);
        final double lado = (_avancando ? 1 : -1) * (entrando ? 1 : -1);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.35 * lado, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _conteudoPasso(_passo),
    );
  }

  Widget _botaoVoltar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _voltar,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: local.AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Phosphor.arrowLeft,
          color: local.AppColors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _contadorPasso() {
    final int total = CadastroPasso.values.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: local.AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, _avancando ? 1 : -1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey(_passo),
              child: appText(
                '${_passo.indice + 1}',
                bold: true,
                fontSize: 13,
                color: local.AppColors.white,
              ),
            ),
          ),
          appText(
            ' de $total',
            fontSize: 13,
            color: local.AppColors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  /// [compacto]: com o teclado aberto o título vira uma linha só e menor, para
  /// sobrar espaço para o campo.
  Widget _tituloPasso(bool compacto) {
    final Widget titulo = AnimatedDefaultTextStyle(
      duration: _duracaoCompacto,
      curve: Curves.easeOutCubic,
      style: TextStyle(
        fontFamily: AppFonts.family,
        fontWeight: FontWeight.w800,
        fontSize: compacto ? 21 : 28,
        height: 1.12,
        color: local.AppColors.white,
      ),
      child: Text(
        compacto ? _passo.titulo.replaceAll('\n', ' ') : _passo.titulo,
        maxLines: compacto ? 1 : null,
        softWrap: !compacto,
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      layoutBuilder: (atual, anteriores) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...anteriores, ?atual],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Align(
        key: ValueKey(_passo),
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            compacto
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: titulo,
                  )
                : titulo,
            AnimatedContainer(
              duration: _duracaoCompacto,
              curve: Curves.easeOutCubic,
              height: compacto ? 4 : AppSpacing.normal,
            ),
            appText(
              _passo.subtitulo,
              fontSize: AppFontSizes.verySmall,
              color: local.AppColors.white.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }

  static const Duration _duracaoCompacto = Duration(milliseconds: 260);

  /// [compacto]: teclado aberto. O cabeçalho encolhe (espaços menores e título
  /// em uma linha) e devolve essa altura para a folha com o campo.
  Widget _cabecalho(BuildContext context, bool compacto) {
    Widget espaco(double normal, double reduzido) => AnimatedContainer(
          duration: _duracaoCompacto,
          curve: Curves.easeOutCubic,
          height: compacto ? reduzido : normal,
        );

    return AnimatedPadding(
      duration: _duracaoCompacto,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + AppSpacing.normal,
        24,
        compacto ? AppSpacing.medium : AppSpacing.big + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _botaoVoltar(),
              const Spacer(),
              _contadorPasso(),
            ],
          ),
          espaco(AppSpacing.medium + 4, AppSpacing.normal),
          CadastroProgresso(
            total: CadastroPasso.values.length,
            atual: _passo.indice,
          ),
          espaco(AppSpacing.big, AppSpacing.medium),
          AnimatedContainer(
            duration: _duracaoCompacto,
            curve: Curves.easeOutCubic,
            height: compacto ? 48 : 96,
            // Durante a animação o texto pode passar da caixa por um instante:
            // fica alinhado embaixo e cortado, sem estourar o layout.
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomLeft,
                minHeight: 0,
                maxHeight: 96,
                child: _tituloPasso(compacto),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rodape(bool carregando) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: carregando ? null : _openLogin,
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.normal + 4),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppFontSizes.verySmall + 1,
              color: local.AppColors.textSecondary,
            ),
            children: [
              TextSpan(text: '${AppStrings.jaTenhoConta}? '),
              TextSpan(
                text: 'Entrar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: local.AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [teclado] é a altura do teclado: só a área do botão sobe junto com ele,
  /// cabeçalho, folha e campo ficam parados.
  Widget _folha(bool carregando, double teclado) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: local.AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppEstilo.raioFolha),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.normal + 2),
              child: appFolhaAlca(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, teclado > 0 ? 16 : 28, 24, 16),
                child: _transicaoPasso(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 12 + teclado),
              child: Column(
                children: [
                  CadastroBotao(
                    titulo: _passo.ultimo ? 'Criar conta' : 'Continuar',
                    habilitado: _valido(_passo) &&
                        (!_passo.ultimo || _aceitouPolitica),
                    carregando: carregando,
                    onTap: _continuar,
                  ),
                  if (teclado == 0) _rodape(carregando),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroBloc, CadastroState>(
      bloc: bloc,
      builder: (context, state) {
        final bool carregando = state is CadastroLoadingState;
        final double teclado = MediaQuery.of(context).viewInsets.bottom;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !carregando) _voltar();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: local.AppColors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: local.AppColors.primary,
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          appHeaderFundo(altura: constraints.maxHeight),
                    ),
                  ),
                  Column(
                    children: [
                      _cabecalho(context, teclado > 0),
                      Expanded(child: _folha(carregando, teclado)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final foco in _focos.values) {
      foco.dispose();
    }
    bloc.close();
    super.dispose();
  }
}
