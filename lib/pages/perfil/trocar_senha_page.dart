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

class TrocarSenhaPage extends StatefulWidget {
  const TrocarSenhaPage({super.key});

  @override
  State<TrocarSenhaPage> createState() => _TrocarSenhaPageState();
}

class _TrocarSenhaPageState extends State<TrocarSenhaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppFormField _atual;
  late final AppFormField _nova;
  late final AppFormField _confirmar;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _atual = criarCampoPerfil(
      context: context,
      hint: 'Senha atual',
      icon: Phosphor.lockKey,
      textInputType: TextInputType.visiblePassword,
      showContent: false,
      validator: (String? value) => AppValidators.required(
        value,
        errorMessage: 'Senha atual é obrigatória',
      ),
    );
    _nova = criarCampoPerfil(
      context: context,
      hint: 'Nova senha',
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      showContent: false,
      validator: AppValidators.senhaCadastro,
    );
    _confirmar = criarCampoPerfil(
      context: context,
      hint: AppStrings.confirmeSuaSenha,
      icon: Phosphor.lockSimple,
      textInputType: TextInputType.visiblePassword,
      showContent: false,
      validator: (String? value) => AppValidators.confirmacaoSenha(
        value,
        _nova.controller.text,
      ),
    );
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _carregando = true);

    try {
      await trocarSenhaPerfil(
        senhaAtual: _atual.controller.text,
        senhaNova: _nova.controller.text,
      );
      if (!mounted) {
        return;
      }
      showSnackbarSuccess(message: 'Senha atualizada');
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
      title: 'Trocar senha',
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
                    linhas: const <String>[
                      'Use no mínimo 8 caracteres. Você continua conectado depois de trocar.',
                    ],
                  ),
                  _atual.formulario,
                  _nova.formulario,
                  _confirmar.formulario,
                  appElevatedButtonRazor(
                    title: 'Atualizar senha',
                    onTap: _salvar,
                    padding: AppSpacing.medium,
                  ),
                ],
              ),
            ),
    );
  }
}
