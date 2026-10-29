import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/menu/menu.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/permissoes/widgets/permissoes_animacao.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Tela exibida após o login (e na abertura do app, se a localização não
/// estiver liberada). Só deixa seguir para a home com a localização permitida.
class PermissoesPage extends StatefulWidget {
  const PermissoesPage({super.key});

  @override
  State<PermissoesPage> createState() => _PermissoesPageState();
}

class _PermissoesPageState extends State<PermissoesPage>
    with WidgetsBindingObserver {
  final List<PermissaoApp> _permissoes = permissoesDoApp();
  final Map<PermissaoApp, PermissaoStatus> _status =
      <PermissaoApp, PermissaoStatus>{};

  bool get _localizacaoConcedida =>
      _status[PermissaoApp.localizacao] == PermissaoStatus.concedida;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizarStatus();
  }

  // Ao voltar dos Ajustes, relê o que o usuário liberou por lá.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _atualizarStatus();
    }
  }

  Future<void> _atualizarStatus() async {
    for (final PermissaoApp permissao in _permissoes) {
      _status[permissao] = await statusPermissao(permissao);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pedir(PermissaoApp permissao) async {
    if (_status[permissao] == PermissaoStatus.bloqueada) {
      await abrirAjustesDoApp();
      return;
    }

    final PermissaoStatus status = await pedirPermissao(permissao);

    if (mounted) {
      setState(() => _status[permissao] = status);
    }
  }

  void _continuar() {
    if (!_localizacaoConcedida) {
      showSnackbarWarning(
        message: 'Permita o acesso à localização para continuar.',
      );
      return;
    }

    open(screen: const MenuScreen(), closePrevious: true);
  }

  Future<void> _sair() async {
    await sairDaConta();
    open(screen: const LoginPage(), closePrevious: true);
  }

  String _titulo(PermissaoApp permissao) {
    switch (permissao) {
      case PermissaoApp.localizacao:
        return 'Localização';
      case PermissaoApp.camera:
        return 'Câmera';
      case PermissaoApp.galeria:
        return 'Fotos';
      case PermissaoApp.notificacoes:
        return 'Avisos';
    }
  }

  String _descricao(PermissaoApp permissao) {
    switch (permissao) {
      case PermissaoApp.localizacao:
        return 'Mostra barbearias e promoções perto de você.';
      case PermissaoApp.camera:
        return 'Tire uma foto para o seu perfil.';
      case PermissaoApp.galeria:
        return 'Escolha uma foto do perfil na galeria.';
      case PermissaoApp.notificacoes:
        return 'Lembrete 1 hora antes, confirmações e mudanças no seu horário.';
    }
  }

  IconData _icone(PermissaoApp permissao) {
    switch (permissao) {
      case PermissaoApp.localizacao:
        return Phosphor.mapPin;
      case PermissaoApp.camera:
        return Phosphor.camera;
      case PermissaoApp.galeria:
        return Phosphor.images;
      case PermissaoApp.notificacoes:
        return Phosphor.bell;
    }
  }

  Widget _acao(PermissaoApp permissao) {
    final PermissaoStatus? status = _status[permissao];

    if (status == PermissaoStatus.concedida) {
      return Icon(
        PhosphorFill.checkCircle,
        color: local.AppColors.statusAberto,
        size: 26,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: status == null ? null : () => _pedir(permissao),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: local.AppColors.primary,
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        ),
        child: appText(
          status == PermissaoStatus.bloqueada ? 'Ajustes' : 'Permitir',
          bold: true,
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.white,
        ),
      ),
    );
  }

  Widget _card(PermissaoApp permissao) {
    final bool obrigatoria = permissao == PermissaoApp.localizacao;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.normal),
      padding: EdgeInsets.all(AppSpacing.normal + 2),
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: local.AppColors.surface,
              borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
            ),
            child: Icon(
              _icone(permissao),
              color: local.AppColors.primary,
              size: 22,
            ),
          ),
          appSizedBox(width: AppSpacing.normal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    appText(
                      _titulo(permissao),
                      bold: true,
                      fontSize: AppFontSizes.small,
                      color: local.AppColors.text,
                    ),
                    appSizedBox(width: 6),
                    appText(
                      obrigatoria ? 'Obrigatória' : 'Opcional',
                      fontSize: 11,
                      color: obrigatoria
                          ? local.AppColors.danger
                          : AppEstilo.campoIcone,
                    ),
                  ],
                ),
                appSizedBox(height: 2),
                appText(
                  _descricao(permissao),
                  fontSize: AppFontSizes.verySmall,
                  color: local.AppColors.textSecondary,
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.small),
          _acao(permissao),
        ],
      ),
    );
  }

  Widget _conteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final PermissaoApp permissao in _permissoes) _card(permissao),
        appSizedBox(height: AppSpacing.small),
        appElevatedButtonRazor(
          title: 'Continuar',
          onTap: _continuar,
          color: _localizacaoConcedida
              ? local.AppColors.primary
              : local.AppColors.statusFechado,
          height: 54,
          radius: 10,
          padding: AppSpacing.medium,
        ),
      ],
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        const PermissoesAnimacao(),
        appSizedBox(height: AppSpacing.normal),
        appText(
          'Permissões',
          bold: true,
          fontSize: 26,
          color: local.AppColors.text,
          textAlign: TextAlign.center,
        ),
        appSizedBox(height: 4),
        appText(
          'Libere o acesso abaixo para o Razor\nencontrar as barbearias perto de você.',
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _rodape() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _sair,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.normal),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppFontSizes.verySmall + 1,
              color: local.AppColors.textSecondary,
            ),
            children: [
              TextSpan(text: 'Quer usar outra conta? '),
              TextSpan(
                text: 'Sair',
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
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Centraliza na tela e ainda rola em telas baixas.
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(AppSpacing.medium),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - AppSpacing.medium * 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _cabecalho(),
                            appSizedBox(height: AppSpacing.medium + 4),
                            _conteudo(),
                          ],
                        ),
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
