import 'dart:async';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros_modal.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_bloc.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_event.dart';
import 'package:app_razor/pages/pesquisa_barbearias/pesquisa_barbearias_state.dart';
import 'package:app_razor/widgets/app_campo_busca.dart';
import 'package:app_razor/widgets/app_error_razor.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

const Duration _esperaDigitacao = Duration(milliseconds: 400);

class PesquisaBarbeariasPage extends StatefulWidget {
  const PesquisaBarbeariasPage({super.key});

  @override
  State<PesquisaBarbeariasPage> createState() => _PesquisaBarbeariasPageState();
}

class _PesquisaBarbeariasPageState extends State<PesquisaBarbeariasPage> {
  final PesquisaBarbeariasBloc bloc = PesquisaBarbeariasBloc();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  BarbeariasFiltros _filtros = BarbeariasFiltros.empty();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_aoRolar);
    _disparar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _controller.dispose();
    bloc.close();
    super.dispose();
  }

  void _disparar() {
    bloc.prepararConsulta();
    bloc.add(PesquisaCarregarEvent(filtros: _filtros));
  }

  void _aoDigitar(String valor) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(_esperaDigitacao, () {
      _filtros = _filtros.comBusca(valor);
      _disparar();
    });
  }

  void _limpar() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _filtros = _filtros.comBusca(null);
    });
    _disparar();
  }

  void _ordenar(String? ordenacao) {
    if (ordenacao == OrdenacaoBusca.distancia &&
        bloc.state.latitude == null) {
      showSnackbarWarning(
        message: avisoLocalizacaoNegada,
      );
      return;
    }
    final String? atual = _filtros.ordenacao;
    setState(() {
      _filtros = _filtros.comOrdenacao(atual == ordenacao ? null : ordenacao);
    });
    _voltarAoTopo();
    _disparar();
  }

  void _abrirFiltros() {
    showBarbeariasFiltrosModal(
      context: context,
      filtros: _filtros,
      avancado: true,
      temLocalizacao: bloc.state.latitude != null,
      onApply: (BarbeariasFiltros filtros) {
        setState(() {
          _filtros = filtros.comBusca(_controller.text);
        });
        _voltarAoTopo();
        _disparar();
      },
    );
  }

  void _aoRolar() {
    if (!_scroll.hasClients) {
      return;
    }
    final ScrollPosition posicao = _scroll.position;
    if (posicao.pixels >= posicao.maxScrollExtent - 240) {
      bloc.add(PesquisaCarregarMaisEvent());
    }
  }

  void _voltarAoTopo() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  void _abrir(BarbeariaModel barbearia) {
    final int? id = barbearia.id;
    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }
    FocusScope.of(context).unfocus();
    openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: local.AppColors.iconesBarraStatus,
        statusBarBrightness: local.AppColors.brilhoBarraStatus,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topo(),
              _ordenacao(),
              Expanded(
                child: BlocBuilder<PesquisaBarbeariasBloc, PesquisaBarbeariasState>(
                  bloc: bloc,
                  builder: (BuildContext context, PesquisaBarbeariasState state) {
                    return Column(
                      children: [
                        if (state.avisoLocalizacao != null) _aviso(state.avisoLocalizacao!),
                        Expanded(child: _conteudo(state)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topo() {
    final bool temTexto = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.small,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Phosphor.arrowLeft, color: local.AppColors.text, size: 24),
          ),
          Expanded(child: _campo(temTexto)),
          appSizedBox(width: AppSpacing.small),
          _botaoFiltros(),
        ],
      ),
    );
  }

  Widget _campo(bool temTexto) {
    return Container(
      height: appCampoBuscaAltura,
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: _aoDigitar,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15,
          color: local.AppColors.text,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'Barbearia, serviço, profissional ou bairro',
          hintStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 15,
            color: AppEstilo.campoIcone,
          ),
          prefixIcon: Icon(
            Phosphor.magnifyingGlass,
            size: 20,
            color: AppEstilo.campoIcone,
          ),
          suffixIcon: temTexto
              ? IconButton(
                  onPressed: _limpar,
                  icon: Icon(Phosphor.x, size: 18, color: AppEstilo.campoIcone),
                )
              : null,
        ),
      ),
    );
  }

  Widget _botaoFiltros() {
    final bool ativo = _filtros.temRefino;
    return GestureDetector(
      onTap: _abrirFiltros,
      child: Container(
        width: appCampoBuscaAltura,
        height: appCampoBuscaAltura,
        decoration: BoxDecoration(
          color: ativo ? local.AppColors.primary : AppEstilo.campoFundo,
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        ),
        child: Icon(
          Phosphor.slidersHorizontal,
          size: 20,
          color: ativo ? local.AppColors.white : local.AppColors.text,
        ),
      ),
    );
  }

  Widget _ordenacao() {
    const List<(String?, String)> opcoes = <(String?, String)>[
      (null, 'Padrão'),
      (OrdenacaoBusca.distancia, 'Perto'),
      (OrdenacaoBusca.precoAsc, 'Menor preço'),
      (OrdenacaoBusca.precoDesc, 'Maior preço'),
      (OrdenacaoBusca.avaliacao, 'Avaliação'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        itemCount: opcoes.length,
        separatorBuilder: (_, _) => appSizedBox(width: AppSpacing.small),
        itemBuilder: (BuildContext context, int index) {
          final (String? valor, String rotulo) = opcoes[index];
          final bool selecionado = _filtros.ordenacao == valor ||
              (valor == null && _filtros.ordenacao == null);
          return GestureDetector(
            onTap: () => _ordenar(valor),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selecionado ? local.AppColors.primary : AppEstilo.campoFundo,
                borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
              ),
              child: appText(
                rotulo,
                bold: selecionado,
                fontSize: 12,
                color: selecionado ? local.AppColors.white : local.AppColors.text,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _aviso(String mensagem) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.normal),
        decoration: BoxDecoration(
          color: AppEstilo.campoFundo,
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        ),
        child: appText(
          mensagem,
          fontSize: 12,
          color: local.AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _conteudo(PesquisaBarbeariasState state) {
    if (state is PesquisaLoadingState || state is PesquisaInicialState) {
      return appLoadingRazor();
    }
    if (state is PesquisaErrorState) {
      return appErrorRazor(state.errorModel, function: _disparar);
    }
    if (state is! PesquisaSuccessState) {
      return appLoadingRazor();
    }
    if (state.itens.isEmpty) {
      final String termo = _controller.text.trim();
      return Padding(
        padding: EdgeInsets.only(top: AppSpacing.giant),
        child: Align(
          alignment: Alignment.topCenter,
          child: homeEmptyState(
            message: termo.isEmpty
                ? AppStrings.nenhumaBarbeariaEncontrada
                : 'Nenhuma barbearia encontrada para "$termo"',
            icon: Phosphor.magnifyingGlass,
            iconSize: 44,
          ),
        ),
      );
    }

    final bool carregandoMais = state.loadingMore;
    return ListView.separated(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.giant,
      ),
      itemCount: state.itens.length + (carregandoMais ? 1 : 0),
      separatorBuilder: (_, _) => appSizedBox(height: AppSpacing.normal),
      itemBuilder: (BuildContext context, int index) {
        if (index >= state.itens.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final BarbeariaModel barbearia = state.itens[index];
        return homeProximaCard(
          barbearia: barbearia,
          onTap: () => _abrir(barbearia),
        );
      },
    );
  }
}
