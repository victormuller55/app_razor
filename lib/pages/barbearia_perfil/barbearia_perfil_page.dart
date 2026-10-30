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
import 'package:app_razor/pages/barbearia_perfil/widgets/galeria_fotos_viewer.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/pages/home/widgets/home_promocao_card.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:app_razor/widgets/app_error_razor.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:app_razor/widgets/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

void openBarbeariaPerfil({required int barbeariaId, String? nome}) {
  open(
    screen: BarbeariaPerfilPage(barbeariaId: barbeariaId, nomeInicial: nome),
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
  static const List<String> _diasSemana = <String>[
    'SEGUNDA',
    'TERCA',
    'QUARTA',
    'QUINTA',
    'SEXTA',
    'SABADO',
    'DOMINGO',
  ];

  late final BarbeariaPerfilBloc bloc;

  double get _margem => AppSpacing.medium + 4;

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

  // ---------------------------------------------------------------------------
  // Identidade
  // ---------------------------------------------------------------------------

  void _abrirGaleria(BarbeariaPerfilModel perfil, {int inicial = 0}) {
    if (perfil.fotos.isEmpty) {
      return;
    }
    abrirGaleriaFotos(context, fotos: perfil.fotos, inicial: inicial);
  }

  /// Capa enviada pelo gestor; sem ela, a primeira foto da galeria.
  String? _urlCapa(BarbeariaPerfilModel perfil) {
    return perfil.capa ?? (perfil.fotos.isEmpty ? null : perfil.fotos.first);
  }

  /// Fundo da capa quando a barbearia ainda não tem fotos.
  Widget _capaVazia() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [local.AppColors.primaryBrand, local.AppColors.primaryDark],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.85, -0.2),
        child: Icon(
          Phosphor.scissors,
          size: 96,
          color: local.AppColors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  Widget _seloSobreFoto({required IconData icone, required String texto}) {
    return appContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      backgroundColor: local.AppColors.primaryDark.withValues(alpha: 0.7),
      radius: BorderRadius.circular(AppRadii.interno),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: local.AppColors.white),
          appSizedBox(width: 5),
          appText(
            texto,
            bold: true,
            color: local.AppColors.white,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  /// Foto de capa com o logo da barbearia sobreposto na borda inferior.
  Widget _capa(BarbeariaPerfilModel perfil) {
    const double alturaCapa = 180;
    const double logoSize = 84;
    final String? capa = _urlCapa(perfil);
    final int totalFotos = perfil.fotos.length;

    return SizedBox(
      height: alturaCapa + logoSize / 2,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: alturaCapa,
            child: GestureDetector(
              onTap: () => _abrirGaleria(perfil),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (capa != null) imagemRedeBarbearia(capa) else _capaVazia(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          local.AppColors.primaryDark.withValues(alpha: 0.45),
                        ],
                        stops: const [0.45, 1],
                      ),
                    ),
                  ),
                  if (totalFotos > 0)
                    Positioned(
                      right: _margem,
                      bottom: AppSpacing.normal + 2,
                      child: _seloSobreFoto(
                        icone: Phosphor.images,
                        texto: totalFotos == 1 ? '1 foto' : '$totalFotos fotos',
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _margem,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: local.AppColors.surface,
                borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 10),
                boxShadow: [
                  BoxShadow(
                    color: local.AppColors.primaryDark.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: homeBarbeariaLogo(
                barbearia: perfil.asResumo,
                size: logoSize - 8,
                radius: AppEstilo.raioCampo + 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identidade(BarbeariaPerfilModel perfil) {
    final BarbeariaModel resumo = perfil.asResumo;
    final String? descricao = perfil.descricao?.trim();
    final String regiao = perfil.localDescricao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: appText(
                perfil.nome ?? AppStrings.vazio,
                bold: true,
                maxLines: 2,
                overflow: true,
                color: local.AppColors.text,
                fontSize: AppFontSizes.medium + 2,
              ),
            ),
            appSizedBox(width: AppSpacing.small + 3),
            homeStatusPill(resumo),
          ],
        ),
        if (regiao.isNotEmpty) ...[
          appSizedBox(height: 4),
          Row(
            children: [
              Icon(
                Phosphor.mapPin,
                size: 13,
                color: AppEstilo.campoIcone,
              ),
              appSizedBox(width: 3),
              Expanded(
                child: appText(
                  regiao,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        if (descricao != null && descricao.isNotEmpty) ...[
          appSizedBox(height: AppSpacing.normal + 4),
          appText(
            descricao,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
        ],
        _resumoInfo(perfil),
      ],
    );
  }

  Widget _itemResumo({required Widget valor, required String legenda}) {
    return Expanded(
      child: Column(
        children: [
          valor,
          appSizedBox(height: 3),
          appText(
            legenda,
            maxLines: 1,
            overflow: true,
            textAlign: TextAlign.center,
            color: local.AppColors.textSecondary,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  Widget _valorResumo(String texto, {Widget? leading}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, appSizedBox(width: 4)],
        Flexible(
          child: appText(
            texto,
            bold: true,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.text,
            fontSize: AppFontSizes.verySmall + 1,
          ),
        ),
      ],
    );
  }

  Widget _divisorResumo() {
    return Container(width: 1, height: 28, color: local.AppColors.divisor);
  }

  /// Faixa com nota, horário de hoje e distância (ou nº de serviços).
  Widget _resumoInfo(BarbeariaPerfilModel perfil) {
    final String nota = (perfil.nota ?? 0)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final int total = perfil.totalAvaliacoes ?? 0;
    final String? horarioHoje = perfil.horarioHoje;
    final String? distancia = homeTextoDistanciaKm(perfil.distanciaKm);

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.medium),
      child: _card(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.normal + 2,
        ),
        child: Row(
          children: [
            _itemResumo(
              valor: _valorResumo(
                nota,
                leading: const Icon(
                  PhosphorFill.star,
                  size: 14,
                  color: Color(0xFFF2B01E),
                ),
              ),
              legenda:
                  '${_formataInteiro(total)} ${total == 1 ? 'avaliação' : 'avaliações'}',
            ),
            _divisorResumo(),
            _itemResumo(
              valor: _valorResumo(horarioHoje ?? 'Fechado'),
              legenda: 'Horário de hoje',
            ),
            _divisorResumo(),
            distancia != null
                ? _itemResumo(
                    valor: _valorResumo(distancia),
                    legenda: 'De você',
                  )
                : _itemResumo(
                    valor: _valorResumo('${perfil.servicos.length}'),
                    legenda: perfil.servicos.length == 1
                        ? 'Serviço'
                        : 'Serviços',
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Blocos da folha
  // ---------------------------------------------------------------------------

  Widget _botaoAcaoRapida({
    required IconData icone,
    required String texto,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: appContainer(
          height: 72,
          backgroundColor: AppEstilo.campoFundo,
          radius: BorderRadius.circular(AppRadii.externo - 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 22, color: local.AppColors.primary),
              appSizedBox(height: 6),
              appText(
                texto,
                bold: true,
                color: local.AppColors.text,
                fontSize: 12,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acoesRapidas(BarbeariaPerfilModel perfil) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.normal),
      child: Row(
        children: [
          _botaoAcaoRapida(
            icone: Phosphor.whatsappLogo,
            texto: 'WhatsApp',
            onTap: () => _abrirWhatsApp(perfil.telefone),
          ),
          appSizedBox(width: AppSpacing.normal),
          _botaoAcaoRapida(
            icone: Phosphor.phone,
            texto: 'Ligar',
            onTap: () => _ligar(perfil.telefone),
          ),
          appSizedBox(width: AppSpacing.normal),
          _botaoAcaoRapida(
            icone: Phosphor.navigationArrow,
            texto: 'Como chegar',
            onTap: () => _abrirRota(perfil),
          ),
        ],
      ),
    );
  }

  Widget _cabecalhoSecao({
    required String titulo,
    String? contador,
    String? acao,
    VoidCallback? onAcao,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppEstilo.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        appSizedBox(width: AppSpacing.small + 3),
        appText(
          titulo,
          bold: true,
          fontSize: AppFontSizes.small + 1,
          color: local.AppColors.text,
        ),
        if (contador != null) ...[
          appSizedBox(width: 6),
          appText(
            contador,
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
        ],
        const Spacer(),
        if (acao != null)
          GestureDetector(
            onTap: onAcao,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                appText(
                  acao,
                  bold: true,
                  color: local.AppColors.primaryLight,
                  fontSize: AppFontSizes.verySmall,
                ),
                appSizedBox(width: 2),
                const Icon(
                  Phosphor.caretRight,
                  size: 14,
                  color: local.AppColors.primaryLight,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _secao({
    required String titulo,
    required Widget child,
    String? contador,
    String? acao,
    VoidCallback? onAcao,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.big),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoSecao(
            titulo: titulo,
            contador: contador,
            acao: acao,
            onAcao: onAcao,
          ),
          appSizedBox(height: AppSpacing.normal + 4),
          child,
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return appContainer(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppSpacing.normal + 4),
      backgroundColor: AppEstilo.campoFundo,
      radius: BorderRadius.circular(AppRadii.externo),
      child: child,
    );
  }

  Widget _iconeQuadrado(IconData icone) {
    return appContainer(
      width: 38,
      height: 38,
      backgroundColor: local.AppColors.surface,
      radius: BorderRadius.circular(AppRadii.interno),
      child: Center(
        child: Icon(icone, size: 18, color: local.AppColors.primary),
      ),
    );
  }

  Widget _localizacao(BarbeariaPerfilModel perfil) {
    final String endereco = perfil.enderecoCompleto?.trim().isNotEmpty == true
        ? perfil.enderecoCompleto!.trim()
        : perfil.localDescricao;
    final bool temMapa = perfil.latitude != null && perfil.longitude != null;
    final bool temEndereco = endereco.isNotEmpty;

    if (!temMapa && !temEndereco) {
      return const SizedBox.shrink();
    }

    return _secao(
      titulo: 'Localização',
      child: GestureDetector(
        onTap: () => _abrirRota(perfil),
        behavior: HitTestBehavior.opaque,
        child: _card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (temMapa)
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(AppRadii.externo),
                    bottom: temEndereco
                        ? Radius.zero
                        : const Radius.circular(AppRadii.externo),
                  ),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: IgnorePointer(
                      child: AppMaps.map(
                        latitude: perfil.latitude!,
                        longitude: perfil.longitude!,
                        interactive: false,
                        barbearias: <BarbeariaModel>[perfil.asResumo],
                      ),
                    ),
                  ),
                ),
              if (temEndereco)
                Padding(
                  padding: EdgeInsets.all(AppSpacing.normal + 2),
                  child: Row(
                    children: [
                      _iconeQuadrado(Phosphor.mapPin),
                      appSizedBox(width: AppSpacing.normal + 2),
                      Expanded(
                        child: appText(
                          endereco,
                          color: local.AppColors.text,
                          fontSize: AppFontSizes.verySmall,
                          maxLines: 2,
                          overflow: true,
                        ),
                      ),
                      appSizedBox(width: AppSpacing.small),
                      Icon(
                        Phosphor.caretRight,
                        size: 16,
                        color: AppEstilo.campoIcone,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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
          backgroundColor: local.AppColors.surface,
          radius: const BorderRadius.vertical(
            top: Radius.circular(AppEstilo.raioFolha),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _margem,
              AppSpacing.normal + 2,
              _margem,
              MediaQuery.viewPaddingOf(modalContext).bottom + AppSpacing.medium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                appFolhaAlca(),
                appSizedBox(height: AppSpacing.medium),
                _cabecalhoSecao(
                  titulo: 'Equipe',
                  contador: '${perfil.funcionarios.length}',
                ),
                appSizedBox(height: AppSpacing.normal + 4),
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _abrirAgendamento(funcionarioId: funcionario.id);
                      },
                      child: funcionarioGridCard(funcionario: funcionario),
                    );
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

    return _secao(
      titulo: 'Equipe',
      contador: '${perfil.funcionarios.length}',
      acao: perfil.funcionarios.length > 3 ? 'Ver todos' : null,
      onAcao: () => _abrirEquipeCompleta(perfil),
      child: SizedBox(
        height: 124,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: perfil.funcionarios.length,
          separatorBuilder: (_, _) => appSizedBox(width: AppSpacing.normal),
          itemBuilder: (BuildContext context, int index) {
            final BarbeariaFuncionarioModel funcionario =
                perfil.funcionarios[index];
            return GestureDetector(
              onTap: () => _abrirAgendamento(funcionarioId: funcionario.id),
              child: funcionarioListaCard(funcionario: funcionario),
            );
          },
        ),
      ),
    );
  }

  Widget _fotoServico(BarbeariaServicoModel servico) {
    const double size = 68;
    final String? imagem = servico.imagem;
    final bool temFoto = imagem != null && imagem.isNotEmpty;
    final Widget fallback = ColoredBox(
      color: local.AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          iconeServico(servico.nome),
          size: 26,
          color: local.AppColors.primary,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.interno + 4),
      child: SizedBox(
        width: size,
        height: size,
        child: temFoto
            ? Image.network(
                imagem,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _servicoLinha(BarbeariaServicoModel servico) {
    final String? descricao = servico.descricao?.trim();
    final bool temDescricao = descricao != null && descricao.isNotEmpty;
    final String? duracao = servico.duracaoLabel;

    return GestureDetector(
      onTap: () => _abrirAgendamento(servicoId: servico.id),
      behavior: HitTestBehavior.opaque,
      child: _card(
        padding: EdgeInsets.all(AppSpacing.normal),
        child: Row(
          children: [
            _fotoServico(servico),
            appSizedBox(width: AppSpacing.normal + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  appText(
                    servico.nome ?? AppStrings.vazio,
                    bold: true,
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.text,
                    fontSize: AppFontSizes.small - 1,
                  ),
                  if (temDescricao)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: appText(
                        descricao,
                        maxLines: 1,
                        overflow: true,
                        color: local.AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  appSizedBox(height: 6),
                  Row(
                    children: [
                      if (duracao != null) ...[
                        Icon(
                          Phosphor.clock,
                          size: 13,
                          color: local.AppColors.textSecondary,
                        ),
                        appSizedBox(width: 3),
                        appText(
                          duracao,
                          color: local.AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        appSizedBox(width: AppSpacing.normal),
                      ],
                      if (servico.preco != null)
                        appText(
                          formataDinheiro(servico.preco!),
                          bold: true,
                          color: local.AppColors.primary,
                          fontSize: AppFontSizes.verySmall + 1,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            appSizedBox(width: AppSpacing.small),
            appContainer(
              width: 34,
              height: 34,
              backgroundColor: local.AppColors.primary,
              radius: BorderRadius.circular(AppRadii.interno),
              child: const Center(
                child: Icon(
                  Phosphor.calendarBlank,
                  size: 16,
                  color: local.AppColors.white,
                ),
              ),
            ),
          ],
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
      contador: '${perfil.servicos.length}',
      child: Column(
        children: perfil.servicos
            .map(
              (BarbeariaServicoModel servico) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.normal),
                child: _servicoLinha(servico),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _horarios(BarbeariaPerfilModel perfil) {
    if (perfil.horarios.isEmpty) {
      return const SizedBox.shrink();
    }

    final String hoje = _diasSemana[DateTime.now().weekday - 1];

    return _secao(
      titulo: 'Horários',
      child: _card(
        padding: EdgeInsets.all(AppSpacing.small + 1),
        child: Column(
          children: perfil.horarios.map((BarbeariaHorarioModel horario) {
            final bool ehHoje = horario.diaSemana == hoje;
            final bool fechado = horario.horarioLabel == 'Fechado';

            return appContainer(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.normal,
                vertical: 9,
              ),
              backgroundColor: ehHoje
                  ? local.AppColors.surface
                  : Colors.transparent,
              radius: BorderRadius.circular(AppRadii.externo - 6),
              child: Row(
                children: [
                  appText(
                    horario.diaLabel,
                    color: ehHoje
                        ? local.AppColors.primary
                        : local.AppColors.text,
                    fontSize: AppFontSizes.verySmall,
                    bold: true,
                  ),
                  if (ehHoje) ...[
                    appSizedBox(width: 6),
                    appContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      backgroundColor: local.AppColors.primary,
                      radius: BorderRadius.circular(6),
                      child: appText(
                        'HOJE',
                        bold: true,
                        color: local.AppColors.white,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                  const Spacer(),
                  appText(
                    horario.horarioLabel,
                    bold: ehHoje,
                    color: fechado
                        ? local.AppColors.statusFechado
                        : ehHoje
                        ? local.AppColors.primary
                        : local.AppColors.textSecondary,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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
              (PromocaoModel promocao) =>
                  homePromocaoCard(promocao: promocao, onTap: () {}),
            )
            .toList(),
      ),
    );
  }

  Widget _fotoGaleria(
    BarbeariaPerfilModel perfil,
    int index, {
    int restantes = 0,
  }) {
    return GestureDetector(
      onTap: () => _abrirGaleria(perfil, inicial: index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.externo - 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imagemRedeBarbearia(perfil.fotos[index]),
            if (restantes > 0)
              ColoredBox(
                color: local.AppColors.primaryDark.withValues(alpha: 0.55),
                child: Center(
                  child: appText(
                    '+$restantes',
                    bold: true,
                    color: local.AppColors.white,
                    fontSize: AppFontSizes.medium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mosaico com a foto principal à esquerda e duas menores à direita.
  Widget _fotos(BarbeariaPerfilModel perfil) {
    final int total = perfil.fotos.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final double espaco = AppSpacing.small + 3;

    return _secao(
      titulo: 'Fotos',
      contador: '$total',
      acao: 'Ver todas',
      onAcao: () => _abrirGaleria(perfil),
      child: SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _fotoGaleria(perfil, 0)),
            if (total > 1) ...[
              appSizedBox(width: espaco),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _fotoGaleria(perfil, 1)),
                    if (total > 2) ...[
                      appSizedBox(height: espaco),
                      Expanded(
                        child: _fotoGaleria(perfil, 2, restantes: total - 3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const Color _corEstrela = Color(0xFFF2B01E);

  Widget _estrelas(int nota, {double size = 13}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        final bool cheia = index < nota;
        return Icon(
          cheia ? PhosphorFill.star : Phosphor.star,
          size: size,
          color: cheia ? _corEstrela : AppEstilo.campoIcone,
        );
      }),
    );
  }

  Widget _barraDistribuicao({
    required int estrelas,
    required int quantidade,
    required int total,
  }) {
    final double fracao = total == 0 ? 0 : quantidade / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: appText(
              '$estrelas',
              bold: true,
              color: local.AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          appSizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fracao,
                minHeight: 6,
                backgroundColor: local.AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(_corEstrela),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoAvaliacoes(
    BarbeariaPerfilModel perfil,
    List<BarbeariaAvaliacaoModel> avaliacoes,
  ) {
    final int quantidade = avaliacoes.length;
    final double media =
        perfil.nota ??
        (quantidade == 0
            ? 0
            : avaliacoes
                      .map((BarbeariaAvaliacaoModel a) => a.nota ?? 0)
                      .reduce((int a, int b) => a + b) /
                  quantidade);
    final int total = perfil.totalAvaliacoes ?? quantidade;

    return _card(
      padding: EdgeInsets.all(AppSpacing.medium - 4),
      child: Row(
        children: [
          Column(
            children: [
              appText(
                media.toStringAsFixed(1).replaceAll('.', ','),
                bold: true,
                color: local.AppColors.text,
                fontSize: 34,
              ),
              _estrelas(media.round(), size: 14),
              appSizedBox(height: 4),
              appText(
                '${_formataInteiro(total)} ${total == 1 ? 'avaliação' : 'avaliações'}',
                color: local.AppColors.textSecondary,
                fontSize: 11,
              ),
            ],
          ),
          appSizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1]
                  .map(
                    (int estrelas) => _barraDistribuicao(
                      estrelas: estrelas,
                      quantidade: avaliacoes
                          .where(
                            (BarbeariaAvaliacaoModel a) => a.nota == estrelas,
                          )
                          .length,
                      total: quantidade,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirTodasAvaliacoes(List<BarbeariaAvaliacaoModel> avaliacoes) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(modalContext).height * 0.85,
          ),
          child: appContainer(
            width: double.infinity,
            backgroundColor: local.AppColors.surface,
            radius: const BorderRadius.vertical(
              top: Radius.circular(AppEstilo.raioFolha),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _margem,
                AppSpacing.normal + 2,
                _margem,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  appFolhaAlca(),
                  appSizedBox(height: AppSpacing.medium),
                  _cabecalhoSecao(
                    titulo: 'Avaliações',
                    contador: '${avaliacoes.length}',
                  ),
                  appSizedBox(height: AppSpacing.normal + 4),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.viewPaddingOf(modalContext).bottom +
                            AppSpacing.medium,
                      ),
                      children: avaliacoes.map(_avaliacaoCard).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _avaliacaoCard(BarbeariaAvaliacaoModel avaliacao) {
    final String nome = avaliacao.nomeCliente?.trim().isNotEmpty == true
        ? avaliacao.nomeCliente!.trim()
        : 'Cliente';
    final String? comentario = avaliacao.comentario?.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                appContainer(
                  width: 36,
                  height: 36,
                  backgroundColor: local.AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  radius: BorderRadius.circular(18),
                  child: Center(
                    child: appText(
                      nome.substring(0, 1).toUpperCase(),
                      bold: true,
                      color: local.AppColors.primary,
                      fontSize: AppFontSizes.small,
                    ),
                  ),
                ),
                appSizedBox(width: AppSpacing.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appText(
                        nome,
                        bold: true,
                        maxLines: 1,
                        overflow: true,
                        color: local.AppColors.text,
                        fontSize: AppFontSizes.verySmall,
                      ),
                      if (avaliacao.dataLabel != null)
                        appText(
                          avaliacao.dataLabel!,
                          color: local.AppColors.textSecondary,
                          fontSize: 11,
                        ),
                    ],
                  ),
                ),
                _estrelas(avaliacao.nota ?? 0),
              ],
            ),
            if (comentario != null && comentario.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.normal),
                child: appText(
                  comentario,
                  color: local.AppColors.textSecondary,
                  fontSize: AppFontSizes.verySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A barbearia ainda não foi avaliada: quem conclui um serviço avalia pela agenda.
  Widget _avaliacoesVazias() {
    return appContainer(
      padding: EdgeInsets.all(AppSpacing.normal + 2),
      backgroundColor: AppEstilo.campoFundo,
      radius: BorderRadius.circular(AppRadii.externo - 4),
      child: Row(
        children: [
          const Icon(Phosphor.star, size: 22, color: _corEstrela),
          appSizedBox(width: AppSpacing.normal),
          Expanded(
            child: appText(
              'Ainda sem avaliações. Depois de um serviço concluído, os clientes avaliam pela agenda.',
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.verySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avaliacoes(BarbeariaPerfilModel perfil) {
    final List<BarbeariaAvaliacaoModel> avaliacoes = perfil.avaliacoes;

    if (avaliacoes.isEmpty) {
      return _secao(titulo: 'Avaliações', child: _avaliacoesVazias());
    }

    const int visiveis = 3;
    final int total = perfil.totalAvaliacoes ?? avaliacoes.length;

    return _secao(
      titulo: 'Avaliações',
      contador: '${total > avaliacoes.length ? total : avaliacoes.length}',
      acao: avaliacoes.length > visiveis ? 'Ver todas' : null,
      onAcao: () => _abrirTodasAvaliacoes(avaliacoes),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _resumoAvaliacoes(perfil, avaliacoes),
          appSizedBox(height: AppSpacing.normal),
          ...avaliacoes.take(visiveis).map(_avaliacaoCard),
        ],
      ),
    );
  }

  Widget _folha(BarbeariaPerfilModel perfil) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _margem,
        AppSpacing.normal + 4,
        _margem,
        AppSpacing.big,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identidade(perfil),
          _acoesRapidas(perfil),
          _servicos(perfil),
          _fotos(perfil),
          _equipe(perfil),
          _avaliacoes(perfil),
          _localizacao(perfil),
          _horarios(perfil),
          _promocoes(perfil),
        ],
      ),
    );
  }

  Widget _barraAgendar() {
    return Container(
      decoration: BoxDecoration(
        color: local.AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: local.AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        _margem,
        AppSpacing.normal + 2,
        _margem,
        AppSpacing.normal + 2 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: appElevatedButtonRazor(
        title: 'Agendar horário',
        padding: 0,
        width: double.infinity,
        onTap: _abrirAgendamento,
      ),
    );
  }

  Widget _botaoFavorito(BarbeariaPerfilModel perfil) {
    return IconButton(
      onPressed: () => bloc.add(BarbeariaPerfilFavoritoEvent()),
      icon: Icon(
        perfil.favorito == true ? PhosphorFill.heart : Phosphor.heart,
        size: 22,
        color: local.AppColors.white,
      ),
    );
  }

  Widget _telaPerfil(BarbeariaPerfilModel perfil) {
    return scaffold(
      title: 'Detalhes',
      centerTitle: true,
      background: local.AppColors.surface,
      appBarColor: local.AppColors.primaryBrand,
      safeBottom: false,
      actions: [_botaoFavorito(perfil)],
      bottomNavigationBar: _barraAgendar(),
      body: RefreshIndicator(
        color: local.AppColors.primary,
        onRefresh: () => _loadPerfil(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_capa(perfil), _folha(perfil)],
          ),
        ),
      ),
    );
  }

  Widget _bodyTela(BarbeariaPerfilState state) {
    if (state is BarbeariaPerfilErrorState) {
      return Center(
        child: appErrorRazor(
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
        final BarbeariaPerfilModel? perfil = state.perfil;
        if (perfil != null && state is! BarbeariaPerfilErrorState) {
          return _telaPerfil(perfil);
        }

        return scaffold(
          title: 'Detalhes',
          centerTitle: true,
          background: local.AppColors.surface,
          appBarColor: local.AppColors.primaryBrand,
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
