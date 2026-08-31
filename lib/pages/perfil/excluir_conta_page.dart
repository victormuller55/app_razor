import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/perfil/widgets/perfil_form_field.dart';
import 'package:app_razor/pages/perfil/widgets/perfil_info_banner.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class ExcluirContaPage extends StatefulWidget {
  const ExcluirContaPage({super.key});

  @override
  State<ExcluirContaPage> createState() => _ExcluirContaPageState();
}

class _ExcluirContaPageState extends State<ExcluirContaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppFormField _senha;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _senha = criarCampoPerfil(
      context: context,
      hint: 'Senha atual',
      icon: Phosphor.lockKey,
      textInputType: TextInputType.visiblePassword,
      showContent: false,
      validator: (String? value) => AppValidators.required(
        value,
        errorMessage: 'Senha é obrigatória',
      ),
    );
  }

  Future<void> _excluir() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _carregando = true);

    try {
      await excluirContaPerfil(senha: _senha.controller.text);
      if (!mounted) {
        return;
      }
      showSnackbarSuccess(message: 'Conta encerrada');
      open(screen: const LoginPage(), closePrevious: true);
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
      title: 'Excluir conta',
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
                    icon: Phosphor.warning,
                    linhas: const <String>[
                      'Sua conta será encerrada e você perderá o acesso aos agendamentos. Essa ação não pode ser desfeita.',
                      'Confirme com a senha atual para continuar.',
                    ],
                  ),
                  _senha.formulario,
                  appElevatedButtonRazor(
                    title: 'Excluir conta',
                    onTap: _excluir,
                    color: local.AppColors.danger,
                    padding: AppSpacing.medium,
                  ),
                ],
              ),
            ),
    );
  }
}
