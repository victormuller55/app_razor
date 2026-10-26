import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/cadastro/cadastro_page.dart';
import 'package:app_razor/pages/login/login_bloc.dart';
import 'package:app_razor/pages/login/login_event.dart';
import 'package:app_razor/pages/login/login_state.dart';
import 'package:app_razor/widgets/app_auth_layout.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginBloc bloc = LoginBloc();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AppFormField email;
  late AppFormField senha;
  bool _aceitouPolitica = false;

  void _loginUsuario() {
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
      LoginSaveEvent(
        email: email.controller.text.trim(),
        senha: senha.controller.text,
      ),
    );
  }

  void _openCadastro() {
    open(screen: const CadastroPage(), closePrevious: true);
  }

  void _updateAceitePolitica(bool value) {
    setState(() {
      _aceitouPolitica = value;
    });
  }

  @override
  void initState() {
    super.initState();

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
      validator: (value) => AppValidators.required(
        value,
        errorMessage: 'Senha é obrigatória',
      ),
    );
  }

  Widget _formCampos() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          email.formulario,
          senha.formulario,
        ],
      ),
    );
  }

  Widget _conteudoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formCampos(),
        appSizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: AppAuthTermos(
            value: _aceitouPolitica,
            onChanged: _updateAceitePolitica,
          ),
        ),
        appSizedBox(height: 10),
        appElevatedButtonRazor(
          title: AppStrings.entrar,
          onTap: _loginUsuario,
          height: 54,
          radius: 10,
          padding: AppSpacing.medium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      bloc: bloc,
      builder: (context, state) {
        return AppAuthLayout(
          titulo: 'Entrar no Razor',
          subtitulo:
              'Acesse sua conta com seu e-mail e senha\npara agendar seu próximo corte.',
          rodapePergunta: '${AppStrings.naoTenhoConta}?',
          rodapeAcao: 'Cadastre-se',
          onRodapeTap: _openCadastro,
          loading: state is LoginLoadingState,
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
