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

class EditarNomePage extends StatefulWidget {
  const EditarNomePage({super.key, required this.nomeAtual});

  final String nomeAtual;

  @override
  State<EditarNomePage> createState() => _EditarNomePageState();
}

class _EditarNomePageState extends State<EditarNomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppFormField _nome;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _nome = criarCampoPerfil(
      context: context,
      hint: AppStrings.digiteSeuNome,
      icon: Phosphor.user,
      textInputType: TextInputType.name,
      validator: AppValidators.nome,
    );
    _nome.controller.text = widget.nomeAtual;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _carregando = true);

    try {
      await atualizarNomePerfil(_nome.controller.text.trim());
      if (!mounted) {
        return;
      }
      showSnackbarSuccess(message: 'Nome atualizado');
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
      title: 'Editar nome',
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
                      'Esse nome aparece na home e nos seus agendamentos.',
                    ],
                  ),
                  _nome.formulario,
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
