import 'package:app_razor/app_config/const/app_colors.dart' as local;
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
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/pages/home/widgets/home_promocao_card.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:flutter/material.dart';
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
      );
    } catch (_) {
      showSnackbarWarning(message: rotaMensagemIndisponivel);
    }
  }

  Future<void> _ligar(String telefone) async {
    try {
      await abrirTelefone(telefone);
    } catch (_) {
      showSnackbarWarning(message: contatoMensagemIndisponivel);
    }
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    try {
      await abrirWhatsApp(telefone);
    } catch (_) {
      showSnackbarWarning(message: contatoMensagemIndisponivel);
    }
  }

  @override
  void initState() {
    super.initState();
    bloc = BarbeariaPerfilBloc(barbeariaId: widget.barbeariaId);
    _loadPerfil();
  }

  Widget _logo(BarbeariaPerfilModel perfil) {
    const double size = 88;
    final String? logo = perfil.logo;
    final bool temFoto = logo != null && logo.isNotEmpty;
    final String nome = perfil.nome ?? '';
    final String inicial =
        nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.normal),
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

  Widget _chipInfo({
    required IconData icone,
    required String texto,
    required Color corIcone,
    required Color corTexto,
    Color? fundo,
  }) {
    return appContainer(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      backgroundColor: fundo ?? local.AppColors.inputBackground,
      radius: BorderRadius.circular(AppRadius.medium),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: corIcone),
          appSizedBox(width: 4),
          appText(
            texto,
            bold: true,
            color: corTexto,
            fontSize: 11,
            maxLines: 1,
            overflow: true,
          ),
        ],
      ),
    );
  }

  Widget _identidade(BarbeariaPerfilModel perfil) {
    final bool aberto = perfil.aberto ?? false;
    final Color corStatus = aberto
        ? local.AppColors.statusAberto
        : local.AppColors.statusFechado;
    final String status = aberto ? 'Aberto' : 'Fechado';
    final String? horario = perfil.horarioHoje;
    final String nota =
        (perfil.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
    final int? total = perfil.totalAvaliacoes;
    final String notaTexto =
        total != null && total > 0 ? '$nota ($total)' : nota;
    final String? distancia = homeTextoDistanciaKm(perfil.distanciaKm);
    final String? descricao = perfil.descricao?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logo(perfil),
            appSizedBox(width: AppSpacing.normal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            appText(
                              perfil.nome ?? AppStrings.vazio,
                              bold: true,
                              fontSize: AppFontSizes.medium,
                              color: local.AppColors.text,
                            ),
                            if (perfil.localDescricao.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: appText(
                                  perfil.localDescricao,
                                  color: local.AppColors.textSecondary,
                                  fontSize: AppFontSizes.verySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      appSizedBox(width: AppSpacing.small),
                      _chipInfo(
                        icone: Phosphor.clock,
                        texto: status,
                        corIcone: corStatus,
                        corTexto: corStatus,
                        fundo: corStatus.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        appSizedBox(height: AppSpacing.normal),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipInfo(
              icone: Phosphor.star,
              texto: notaTexto,
              corIcone: local.AppColors.primary,
              corTexto: local.AppColors.text,
            ),
            if (distancia != null)
              _chipInfo(
                icone: Phosphor.mapPin,
                texto: distancia,
                corIcone: local.AppColors.textSecondary,
                corTexto: local.AppColors.textSecondary,
              ),
            if (horario != null)
              _chipInfo(
                icone: Phosphor.clock,
                texto: horario,
                corIcone: local.AppColors.textSecondary,
                corTexto: local.AppColors.textSecondary,
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
      backgroundColor: local.AppColors.white,
      radius: BorderRadius.circular(AppRadius.normal),
      shadow: local.AppColors.cardShadow,
      child: child,
    );
  }

  Widget _botaoAcao({
    required IconData icone,
    required String texto,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 16, color: cor),
              appSizedBox(width: 6),
              appText(
                texto,
                bold: true,
                color: cor,
                fontSize: AppFontSizes.verySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoRota(BarbeariaPerfilModel perfil) {
    return _botaoAcao(
      icone: Phosphor.navigationArrow,
      texto: 'Como chegar',
      cor: local.AppColors.primary,
      onTap: () => _abrirRota(perfil),
    );
  }

  Widget _botoesContato(String telefone) {
    const Color corWhatsApp = Color(0xFF25D366);
    final bool whatsapp = ehCelularWhatsApp(telefone);

    return Row(
      children: [
        if (whatsapp) ...[
          Expanded(
            child: _botaoAcao(
              icone: Phosphor.whatsappLogo,
              texto: 'WhatsApp',
              cor: corWhatsApp,
              onTap: () => _abrirWhatsApp(telefone),
            ),
          ),
          appSizedBox(width: AppSpacing.small),
        ],
        Expanded(
          child: _botaoAcao(
            icone: Phosphor.phone,
            texto: 'Ligar',
            cor: local.AppColors.primary,
            onTap: () => _ligar(telefone),
          ),
        ),
      ],
    );
  }

  Widget _linhaInfo({
    required IconData icone,
    required String texto,
    bool destaque = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: local.AppColors.primary),
        appSizedBox(width: AppSpacing.small),
        Expanded(
          child: appText(
            texto,
            color: local.AppColors.text,
            fontSize: AppFontSizes.verySmall,
            bold: destaque,
          ),
        ),
      ],
    );
  }

  Widget _endereco(BarbeariaPerfilModel perfil) {
    final String? endereco = perfil.enderecoCompleto;
    final String? telefone = perfil.telefone;
    final bool temMapa = perfil.latitude != null && perfil.longitude != null;
    final bool temEndereco = endereco != null && endereco.isNotEmpty;
    final bool temTelefone = telefone != null && telefone.isNotEmpty;
    final bool temRota = temMapa || temEndereco;

    if (!temEndereco && !temMapa && !temTelefone) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.normal),
      child: _card(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (temMapa)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.normal - 1),
                ),
                child: SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: AppMaps.map(
                    latitude: perfil.latitude!,
                    longitude: perfil.longitude!,
                    interactive: false,
                    barbearias: <BarbeariaModel>[perfil.asResumo],
                  ),
                ),
              ),
            if (temEndereco || temTelefone || temRota)
              Padding(
                padding: EdgeInsets.all(AppSpacing.normal),
                child: Column(
                  children: [
                    if (temEndereco)
                      _linhaInfo(icone: Phosphor.mapPin, texto: endereco),
                    if (temEndereco && temTelefone)
                      appSizedBox(height: AppSpacing.small),
                    if (temTelefone)
                      _linhaInfo(
                        icone: Phosphor.phone,
                        texto: formataTelefone(telefone),
                        destaque: true,
                      ),
                    if (temTelefone) ...[
                      appSizedBox(height: AppSpacing.normal),
                      _botoesContato(telefone),
                    ],
                    if (temRota) ...[
                      if (temEndereco || temTelefone)
                        appSizedBox(height: AppSpacing.normal),
                      _botaoRota(perfil),
                    ],
                  ],
                ),
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
            onTap: () => _abrirAgendamento(
              servicoId: servico.id,
            ),
          );
        },
      ),
    );
  }

  Widget _equipe(BarbeariaPerfilModel perfil) {
    if (perfil.funcionarios.isEmpty) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Equipe',
      child: GridView.builder(
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
          return funcionarioGridCard(
            funcionario: funcionario,
            onTap: () => _abrirAgendamento(funcionarioId: funcionario.id),
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

  Widget _conteudo(BarbeariaPerfilModel perfil) {
    return RefreshIndicator(
      color: local.AppColors.primary,
      onRefresh: () => _loadPerfil(forceRefresh: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.normal,
          AppSpacing.medium,
          AppSpacing.giant,
        ),
        children: [
          _identidade(perfil),
          _endereco(perfil),
          _horarios(perfil),
          _servicos(perfil),
          _equipe(perfil),
          _promocoes(perfil),
          _avaliacoes(perfil),
        ],
      ),
    );
  }

  Widget _bodyTela(BarbeariaPerfilState state) {
    if (state is BarbeariaPerfilSuccessState) {
      return _conteudo(state.perfil!);
    }

    if (state is BarbeariaPerfilErrorState) {
      return appError(
        state.errorModel,
        function: () => _loadPerfil(forceRefresh: true),
      );
    }

    return appLoadingRazor();
  }

  List<Widget> _actions(BarbeariaPerfilState state) {
    final bool favorito = state.perfil?.favorito ?? false;

    if (!favorito) {
      return const <Widget>[];
    }

    return <Widget>[
      Padding(
        padding: EdgeInsets.only(right: AppSpacing.normal),
        child: Icon(PhosphorFill.heart, color: local.AppColors.white),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarbeariaPerfilBloc, BarbeariaPerfilState>(
      bloc: bloc,
      builder: (BuildContext context, BarbeariaPerfilState state) {
        final String titulo = state.perfil?.nome ??
            widget.nomeInicial ??
            AppStrings.barbearias;

        return scaffold(
          title: titulo,
          background: local.AppColors.background,
          appBarColor: local.AppColors.primary,
          actions: _actions(state),
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
