import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/cadastro/cadastro_bloc.dart';
import 'package:app_razor/pages/cadastro/cadastro_event.dart';
import 'package:app_razor/pages/cadastro/cadastro_state.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/widgets/app_auth_layout.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
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

  void _updateAceitePolitica(bool value) {
    setState(() {
      _aceitouPolitica = value;
    });
  }

  @override
  void initState() {
    super.initState();

    nome = appAuthFormField(
      context: context,
      hint: AppStrings.digiteSeuNome,
      icon: Phosphor.user,
      textInputType: TextInputType.name,
      validator: AppValidators.nome,
    );

    email = appAuthFormField(
      context: context,
      hint: AppStrings.digiteSeuEmail,
      icon: Phosphor.envelope,
      textInputType: TextInputType.emailAddress,
      validator: (value) => AppValidators.email(
        value,
        errorMessage: AppStrings.emailInvalido,
      ),
    );

    senha = appAuthFormField(
      context: context,
      hint: AppStrings.digiteSuaSenha,
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      senha: true,
      validator: AppValidators.senhaCadastro,
    );

    confirmarSenha = appAuthFormField(
      context: context,
      hint: AppStrings.confirmeSuaSenha,
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      senha: true,
      validator: (value) => AppValidators.confirmacaoSenha(
        value,
        senha.controller.text,
      ),
    );
  }

  Widget _formCampos() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          nome.formulario,
          email.formulario,
          senha.formulario,
          confirmarSenha.formulario,
        ],
      ),
    );
  }

  Widget _conteudoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formCampos(),
        appSizedBox(height: 10),
        AppAuthTermos(
          value: _aceitouPolitica,
          onChanged: _updateAceitePolitica,
        ),
        appSizedBox(height: 10),
        appElevatedButtonRazor(
          title: AppStrings.cadastrar,
          onTap: _saveCadastro,
          height: 54,
          radius: 10,
          padding: AppSpacing.medium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroBloc, CadastroState>(
      bloc: bloc,
      builder: (context, state) {
        return AppAuthLayout(
          titulo: 'Crie sua conta',
          subtitulo:
              'Faltam poucos passos: preencha seus dados\nabaixo para começar a agendar.',
          rodapePergunta: '${AppStrings.jaTenhoConta}?',
          rodapeAcao: 'Entrar',
          onRodapeTap: _openLogin,
          onVoltar: _openLogin,
          loading: state is CadastroLoadingState,
          conteudo: _conteudoCard(),
        );
      },
    );
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }
}
