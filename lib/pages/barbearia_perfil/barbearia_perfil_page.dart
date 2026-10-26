import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/abrir_rota.dart';
import 'package:app_razor/functions/telefone.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:app_razor/models/promocao_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_bloc.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_event.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_state.dart';
import 'package:app_razor/pages/agendamento/agendamento_page.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/funcionario_grid_card.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:app_razor/pages/home/widgets/home_promocao_card.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

void openBarbeariaPerfil({
  required int barbeariaId,
  String? nome,
}) {
  open(
    screen: BarbeariaPerfilPage(
      barbeariaId: barbeariaId,
      nomeInicial: nome,
    ),
  );
}

class BarbeariaPerfilPage extends StatefulWidget {
  const BarbeariaPerfilPage({
    super.key,
    required this.barbeariaId,
    this.nomeInicial,
  });

  final int barbeariaId;
  final String? nomeInicial;

  @override
  State<BarbeariaPerfilPage> createState() => _BarbeariaPerfilPageState();
}

class _BarbeariaPerfilPageState extends State<BarbeariaPerfilPage> {
  static const Color _corAcaoFundo = Color(0xFFE8EEF4);

  late final BarbeariaPerfilBloc bloc;

  Future<void> _loadPerfil({bool forceRefresh = false}) async {
    bloc.add(BarbeariaPerfilLoadEvent(forceRefresh: forceRefresh));
  }

  void _abrirAgendamento({int? servicoId, int? funcionarioId}) {
    openAgendamento(
      barbeariaId: widget.barbeariaId,
      nomeBarbearia: widget.nomeInicial,
      servicoId: servicoId,
      funcionarioId: funcionarioId,
    );
  }

  Future<void> _abrirRota(BarbeariaPerfilModel perfil) async {
    try {
      await abrirRotaBarbearia(
        latitude: perfil.latitude,
        longitude: perfil.longitude,
        endereco: perfil.enderecoCompleto,
        nome: perfil.nome,
      );
    } catch (_) {
      showSnackbarWarning(message: rotaMensagemIndisponivel);
    }
  }

  Future<void> _ligar(String? telefone) async {
    try {
      await abrirTelefone(telefone);
    } catch (_) {
      showSnackbarWarning(message: contatoMensagemIndisponivel);
    }
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    try {
      await abrirWhatsApp(telefone);
    } catch (_) {
      showSnackbarWarning(message: contatoMensagemIndisponivel);
    }
  }

  Future<void> _compartilhar(BarbeariaPerfilModel perfil) async {
    final String nome = perfil.nome?.trim() ?? '';
    final String endereco = perfil.enderecoCompleto?.trim() ??
        perfil.localDescricao.trim();
    final String texto = <String>[
      if (nome.isNotEmpty) nome,
      if (endereco.isNotEmpty) endereco,
    ].join('\n');

    if (texto.isEmpty) {
      showSnackbarWarning(message: 'Nada para compartilhar.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: texto));
    showSnackbarSuccess(message: 'Informações copiadas');
  }

  @override
  void initState() {
    super.initState();
    bloc = BarbeariaPerfilBloc(barbeariaId: widget.barbeariaId);
    _loadPerfil();
  }

  String _formataInteiro(int value) {
    final String digits = value.toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  Widget _badgeStatus(BarbeariaPerfilModel perfil) {
    final bool aberto = perfil.aberto ?? false;
    final Color cor = aberto
        ? local.AppColors.statusAberto
        : local.AppColors.statusFechado;

    return appContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      backgroundColor: cor.withValues(alpha: 0.12),
      radius: BorderRadius.circular(20),
      child: appText(
        aberto ? 'Aberto' : 'Fechado',
        bold: true,
        color: cor,
        fontSize: 12,
      ),
    );
  }

  Widget _linhaMeta({
    required IconData icone,
    required String texto,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icone, size: 16, color: local.AppColors.primary),
        ),
        appSizedBox(width: 6),
        Expanded(
          child: appText(
            texto,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
        ),
      ],
    );
  }

