import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/perfil/widgets/perfil_form_field.dart';
import 'package:app_razor/pages/perfil/widgets/perfil_info_banner.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class EditarEmailPage extends StatefulWidget {
  const EditarEmailPage({super.key, required this.emailAtual});

  final String emailAtual;

  @override
  State<EditarEmailPage> createState() => _EditarEmailPageState();
}

class _EditarEmailPageState extends State<EditarEmailPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppFormField _email;
  late final AppFormField _senha;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _email = criarCampoPerfil(
      context: context,
      hint: AppStrings.digiteSeuEmail,
      icon: Phosphor.envelope,
      textInputType: TextInputType.emailAddress,
      validator: (String? value) {
        final String? erro = AppValidators.email(
          value,
          errorMessage: AppStrings.emailInvalido,
        );
        if (erro != null) {
          return erro;
        }
        if (value!.trim().toLowerCase() == widget.emailAtual.trim().toLowerCase()) {
          return 'Informe um e-mail diferente do atual';
        }
        return null;
      },
    );
    _senha = criarCampoPerfil(
      context: context,
      hint: AppStrings.digiteSuaSenha,
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      showContent: false,
      validator: (String? value) => AppValidators.required(
        value,
        errorMessage: 'Senha é obrigatória',
      ),
    );
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _carregando = true);

    try {
      await trocarEmailPerfil(
        email: _email.controller.text.trim(),
        senha: _senha.controller.text,
      );
      if (!mounted) {
        return;
      }
      showSnackbarSuccess(message: 'E-mail atualizado');
      Navigator.of(context).pop(true);
    } catch (e) {
      showSnackbarError(message: errorModelFromApi(e).mensagem);
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: 'Trocar e-mail',
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: _carregando
          ? appLoadingRazor()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.normal),
                children: [
                  perfilInfoBanner(
                    linhas: <String>[
                      'Atual: ${widget.emailAtual}',
                      'Confirme com a senha atual para alterar o e-mail da conta.',
                    ],
                  ),
                  _email.formulario,
                  _senha.formulario,
                  appElevatedButtonRazor(
                    title: 'Salvar',
                    onTap: _salvar,
                    padding: AppSpacing.medium,
                  ),
                ],
              ),
            ),
    );
  }
}
