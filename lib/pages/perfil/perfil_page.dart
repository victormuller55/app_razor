import 'dart:io';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/media_url.dart';
import 'package:app_razor/models/usuario_model.dart';
import 'package:app_razor/pages/perfil/editar_email_page.dart';
import 'package:app_razor/pages/perfil/editar_nome_page.dart';
import 'package:app_razor/pages/perfil/excluir_conta_page.dart';
import 'package:app_razor/pages/perfil/perfil_bloc.dart';
import 'package:app_razor/pages/perfil/perfil_event.dart';
import 'package:app_razor/pages/perfil/perfil_service.dart';
import 'package:app_razor/pages/perfil/perfil_state.dart';
import 'package:app_razor/pages/perfil/politica_privacidade_page.dart';
import 'package:app_razor/pages/perfil/trocar_senha_page.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muller_package/muller_package.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final PerfilBloc bloc = PerfilBloc();
  final ImagePicker _picker = ImagePicker();
  bool _enviandoFoto = false;

  Future<void> _load({bool silencioso = false}) async {
    final Future<PerfilState> done = bloc.stream.firstWhere(
      (PerfilState state) =>
          state is PerfilSuccessState || state is PerfilErrorState,
    );
    bloc.add(PerfilLoadEvent(silencioso: silencioso));
    await done;
  }

  Future<void> _abrir(Widget page) async {
    final bool? atualizou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => page),
    );
    if (atualizou == true && mounted) {
      await _load(silencioso: true);
    }
  }

  String? _urlFoto(UsuarioModel usuario) {
    return resolveMediaUrl(usuario.foto);
  }

  String _iniciais(String? nome) {
    final List<String> partes = (nome ?? '').trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) {
      return '?';
    }
    if (partes.length == 1) {
      return partes.first[0].toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Future<void> _escolherFoto(UsuarioModel usuario) async {
    if (_enviandoFoto) {
      return;
    }

    final String? acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: local.AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.big),
        ),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.medium,
                  AppSpacing.medium,
                  AppSpacing.small,
                ),
                child: appText(
                  'Foto de perfil',
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.medium,
                ),
              ),
              ListTile(
                leading: Icon(Phosphor.camera, color: local.AppColors.primary),
                title: appText('Câmera', color: local.AppColors.text, bold: true),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Icon(Phosphor.image, color: local.AppColors.primary),
                title: appText('Galeria', color: local.AppColors.text, bold: true),
                onTap: () => Navigator.pop(ctx, 'galeria'),
              ),
              if (_urlFoto(usuario) != null)
                ListTile(
                  leading: Icon(Phosphor.trash, color: local.AppColors.danger),
                  title: appText(
                    'Remover foto',
                    color: local.AppColors.danger,
                    bold: true,
                  ),
                  onTap: () => Navigator.pop(ctx, 'remover'),
                ),
              appSizedBox(height: AppSpacing.small),
            ],
          ),
        );
      },
    );

    if (acao == null || !mounted) {
      return;
    }
    if (acao == 'remover') {
      await _removerFoto();
      return;
    }
    await _enviarFoto(
      acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  Future<void> _enviarFoto(ImageSource origem) async {
    final XFile? arquivo = await _picker.pickImage(
      source: origem,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (arquivo == null || !mounted) {
      return;
    }

    setState(() => _enviandoFoto = true);

    try {
      final UsuarioModel usuario = await atualizarFotoPerfil(File(arquivo.path));
      if (!mounted) {
        return;
      }
      bloc.add(PerfilAtualizadoEvent(usuario));
      showSnackbarSuccess(message: 'Foto atualizada');
    } catch (e) {
      showSnackbarError(message: errorModelFromApi(e).mensagem);
    } finally {
      if (mounted) {
        setState(() => _enviandoFoto = false);
      }
    }
  }

  Future<void> _removerFoto() async {
    setState(() => _enviandoFoto = true);

    try {
      final UsuarioModel usuario = await removerFotoPerfil();
      if (!mounted) {
        return;
      }
      bloc.add(PerfilAtualizadoEvent(usuario));
      showSnackbarSuccess(message: 'Foto removida');
    } catch (e) {
      showSnackbarError(message: errorModelFromApi(e).mensagem);
    } finally {
      if (mounted) {
        setState(() => _enviandoFoto = false);
      }
    }
  }

  void _confirmarSaida() {
    showModalEmpty(
      context,
      initialHeight: 0.38,
      minHeight: 0.32,
      maxHeight: 0.5,
      backgroundColor: local.AppColors.white,
      child: Builder(
        builder: (BuildContext modalContext) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.small,
              AppSpacing.medium,
              AppSpacing.normal,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  'Sair da conta',
                  bold: true,
                  fontSize: AppFontSizes.medium,
                  color: local.AppColors.text,
                ),
                appSizedBox(height: AppSpacing.small),
                appText(
                  'Você vai precisar entrar de novo com e-mail e senha.',
                  color: local.AppColors.textSecondary,
                  fontSize: AppFontSizes.verySmall,
                ),
                appSizedBox(height: AppSpacing.medium),
                appElevatedButtonRazor(
                  title: 'Sim, sair',
                  padding: 0,
                  height: 46,
                  color: local.AppColors.danger,
                  onTap: () {
                    Navigator.of(modalContext).pop();
                    bloc.add(PerfilLogoutEvent());
                  },
                ),
                appElevatedButtonRazorTransparent(
                  title: 'Voltar',
                  padding: AppSpacing.small,
                  height: 46,
                  onTap: () => Navigator.of(modalContext).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(UsuarioModel usuario) {
    final String? url = _urlFoto(usuario);

    return GestureDetector(
      onTap: () => _escolherFoto(usuario),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: local.AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 88,
                height: 88,
                child: url == null
                    ? ColoredBox(
                        color: local.AppColors.primary.withValues(alpha: 0.12),
                        child: Center(
                          child: appText(
                            _iniciais(usuario.nome),
                            bold: true,
                            color: local.AppColors.primary,
                            fontSize: AppFontSizes.big,
                          ),
                        ),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: local.AppColors.primary.withValues(alpha: 0.12),
                          child: Center(
                            child: appText(
                              _iniciais(usuario.nome),
                              bold: true,
                              color: local.AppColors.primary,
                              fontSize: AppFontSizes.big,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: local.AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: local.AppColors.background, width: 2),
              boxShadow: <BoxShadow>[local.AppColors.cardShadow],
            ),
            child: _enviandoFoto
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: appLoadingRazor(size: 14),
                  )
                : Icon(
                    Phosphor.camera,
                    size: 14,
                    color: local.AppColors.primary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hero(UsuarioModel usuario) {
    return appContainer(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.big,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      radius: BorderRadius.circular(AppRadius.normal),
      backgroundColor: local.AppColors.white,
      shadow: local.AppColors.cardShadow,
      child: Column(
        children: [
          _avatar(usuario),
          appSizedBox(height: AppSpacing.medium),
          appText(
            usuario.nome ?? AppStrings.vazio,
            bold: true,
            color: local.AppColors.text,
            fontSize: AppFontSizes.medium,
            textAlign: TextAlign.center,
          ),
          appSizedBox(height: AppSpacing.small),
          appText(
            usuario.email ?? AppStrings.vazio,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _secao({required String titulo, required List<Widget> itens}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.small),
          child: appText(
            titulo.toUpperCase(),
            color: local.AppColors.textSecondary,
            fontSize: 11,
            bold: true,
          ),
        ),
        appContainer(
          radius: BorderRadius.circular(AppRadius.normal),
          backgroundColor: local.AppColors.white,
          shadow: local.AppColors.cardShadow,
          child: Column(
            children: [
              for (int i = 0; i < itens.length; i++) ...[
                itens[i],
                if (i < itens.length - 1)
                  Divider(
                    height: 1,
                    color: local.AppColors.border,
                    indent: 60,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _linha({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final Color cor = destructive ? local.AppColors.danger : local.AppColors.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.normal,
        vertical: 2,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cor, size: 18),
      ),
      title: appText(
        title,
        color: destructive ? local.AppColors.danger : local.AppColors.text,
        bold: true,
        fontSize: AppFontSizes.small,
      ),
      subtitle: subtitle == null
          ? null
          : appText(
              subtitle,
              color: local.AppColors.textSecondary,
              fontSize: 12,
            ),
      trailing: Icon(
        Phosphor.caretRight,
        color: local.AppColors.textSecondary,
        size: 16,
      ),
    );
  }

  Widget _loaded(UsuarioModel usuario) {
    return RefreshIndicator(
      color: local.AppColors.primary,
      onRefresh: () => _load(silencioso: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.normal,
          AppSpacing.normal,
          AppSpacing.normal,
          AppSpacing.normal + kBottomNavigationBarHeight,
        ),
        children: [
          _hero(usuario),
          appSizedBox(height: AppSpacing.medium),
          _secao(
            titulo: 'Conta',
            itens: [
              _linha(
                icon: Phosphor.camera,
                title: 'Alterar foto',
                subtitle: 'Câmera ou galeria',
                onTap: () => _escolherFoto(usuario),
              ),
              _linha(
                icon: Phosphor.userCircle,
                title: 'Editar nome',
                subtitle: usuario.nome,
                onTap: () => _abrir(
                  EditarNomePage(nomeAtual: usuario.nome ?? ''),
                ),
              ),
              _linha(
                icon: Phosphor.envelopeSimple,
                title: 'Trocar e-mail',
                subtitle: usuario.email,
                onTap: () => _abrir(
                  EditarEmailPage(emailAtual: usuario.email ?? ''),
                ),
              ),
              _linha(
                icon: Phosphor.lockKey,
                title: 'Trocar senha',
                subtitle: 'Mínimo de 8 caracteres',
                onTap: () => _abrir(const TrocarSenhaPage()),
              ),
            ],
          ),
          appSizedBox(height: AppSpacing.medium),
          _secao(
            titulo: 'Legal',
            itens: [
              _linha(
                icon: Phosphor.shieldCheck,
                title: 'Política de privacidade',
                subtitle: 'Como tratamos seus dados',
                onTap: () => _abrir(const PoliticaPrivacidadePage()),
              ),
            ],
          ),
          appSizedBox(height: AppSpacing.medium),
          _secao(
            titulo: 'Zona de risco',
            itens: [
              _linha(
                icon: Phosphor.trash,
                title: 'Excluir conta',
                subtitle: 'Encerra o acesso a este login',
                destructive: true,
                onTap: () => _abrir(const ExcluirContaPage()),
              ),
            ],
          ),
          appSizedBox(height: AppSpacing.big),
          appElevatedButtonRazorTransparent(
            title: 'Sair da conta',
            onTap: _confirmarSaida,
            textColor: local.AppColors.danger,
            borderColor: local.AppColors.danger,
            height: 50,
            padding: 0,
          ),
        ],
      ),
    );
  }

  Widget _conteudo(PerfilState state) {
    if (state is PerfilSuccessState) {
      return _loaded(state.usuario);
    }

    if (state is PerfilErrorState) {
      return appError(
        state.errorModel,
        function: () => _load(),
      );
    }

    return appLoadingRazor();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilBloc, PerfilState>(
      bloc: bloc,
      builder: (BuildContext context, PerfilState state) {
        return scaffold(
          title: 'Perfil',
          hideBackIcon: true,
          background: local.AppColors.background,
          appBarColor: local.AppColors.primary,
          body: _conteudo(state),
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