  Widget _logoIdentidade(BarbeariaPerfilModel perfil) {
    const double size = 72;
    final String? logo = perfil.logo;
    final bool temFoto = logo != null && logo.isNotEmpty;
    final String nome = perfil.nome ?? '';
    final String inicial =
        nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.interno),
      child: SizedBox(
        width: size,
        height: size,
        child: temFoto
            ? Image.network(
                logo,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) =>
                    _logoFallback(inicial, nome.isEmpty, size),
              )
            : _logoFallback(inicial, nome.isEmpty, size),
      ),
    );
  }

  Widget _logoFallback(String inicial, bool vazio, double size) {
    return ColoredBox(
      color: local.AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: vazio
            ? Icon(
                Phosphor.scissors,
                size: size * 0.4,
                color: local.AppColors.primary,
              )
            : appText(
                inicial,
                bold: true,
                fontSize: size * 0.38,
                color: local.AppColors.primary,
              ),
      ),
    );
  }

  Widget _identidade(BarbeariaPerfilModel perfil) {
    final String nota =
        (perfil.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
    final int? total = perfil.totalAvaliacoes;
    final String notaTexto = total != null && total > 0
        ? '$nota (${_formataInteiro(total)} ${total == 1 ? 'avaliação' : 'avaliações'})'
        : nota;
    final String? descricao = perfil.descricao?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _logoIdentidade(perfil),
            appSizedBox(width: AppSpacing.normal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: appText(
                          perfil.nome ?? AppStrings.vazio,
                          bold: true,
                          fontSize: AppFontSizes.medium,
                          color: local.AppColors.text,
                        ),
                      ),
                      appSizedBox(width: AppSpacing.small),
                      _badgeStatus(perfil),
                    ],
                  ),
                  appSizedBox(height: 6),
                  _linhaMeta(icone: Phosphor.star, texto: notaTexto),
                ],
              ),
            ),
          ],
        ),
        if (descricao != null && descricao.isNotEmpty) ...[
          appSizedBox(height: AppSpacing.normal),
          appText(
            descricao,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
        ],
      ],
    );
  }

  Widget _botaoAcaoRapida({
    required IconData icone,
    required String texto,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            appContainer(
              width: 56,
              height: 56,
              backgroundColor: _corAcaoFundo,
              radius: BorderRadius.circular(AppRadii.interno),
              child: Center(
                child: Icon(icone, size: 24, color: local.AppColors.primary),
              ),
            ),
            appSizedBox(height: 6),
            appText(
              texto,
              color: local.AppColors.textSecondary,
              fontSize: 12,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _acoesRapidas(BarbeariaPerfilModel perfil) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: Row(
        children: [
          _botaoAcaoRapida(
            icone: Phosphor.whatsappLogo,
            texto: 'WhatsApp',
            onTap: () => _abrirWhatsApp(perfil.telefone),
          ),
          _botaoAcaoRapida(
            icone: Phosphor.phone,
            texto: 'Ligar',
            onTap: () => _ligar(perfil.telefone),
          ),
          _botaoAcaoRapida(
            icone: Phosphor.mapPin,
            texto: 'Rota',
            onTap: () => _abrirRota(perfil),
          ),
          _botaoAcaoRapida(
            icone: Phosphor.shareNetwork,
            texto: 'Compartilhar',
            onTap: () => _compartilhar(perfil),
          ),
        ],
      ),
    );
  }

  Widget _cabecalhoSecao({
    required String titulo,
    String? acao,
    VoidCallback? onAcao,
  }) {
    return Row(
      children: [
        Expanded(
          child: appText(
            titulo,
            bold: true,
            fontSize: AppFontSizes.small,
            color: local.AppColors.text,
          ),
        ),
        if (acao != null)
          GestureDetector(
            onTap: onAcao,
            child: appText(
              acao,
              bold: true,
              color: local.AppColors.primary,
              fontSize: AppFontSizes.verySmall,
            ),
          ),
      ],
    );
  }

  void _abrirEquipeCompleta(BarbeariaPerfilModel perfil) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return appContainer(
          width: double.infinity,
          backgroundColor: local.AppColors.white,
          radius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.externo),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.normal,
              AppSpacing.medium,
              MediaQuery.viewPaddingOf(modalContext).bottom + AppSpacing.medium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 6,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                appSizedBox(height: AppSpacing.medium),
                appText(
                  'Equipe',
                  bold: true,
                  fontSize: AppFontSizes.small,
                  color: local.AppColors.text,
                ),
                appSizedBox(height: AppSpacing.normal),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: perfil.funcionarios.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.normal,
                    crossAxisSpacing: AppSpacing.small,
                    mainAxisExtent: 148,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final BarbeariaFuncionarioModel funcionario =
                        perfil.funcionarios[index];
                    return funcionarioGridCard(funcionario: funcionario);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _equipe(BarbeariaPerfilModel perfil) {
    if (perfil.funcionarios.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.big),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoSecao(
            titulo: 'Equipe',
            acao: perfil.funcionarios.length > 3 ? 'Ver todos' : null,
            onAcao: () => _abrirEquipeCompleta(perfil),
          ),
          appSizedBox(height: AppSpacing.normal),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: perfil.funcionarios.length,
              separatorBuilder: (_, _) => appSizedBox(width: AppSpacing.normal),
              itemBuilder: (BuildContext context, int index) {
                final BarbeariaFuncionarioModel funcionario =
                    perfil.funcionarios[index];
                return funcionarioListaCard(funcionario: funcionario);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao({
    required String titulo,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            titulo,
            bold: true,
            fontSize: AppFontSizes.small,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.small),
          child,
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return appContainer(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppSpacing.normal),
      backgroundColor: local.AppColors.background,
      radius: BorderRadius.circular(AppRadii.externo),
      child: child,
    );
  }

  Widget _endereco(BarbeariaPerfilModel perfil) {
    final String endereco = perfil.enderecoCompleto?.trim().isNotEmpty == true
        ? perfil.enderecoCompleto!.trim()
        : perfil.localDescricao;
    final bool temMapa = perfil.latitude != null && perfil.longitude != null;
    final bool temEndereco = endereco.isNotEmpty;

    if (!temMapa && !temEndereco) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: _card(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (temMapa)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.externo),
                  bottom: temEndereco
                      ? Radius.zero
                      : Radius.circular(AppRadii.externo),
                ),
                child: SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: AppMaps.map(
                    latitude: perfil.latitude!,
                    longitude: perfil.longitude!,
                    interactive: false,
                    barbearias: <BarbeariaModel>[perfil.asResumo],
                  ),
                ),
              ),
            if (temEndereco)
              Padding(
                padding: EdgeInsets.all(AppSpacing.normal),
                child: _linhaMeta(icone: Phosphor.mapPin, texto: endereco),
              ),
          ],
        ),
      ),
    );
  }

  Widget _horarios(BarbeariaPerfilModel perfil) {
    if (perfil.horarios.isEmpty) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Horários',
      child: _card(
        child: Column(
          children: perfil.horarios
              .map(
                (BarbeariaHorarioModel horario) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: appText(
                          horario.diaLabel,
                          color: local.AppColors.text,
                          fontSize: AppFontSizes.verySmall,
                          bold: true,
                        ),
                      ),
                      appText(
                        horario.horarioLabel,
                        color: horario.fechado == true
                            ? local.AppColors.statusFechado
                            : local.AppColors.textSecondary,
                        fontSize: AppFontSizes.verySmall,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _servicos(BarbeariaPerfilModel perfil) {
    if (perfil.servicos.isEmpty) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Serviços',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: perfil.servicos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.normal,
          crossAxisSpacing: AppSpacing.normal,
          mainAxisExtent: 214,
        ),
        itemBuilder: (BuildContext context, int index) {
          final BarbeariaServicoModel servico = perfil.servicos[index];
          return servicoGridCard(
            servico: servico,
            backgroundColor: local.AppColors.background,
            onTap: () => _abrirAgendamento(servicoId: servico.id),
          );
        },
      ),
    );
  }

  Widget _promocoes(BarbeariaPerfilModel perfil) {
    if (perfil.promocoes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Promoções',
      child: Column(
        children: perfil.promocoes
            .map(
              (PromocaoModel promocao) => homePromocaoCard(
                promocao: promocao,
                onTap: () {},
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _avaliacoes(BarbeariaPerfilModel perfil) {
    if (perfil.avaliacoes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Avaliações',
      child: Column(
        children: perfil.avaliacoes
            .map(
              (BarbeariaAvaliacaoModel avaliacao) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.small),
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: appText(
                              avaliacao.nomeCliente ?? 'Cliente',
                              bold: true,
                              color: local.AppColors.text,
                              fontSize: AppFontSizes.verySmall,
                            ),
                          ),
                          Icon(
                            Phosphor.star,
                            size: 14,
                            color: local.AppColors.primary,
                          ),
                          appSizedBox(width: 4),
                          appText(
                            '${avaliacao.nota ?? 0}',
                            bold: true,
                            color: local.AppColors.text,
                            fontSize: AppFontSizes.verySmall,
                          ),
                        ],
                      ),
                      if (avaliacao.comentario != null &&
                          avaliacao.comentario!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.small),
                          child: appText(
                            avaliacao.comentario!,
                            color: local.AppColors.textSecondary,
                            fontSize: AppFontSizes.verySmall,
                          ),
                        ),
                      if (avaliacao.dataLabel != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: appText(
                            avaliacao.dataLabel!,
                            color: local.AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _folha(BarbeariaPerfilModel perfil) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.giant + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identidade(perfil),
          _acoesRapidas(perfil),
          _endereco(perfil),
          _equipe(perfil),
          _servicos(perfil),
          _horarios(perfil),
          _promocoes(perfil),
          _avaliacoes(perfil),
        ],
      ),
    );
  }

  Widget _conteudo(BarbeariaPerfilModel perfil) {
    return RefreshIndicator(
      color: local.AppColors.primary,
      onRefresh: () => _loadPerfil(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: _folha(perfil),
      ),
    );
  }

  Widget _bodyTela(BarbeariaPerfilState state) {
    if (state is BarbeariaPerfilSuccessState) {
      return _conteudo(state.perfil!);
    }

    if (state is BarbeariaPerfilErrorState) {
      return Center(
        child: appError(
          state.errorModel,
          function: () => _loadPerfil(forceRefresh: true),
        ),
      );
    }

    return Center(child: appLoadingRazor());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarbeariaPerfilBloc, BarbeariaPerfilState>(
      bloc: bloc,
      builder: (BuildContext context, BarbeariaPerfilState state) {
        return scaffold(
          title: 'Detalhes',
          centerTitle: true,
          background: local.AppColors.white,
          appBarColor: local.AppColors.primary,
          safeBottom: false,
          body: _bodyTela(state),
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
