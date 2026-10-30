import 'dart:async';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/validators.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_bloc.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_event.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_state.dart';
import 'package:app_razor/widgets/app_auth_layout.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

/// RAZ-08: "Esqueci minha senha" do app. Três passos na mesma tela (e-mail, código, nova senha). Ao terminar
/// volta para o login devolvendo o e-mail, sem entrar automaticamente.
class RecuperarSenhaPage extends StatefulWidget {
  final String emailInicial;
  final RecuperarSenhaBloc? bloc;

  const RecuperarSenhaPage({super.key, this.emailInicial = '', this.bloc});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  late final RecuperarSenhaBloc bloc = widget.bloc ?? RecuperarSenhaBloc();

  final GlobalKey<FormState> _formEmail = GlobalKey<FormState>();
  late AppFormField email;
  late AppFormField codigo;
  late AppFormField senha;
  late AppFormField confirmacao;

  Timer? _timer;
  int _espera = 0;
  RecuperarSenhaState _ultimo = const RecuperarSenhaState();

  @override
  void initState() {
    super.initState();
    email = appAuthFormField(
      context: context,
      hint: AppStrings.digiteSeuEmail,
      icon: Phosphor.envelope,
      textInputType: TextInputType.emailAddress,
      validator: (value) => AppValidators.email(value, errorMessage: AppStrings.emailInvalido),
    );
    email.controller.text = widget.emailInicial;
    codigo = appAuthFormField(
      context: context,
      hint: 'Código de 6 números',
      icon: Phosphor.password,
      textInputType: TextInputType.number,
      textInputFormatter: _CodigoFormatter(),
    );
    senha = appAuthFormField(
      context: context,
      hint: 'Nova senha',
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      senha: true,
    );
    confirmacao = appAuthFormField(
      context: context,
      hint: 'Confirme a nova senha',
      icon: Phosphor.lock,
      textInputType: TextInputType.visiblePassword,
      senha: true,
    );
  }

  void _iniciarEspera(int segundos) {
    _timer?.cancel();
    setState(() => _espera = segundos);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _espera <= 1) {
        timer.cancel();
        if (mounted) setState(() => _espera = 0);
        return;
      }
      setState(() => _espera--);
    });
  }

  void _enviarEmail() {
    if (!(_formEmail.currentState?.validate() ?? false)) return;
    bloc.add(RecuperarSenhaSolicitarEvent(email: email.controller.text));
  }

  void _reenviar(RecuperarSenhaState state) {
    codigo.controller.clear();
    bloc.add(RecuperarSenhaSolicitarEvent(email: state.email));
  }

  void _voltarParaLogin(String emailDigitado) {
    Navigator.of(context).pop(emailDigitado);
  }

  void _ouvir(BuildContext context, RecuperarSenhaState anterior, RecuperarSenhaState atual) {
    final bool codigoEnviado = anterior.carregando && !atual.carregando && atual.erro.isEmpty &&
        atual.passo == RecuperarSenhaPasso.codigo;
    if (codigoEnviado) _iniciarEspera(atual.reenviarEmSegundos);
    if (atual.passo == RecuperarSenhaPasso.senha && anterior.passo != RecuperarSenhaPasso.senha) {
      codigo.controller.clear();
    }
    if (atual.passo == RecuperarSenhaPasso.concluido) {
      senha.controller.clear();
      confirmacao.controller.clear();
      showSnackbarSuccess(message: atual.mensagem);
      _voltarParaLogin(atual.email);
    }
  }

  Widget _texto(String texto, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 12),
      child: appText(texto, fontSize: AppFontSizes.verySmall + 1, color: cor ?? local.AppColors.textSecondary),
    );
  }

  Widget _erro(RecuperarSenhaState state) {
    if (state.erro.isEmpty) return const SizedBox.shrink();
    return Semantics(liveRegion: true, child: _texto(state.erro, cor: local.AppColors.danger));
  }

  Widget _botao(String titulo, VoidCallback onTap) {
    return appElevatedButtonRazor(title: titulo, onTap: onTap, height: 54, radius: 10, padding: AppSpacing.medium);
  }

  Widget _passoEmail(RecuperarSenhaState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _texto('Informe o e-mail da sua conta. Se ele estiver cadastrado, enviaremos um código de 6 números.'),
        Form(key: _formEmail, child: email.formulario),
        _erro(state),
        appSizedBox(height: 10),
        _botao('Enviar código', _enviarEmail),
      ],
    );
  }

  Widget _passoCodigo(RecuperarSenhaState state) {
    final String espera = '${_espera ~/ 60}:${(_espera % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.mensagem.isNotEmpty) _texto(state.mensagem),
        _texto('Confira a caixa de entrada (e o spam) de ${state.email}. '
            'O código vale por ${state.validadeMinutos} minutos.'),
        codigo.formulario,
        _erro(state),
        appSizedBox(height: 10),
        _botao('Confirmar código', () => bloc.add(RecuperarSenhaVerificarEvent(codigo: codigo.controller.text))),
        appAuthLink(
          texto: _espera > 0 ? 'Reenviar código em $espera' : 'Reenviar código',
          onTap: _espera > 0 || state.carregando ? () {} : () => _reenviar(state),
        ),
        appAuthLink(texto: 'Trocar e-mail', onTap: () => bloc.add(RecuperarSenhaRecomecarEvent())),
      ],
    );
  }

  Widget _passoSenha(RecuperarSenhaState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _texto('Crie a nova senha, com 8 a 128 caracteres. Depois, entre com ela.'),
        senha.formulario,
        confirmacao.formulario,
        _erro(state),
        appSizedBox(height: 10),
        _botao(
          'Salvar nova senha',
          () => bloc.add(RecuperarSenhaRedefinirEvent(
            senha: senha.controller.text,
            confirmacao: confirmacao.controller.text,
          )),
        ),
        appAuthLink(texto: 'Pedir um novo código', onTap: () => bloc.add(RecuperarSenhaRecomecarEvent())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecuperarSenhaBloc, RecuperarSenhaState>(
      bloc: bloc,
      listener: (context, atual) {
        _ouvir(context, _ultimo, atual);
        _ultimo = atual;
      },
      builder: (context, state) {
        final Widget conteudo = switch (state.passo) {
          RecuperarSenhaPasso.email => _passoEmail(state),
          RecuperarSenhaPasso.codigo => _passoCodigo(state),
          RecuperarSenhaPasso.senha || RecuperarSenhaPasso.concluido => _passoSenha(state),
        };
        return AppAuthLayout(
          titulo: switch (state.passo) {
            RecuperarSenhaPasso.email => 'Esqueci minha senha',
            RecuperarSenhaPasso.codigo => 'Digite o código',
            _ => 'Crie a nova senha',
          },
          subtitulo: 'Recupere o acesso à sua conta\nem poucos passos.',
          rodapePergunta: 'Lembrou a senha?',
          rodapeAcao: 'Entrar',
          onRodapeTap: () => _voltarParaLogin(state.email.isNotEmpty ? state.email : email.controller.text.trim()),
          onVoltar: () => _voltarParaLogin(email.controller.text.trim()),
          loading: state.carregando,
          conteudo: conteudo,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.bloc == null) bloc.close();
    super.dispose();
  }
}

/// Só dígitos, no máximo 6.
class _CodigoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String texto = digitos.length > 6 ? digitos.substring(0, 6) : digitos;
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
