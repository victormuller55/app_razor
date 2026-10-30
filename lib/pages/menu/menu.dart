import 'dart:async';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/agendamentos_atualizados.dart';
import 'package:app_razor/functions/aviso_avaliacao.dart';
import 'package:app_razor/functions/lembrete_agendamento.dart';
import 'package:app_razor/functions/push_notificacoes.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/pages/agendamentos/widgets/qr_confirmacao_modal.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_page.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/barbearias/barbearias_page.dart';
import 'package:app_razor/pages/home/home_page.dart';
import 'package:app_razor/pages/perfil/perfil_page.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class MenuConst {
  static int currentIndex = 0;
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final List<Widget> _screens;
  final AvisosAtendimento _avisos = AvisosAtendimento();
  StreamSubscription<LinkAtividade>? _linksAtividade;

  bool get _iosNativo => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _selectAba(int index) {
    setState(() {
      MenuConst.currentIndex = index;
    });
  }

  void _openAbaPerfil() {
    _selectAba(3);
  }

  @override
  void initState() {
    super.initState();
    MenuConst.currentIndex = 0;
    LembreteAgendamento.instance.iniciar();
    // Depois do primeiro quadro: o aviso abre por cima do menu já montado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avisos.iniciar();
      _ouvirLinksDaAtividade();
      unawaited(
        PushNotificacoes.instance.iniciarSessao(
          aoReceber: _aoReceberPush,
          aoTocar: _aoTocarPush,
        ),
      );
    });
    _screens = <Widget>[
      HomePage(onOpenPerfil: _openAbaPerfil),
      const BarbeariasPage(),
      const AgendamentosPage(),
      const PerfilPage(),
    ];
  }

  @override
  void dispose() {
    LembreteAgendamento.instance.parar();
    unawaited(_linksAtividade?.cancel());
    _avisos.parar();
    unawaited(PushNotificacoes.instance.encerrarSessao());
    super.dispose();
  }

  /// Push com o app aberto: o banner do sistema não aparece; o aviso vem da API como os demais.
  void _aoReceberPush(Map<String, dynamic> dados) {
    unawaited(_avisos.verificar());
  }

  /// Toque no push (app em segundo plano ou fechado).
  void _aoTocarPush(Map<String, dynamic> dados) {
    if (!mounted) {
      return;
    }
    switch (destinoDoAviso(dados)) {
      case DestinoAviso.avisoNaTela:
        unawaited(_avisos.verificar());
      case DestinoAviso.agendamentos:
        _selectAba(2);
        avisarAgendamentosAtualizados();
        final int? id = idNotificacaoDoAviso(dados);
        if (id != null) {
          unawaited(_marcarLida(id));
        }
      case DestinoAviso.inicio:
        unawaited(_avisos.verificar());
    }
  }

  /// Toques na Live Activity, com o app aberto ou o link que abriu o app fechado.
  void _ouvirLinksDaAtividade() {
    _linksAtividade = LembreteAgendamento.instance.links.listen(
      (LinkAtividade link) => unawaited(_abrirLinkDaAtividade(link)),
    );
    unawaited(
      LembreteAgendamento.instance.linkPendente().then((LinkAtividade? link) {
        if (link != null) {
          unawaited(_abrirLinkDaAtividade(link));
        }
      }),
    );
  }

  /// Abre a agenda e, conforme a situação atual na API, o QR Code ou a avaliação. Chegar a hora não confirma
  /// nada: o QR só aparece para quem ainda aguarda, e quem confirma é a barbearia ao ler o código. Confirmado,
  /// cancelado ou já avaliado ficam só na agenda, que mostra a situação.
  Future<void> _abrirLinkDaAtividade(LinkAtividade link) async {
    if (!mounted) {
      return;
    }
    _selectAba(2);
    avisarAgendamentosAtualizados();
    if (link.acao == AcaoLink.abrir) {
      return;
    }

    final AgendamentoModel? item = await LembreteAgendamento.instance.buscar(
      link.idAgendamento,
    );
    if (!mounted || item == null) {
      return;
    }
    switch (link.acao) {
      case AcaoLink.qrCode:
        if (item.aguardando && item.codigoQr != null) {
          showQrConfirmacaoModal(context: context, agendamento: item);
        }
      case AcaoLink.avaliar:
        if (item.podeAvaliar) {
          final bool? enviou = await showAvaliarServicoModal(
            context: context,
            agendamento: item,
          );
          if (enviou == true) {
            avisarAgendamentosAtualizados();
          }
        }
      case AcaoLink.abrir:
        break;
    }
  }

  Future<void> _marcarLida(int id) async {
    try {
      await marcarNotificacaoLida(id: id);
    } catch (_) {}
  }

  BottomNavigationBarItem _itemNavegacao({
    required int index,
    required IconData icon,
    required IconData iconSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(
        MenuConst.currentIndex == index ? iconSelected : icon,
        size: 28,
      ),
      label: AppStrings.vazio,
    );
  }

  List<BottomNavigationBarItem> _itemsNavegacaoAndroid() {
    return <BottomNavigationBarItem>[
      _itemNavegacao(
        index: 0,
        icon: Phosphor.house,
        iconSelected: PhosphorFill.house,
      ),
      _itemNavegacao(
        index: 1,
        icon: Phosphor.storefront,
        iconSelected: PhosphorFill.storefront,
      ),
      _itemNavegacao(
        index: 2,
        icon: Phosphor.calendarBlank,
        iconSelected: PhosphorFill.calendarBlank,
      ),
      _itemNavegacao(
        index: 3,
        icon: Phosphor.user,
        iconSelected: PhosphorFill.user,
      ),
    ];
  }

  Widget _barraNavegacaoAndroid() {
    return BottomNavigationBar(
      backgroundColor: local.AppColors.primaryBrand,
      currentIndex: MenuConst.currentIndex,
      onTap: _selectAba,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: local.AppColors.white,
      unselectedItemColor: local.AppColors.white.withValues(alpha: 0.72),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
      items: _itemsNavegacaoAndroid(),
    );
  }

  Widget _barraNavegacaoIos() {
    return CNTabBar(
      currentIndex: MenuConst.currentIndex,
      onTap: _selectAba,
      tint: local.AppColors.primary,
      iconSize: 18,
      items: const <CNTabBarItem>[
        CNTabBarItem(
          label: 'Início',
          icon: CNSymbol('house'),
          activeIcon: CNSymbol('house.fill'),
        ),
        CNTabBarItem(
          label: 'Barbearias',
          icon: CNSymbol('storefront'),
          activeIcon: CNSymbol('storefront.fill'),
        ),
        CNTabBarItem(
          label: 'Agenda',
          icon: CNSymbol('calendar'),
          activeIcon: CNSymbol('calendar'),
        ),
        CNTabBarItem(
          label: 'Perfil',
          icon: CNSymbol('person'),
          activeIcon: CNSymbol('person.fill'),
        ),
      ],
    );
  }

  Widget _bodyTela() {
    return IndexedStack(index: MenuConst.currentIndex, children: _screens);
  }

  @override
  Widget build(BuildContext context) {
    if (_iosNativo) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: local.AppColors.background,
          body: Stack(
            children: <Widget>[
              Positioned.fill(child: _bodyTela()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _barraNavegacaoIos(),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: local.AppColors.background,
        body: _bodyTela(),
        bottomNavigationBar: _barraNavegacaoAndroid(),
      ),
    );
  }
}
