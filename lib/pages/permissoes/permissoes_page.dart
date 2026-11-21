import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/menu/menu.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/permissoes/widgets/permissoes_animacao.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Tela exibida após o login (e na abertura do app, se a localização não
/// estiver liberada). Pede uma permissão por vez, só as que ainda faltam; todas
/// são opcionais e "Agora não" segue para a próxima.
class PermissoesPage extends StatefulWidget {
  const PermissoesPage({super.key});

  @override
  State<PermissoesPage> createState() => _PermissoesPageState();
}

class _PermissoesPageState extends State<PermissoesPage>
    with WidgetsBindingObserver {
  /// Só as que ainda não estavam liberadas ao abrir a tela; null enquanto lê.
  List<PermissaoApp>? _passos;
  int _indice = 0;
  PermissaoStatus? _status;
  bool _pedindo = false;
  bool _concedida = false;
  bool _saindo = false;

  PermissaoApp get _atual => _passos![_indice];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregar();
  }

  Future<void> _carregar() async {
    final List<PermissaoApp> faltando = <PermissaoApp>[];
    for (final PermissaoApp permissao in permissoesDoApp()) {
      if (await statusPermissao(permissao) != PermissaoStatus.concedida) {
        faltando.add(permissao);
      }
    }

    if (!mounted) return;
    if (faltando.isEmpty) {
      _continuar();
      return;
    }

    _passos = faltando;
    await _lerStatusAtual();
  }

  Future<void> _lerStatusAtual() async {
    final PermissaoStatus status = await statusPermissao(_atual);
    if (mounted) setState(() => _status = status);
  }

  // Ao voltar dos Ajustes, relê o que o usuário liberou por lá.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _passos == null || _concedida) {
      return;
    }
    statusPermissao(_atual).then((PermissaoStatus status) {
      if (!mounted) return;
      if (status == PermissaoStatus.concedida) {
        _marcarConcedida();
      } else {
        setState(() => _status = status);
      }
    });
  }

  Future<void> _permitir() async {
    if (_pedindo || _concedida || _status == null) return;

    if (_status == PermissaoStatus.bloqueada) {
      await abrirAjustesDoApp();
      return;
    }

    setState(() => _pedindo = true);
    final PermissaoStatus status = await pedirPermissao(_atual);
    if (!mounted) return;
    setState(() => _pedindo = false);

    if (status == PermissaoStatus.concedida) {
      _marcarConcedida();
    } else if (status == PermissaoStatus.bloqueada) {
      // Negou de vez (ou já estava negada): o botão passa a abrir os ajustes.
      setState(() => _status = status);
    } else {
      _proximo();
    }
  }

  /// Mostra o "Permitido" por um instante antes de ir para a próxima.
  Future<void> _marcarConcedida() async {
    HapticFeedback.lightImpact();
    setState(() => _concedida = true);
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (mounted) _proximo();
  }

  void _proximo() {
    if (_indice >= _passos!.length - 1) {
      _continuar();
      return;
    }
    setState(() {
      _indice++;
      _status = null;
      _concedida = false;
    });
    _lerStatusAtual();
  }

  void _continuar() {
    if (_saindo) return;
    _saindo = true;
    open(screen: const MenuScreen(), closePrevious: true);
  }

  Future<void> _sair() async {
    await sairDaConta();
    open(screen: const LoginPage(), closePrevious: true);
  }

  String _titulo(PermissaoApp permissao) {
    switch (permissao) {
      case PermissaoApp.localizacao:
        return 'Barbearias perto de você';
      case PermissaoApp.camera:
        return 'Sua foto de perfil';
      case PermissaoApp.galeria:
        return 'Fotos da galeria';
      case PermissaoApp.notificacoes:
        return 'Não perca seu horário';
    }
  }

  String _descricao(PermissaoApp permissao) {
    switch (permissao) {
      case PermissaoApp.localizacao:
        return 'Com a sua localização, mostramos as barbearias mais próximas e a distância até cada uma. Sem ela, você ainda busca por nome, serviço ou cidade.';
      case PermissaoApp.camera:
        return 'Use a câmera para tirar a foto do seu perfil. Ela só é usada quando você escolher trocar a foto.';
      case PermissaoApp.galeria:
        return 'Permita o acesso às fotos para escolher a imagem do seu perfil direto da galeria.';
      case PermissaoApp.notificacoes:
        return 'Avisamos 1 hora antes do atendimento e quando seu horário for confirmado, alterado ou cancelado.';
    }
  }

  String _botao(PermissaoApp permissao) {
    if (_status == PermissaoStatus.bloqueada) return 'Abrir ajustes';
    switch (permissao) {
      case PermissaoApp.localizacao:
        return 'Permitir localização';
      case PermissaoApp.camera:
        return 'Permitir câmera';
      case PermissaoApp.galeria:
        return 'Permitir acesso às fotos';
      case PermissaoApp.notificacoes:
        return 'Ativar avisos';
    }
  }

  Widget _progresso() {
    final int total = _passos!.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _indice ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= _indice
                  ? local.AppColors.primary
                  : local.AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }

  Widget _topo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.small,
        0,
      ),
      child: Row(
        children: [
          if (_passos!.length > 1) _progresso(),
          const Spacer(),
          TextButton(
            onPressed: _sair,
            style: TextButton.styleFrom(
              foregroundColor: local.AppColors.textSecondary,
            ),
            child: appText(
              'Sair',
              bold: true,
              fontSize: AppFontSizes.verySmall + 1,
              color: local.AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoPasso(PermissaoApp permissao) {
    return Column(
      key: ValueKey(permissao),
      mainAxisSize: MainAxisSize.min,
      children: [
        PermissaoAnimacao(permissao: permissao),
        appSizedBox(height: AppSpacing.big),
        Text(
          _titulo(permissao),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontWeight: FontWeight.w800,
            fontSize: 26,
            height: 1.15,
            color: local.AppColors.text,
          ),
        ),
        appSizedBox(height: AppSpacing.normal),
        appText(
          _descricao(permissao),
          fontSize: AppFontSizes.small,
          color: local.AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _conteudo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool entrando = child.key == ValueKey(_atual);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(entrando ? 0.3 : -0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _conteudoPasso(_atual),
    );
  }

  Widget _botaoPrincipal() {
    final bool pronto = _status != null && !_pedindo;
    final Color cor = _concedida ? local.AppColors.statusAberto : local.AppColors.primary;

    final Widget rotulo = _concedida
        ? Row(
            key: const ValueKey('ok'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorFill.checkCircle, color: local.AppColors.white, size: 22),
              appSizedBox(width: 8),
              appText('PERMITIDO', bold: true, color: local.AppColors.white, letterSpacing: 0.4),
            ],
          )
        : _pedindo
            ? SizedBox(
                key: const ValueKey('carregando'),
                height: 22,
                child: appLoadingRazor(color: local.AppColors.white, size: 22),
              )
            : Row(
                key: ValueKey(_botao(_atual)),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_status == PermissaoStatus.bloqueada) ...[
                    const Icon(Phosphor.gear, color: local.AppColors.white, size: 20),
                    appSizedBox(width: 8),
                  ],
                  appText(
                    _botao(_atual).toUpperCase(),
                    bold: true,
                    color: local.AppColors.white,
                    letterSpacing: 0.4,
                  ),
                ],
              );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: pronto ? _permitir : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 54,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pronto || _concedida ? cor : cor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: rotulo,
        ),
      ),
    );
  }

  Widget _rodape() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _status == PermissaoStatus.bloqueada && !_concedida
                ? Padding(
                    key: const ValueKey('bloqueada'),
                    padding: EdgeInsets.only(bottom: AppSpacing.normal),
                    child: appText(
                      'Essa permissão foi negada antes. Libere nos ajustes do celular e volte para o app.',
                      fontSize: AppFontSizes.verySmall,
                      color: local.AppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('livre')),
          ),
          _botaoPrincipal(),
          appSizedBox(height: AppSpacing.small),
          TextButton(
            onPressed: _pedindo || _concedida ? null : _proximo,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: local.AppColors.primary,
            ),
            child: appText(
              'Agora não',
              bold: true,
              fontSize: AppFontSizes.small,
              color: local.AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: local.AppColors.iconesBarraStatus,
        statusBarBrightness: local.AppColors.brilhoBarraStatus,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.surface,
        body: SafeArea(
          child: _passos == null
              ? Center(child: appLoadingRazor())
              : Column(
                  children: [
                    _topo(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          // Centraliza na tela e ainda rola em telas baixas.
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.big,
                              vertical: AppSpacing.medium,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - AppSpacing.medium * 2,
                              ),
                              child: Center(child: _conteudo()),
                            ),
                          );
                        },
                      ),
                    ),
                    _rodape(),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
