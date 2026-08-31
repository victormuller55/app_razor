import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/cadastro/cadastro_bloc.dart';
import 'package:app_razor/pages/cadastro/cadastro_event.dart';
import 'package:app_razor/pages/cadastro/cadastro_state.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_logo.dart';
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AppFormField nome;
  late AppFormField email;
  late AppFormField senha;
  late AppFormField confirmarSenha;
  bool _aceitouPolitica = false;

  void _saveCadastro() {
    final bool formValido = _formKey.currentState?.validate() ?? false;

    if (!_aceitouPolitica) {
      showSnackbarWarning(
        message: AppStrings.concordeComOsTermosDeUsoEPoliticaDePrivacidade,
      );
      return;
    }

    if (!formValido) {
      return;
    }

    bloc.add(
      CadastroSaveEvent(
        nome: nome.controller.text.trim(),
        email: email.controller.text.trim(),
        senha: senha.controller.text,
      ),
    );
  }

  void _openLogin() {
    open(screen: const LoginPage(), closePrevious: true);
  }

  void _updateAceitePolitica(bool? value) {
    setState(() {
      _aceitouPolitica = value ?? false;
    });
  }

  @override
  void initState() {
    super.initState();

    nome = AppFormField(
      context: context,
      hint: AppStrings.digiteSeuNome,
      paddingHeight: 15,
      maxLines: 1,
      fontSize: 15,
      errorFontSize: 11,
      radius: AppRadius.medium,
      textInputType: TextInputType.name,
      backgroundColor: local.AppColors.white,
      inputColor: local.AppColors.text,
      hintColor: local.AppColors.textSecondary,
      borderColor: local.AppColors.border,
      hoverBorderColor: local.AppColors.primary,
      iconColor: local.AppColors.iconMuted,
      icon: Icon(Phosphor.user, color: local.AppColors.iconMuted),
      validator: AppValidators.nome,
    );

    email = AppFormField(
      context: context,
      hint: AppStrings.digiteSeuEmail,
      paddingHeight: 15,
      maxLines: 1,
      fontSize: 15,
      errorFontSize: 11,
      radius: AppRadius.medium,
      textInputType: TextInputType.emailAddress,
      backgroundColor: local.AppColors.white,
      inputColor: local.AppColors.text,
      hintColor: local.AppColors.textSecondary,
      borderColor: local.AppColors.border,
      hoverBorderColor: local.AppColors.primary,
      iconColor: local.AppColors.iconMuted,
      icon: Icon(Phosphor.envelope, color: local.AppColors.iconMuted),
      validator: (value) => AppValidators.email(
        value,
        errorMessage: AppStrings.emailInvalido,
      ),
    );

    senha = AppFormField(
      context: context,
      hint: AppStrings.digiteSuaSenha,
      radius: AppRadius.medium,
      paddingHeight: 15,
      maxLines: 1,
      fontSize: 15,
      errorFontSize: 11,
      inputColor: local.AppColors.text,
      hintColor: local.AppColors.textSecondary,
      borderColor: local.AppColors.border,
      hoverBorderColor: local.AppColors.primary,
      backgroundColor: local.AppColors.white,
      iconColor: local.AppColors.iconMuted,
      icon: Icon(Phosphor.lock, color: local.AppColors.iconMuted),
      textInputType: TextInputType.visiblePassword,
      validator: AppValidators.senhaCadastro,
      showContent: false,
    );

    confirmarSenha = AppFormField(
      context: context,
      hint: AppStrings.confirmeSuaSenha,
      radius: AppRadius.medium,
      paddingHeight: 15,
      maxLines: 1,
      fontSize: 15,
      errorFontSize: 11,
      inputColor: local.AppColors.text,
      hintColor: local.AppColors.textSecondary,
      borderColor: local.AppColors.border,
      hoverBorderColor: local.AppColors.primary,
      backgroundColor: local.AppColors.white,
      iconColor: local.AppColors.iconMuted,
      icon: Icon(Phosphor.lock, color: local.AppColors.iconMuted),
      textInputType: TextInputType.visiblePassword,
      validator: (value) => AppValidators.confirmacaoSenha(
        value,
        senha.controller.text,
      ),
      showContent: false,
    );
  }

  Widget _headerAcoes() {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          appText(
            '${AppStrings.jaTenhoConta}?',
            color: local.AppColors.white.withValues(alpha: 0.82),
            fontSize: 12,
            maxLines: 1,
            overflow: true,
          ),
          appSizedBox(width: AppSpacing.normal),
          appElevatedButtonRazorTransparent(
            title: AppStrings.entrar,
            onTap: _openLogin,
            height: 40,
            padding: AppSpacing.zero,
            fitContent: true,
            fontSize: 12,
            textColor: local.AppColors.white,
            borderColor: local.AppColors.white.withValues(alpha: 0.7),
            backgroundColor: local.AppColors.white.withValues(alpha: 0.14),
          ),
        ],
      ),
    );
  }

  Widget _headerGradiente() {
    return appContainer(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.34,
      gradient: local.AppColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.big,
        AppSpacing.medium,
        AppSpacing.giant,
      ),
      child: Column(
        children: [
          _headerAcoes(),
          Expanded(child: appLogoRazor(inverted: true, fill: true)),
        ],
      ),
    );
  }

  Widget _titleBoasVindas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        appText(
          'Crie sua conta',
          bold: true,
          fontSize: AppFontSizes.big,
          color: local.AppColors.text,
        ),
        appSizedBox(height: AppSpacing.small),
        appText(
          'Insira seus dados abaixo',
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _formDadosPessoais() {
    return Column(
      children: [
        nome.formulario,
        email.formulario,
      ],
    );
  }

  Widget _formSenhas() {
    return Column(
      children: [
        senha.formulario,
        confirmarSenha.formulario,
      ],
    );
  }

  Widget _formCampos() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _formDadosPessoais(),
            _formSenhas(),
          ],
        ),
      ),
    );
  }

  Widget _checkboxPoliticas() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: CheckboxListTile(
        value: _aceitouPolitica,
        onChanged: _updateAceitePolitica,
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: local.AppColors.primary,
        checkColor: local.AppColors.white,
        side: BorderSide(color: local.AppColors.border),
        title: appText(
          AppStrings.concordoTermosPoliticas,
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.text,
        ),
      ),
    );
  }

  Widget _blocoFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleBoasVindas(),
        _formCampos(),
        _checkboxPoliticas(),
      ],
    );
  }

  Widget _actionsBotoes() {
    return appElevatedButtonRazor(
      title: AppStrings.cadastrar,
      onTap: _saveCadastro,
      padding: AppSpacing.medium,
    );
  }

  Widget _footerConvertix() {
    return Column(
      children: [
        appSizedBox(height: AppSpacing.normal),
        appText(
          'Powered by Convertix',
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _blocoAcoes() {
    return Column(
      children: [
        _actionsBotoes(),
        _footerConvertix(),
      ],
    );
  }

  Widget _cardConteudo() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.72,
        widthFactor: 1,
        child: appContainer(
          backgroundColor: local.AppColors.background,
          radius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: AppScrollVertical(
            center: false,
            padding: AppSpacing.big,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _blocoFormulario(),
                _blocoAcoes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardLoading() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.72,
        widthFactor: 1,
        child: appContainer(
          backgroundColor: local.AppColors.background,
          radius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: appLoadingRazor(),
        ),
      ),
    );
  }

  Widget _bodyLoading() {
    return Stack(
      children: [
        _headerGradiente(),
        _cardLoading(),
      ],
    );
  }

  Widget _bodyTela() {
    return Stack(
      children: [
        _headerGradiente(),
        _cardConteudo(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: local.AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: local.AppColors.background,
        systemNavigationBarContrastEnforced: false,
      ),
      child: scaffold(
        title: AppStrings.vazio,
        showAppBar: false,
        safeBottom: false,
        background: local.AppColors.primaryDark,
        body: BlocBuilder<CadastroBloc, CadastroState>(
          bloc: bloc,
          builder: (context, state) {
            if (state is CadastroLoadingState) {
              return _bodyLoading();
            }

            return _bodyTela();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }
}
