import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/ordem_servico_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/agendamento_lista_card.dart'
    show corReembolso;
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Card da agenda para vários serviços marcados juntos: total da ordem,
/// cada serviço com seu horário e o pagamento de tudo de uma vez.
Widget ordemServicoCard({
  required OrdemServicoGrupo ordem,
  VoidCallback? onPagar,
  VoidCallback? onComoChegar,
  VoidCallback? onCancelar,
  void Function(AgendamentoModel item)? onMostrarQr,
  void Function(AgendamentoModel item)? onAvaliar,
  VoidCallback? onEditar,
  bool cancelando = false,
}) {
  return _OrdemServicoCard(
    key: ValueKey<String>('ordem-${ordem.id}'),
    ordem: ordem,
    onPagar: onPagar,
    onComoChegar: onComoChegar,
    onCancelar: onCancelar,
    onMostrarQr: onMostrarQr,
    onAvaliar: onAvaliar,
    onEditar: onEditar,
    cancelando: cancelando,
  );
}

class _OrdemServicoCard extends StatefulWidget {
  const _OrdemServicoCard({
    super.key,
    required this.ordem,
    this.onPagar,
    this.onComoChegar,
    this.onCancelar,
    this.onMostrarQr,
    this.onAvaliar,
    this.onEditar,
    required this.cancelando,
  });

  final OrdemServicoGrupo ordem;
  final VoidCallback? onPagar;
  final VoidCallback? onComoChegar;
  final VoidCallback? onCancelar;
  final void Function(AgendamentoModel item)? onMostrarQr;
  final void Function(AgendamentoModel item)? onAvaliar;
  final VoidCallback? onEditar;
  final bool cancelando;

  @override
  State<_OrdemServicoCard> createState() => _OrdemServicoCardState();
}

class _OrdemServicoCardState extends State<_OrdemServicoCard> {
  late bool _aberto = widget.ordem.aguardando || _avaliavel;

  OrdemServicoGrupo get ordem => widget.ordem;

  /// Algum serviço concluído ainda sem nota (cada um é avaliado à parte).
  bool get _avaliavel =>
      widget.onAvaliar != null &&
      widget.ordem.itens.any((AgendamentoModel item) => item.podeAvaliar);

  String get _quando {
    final AgendamentoModel primeiro = ordem.primeiro;
    final AgendamentoModel ultimo = ordem.ultimo;
    final bool mesmoDia = primeiro.dataAgendamento == ultimo.dataAgendamento;
    final String faixa = mesmoDia
        ? '${primeiro.horaLabel}–${ultimo.horaFimLabel}'
        : primeiro.horaLabel;

    return <String>[
      primeiro.dataLabel,
      faixa,
    ].where((String parte) => parte.isNotEmpty).join(' · ');
  }

  ({String texto, Color cor}) get _status {
    if (ordem.cancelada) {
      return (texto: 'Cancelada', cor: const Color(0xFFB3261E));
    }
    if (ordem.encerrada) {
      return (texto: 'Encerrada', cor: local.AppColors.textSecondary);
    }
    if (ordem.itens.every((AgendamentoModel item) => item.confirmado)) {
      return (texto: 'Confirmada', cor: local.AppColors.statusAberto);
    }
    return (texto: 'Agendada', cor: local.AppColors.primaryLight);
  }

  Widget _selo(String texto, Color cor) {
    return appContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      radius: BorderRadius.circular(AppEstilo.raioCampo),
      backgroundColor: cor.withValues(alpha: 0.12),
      child: appText(texto, bold: true, color: cor, fontSize: 11),
    );
  }

  Widget _icone() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [local.AppColors.primaryBrand, local.AppColors.primaryLight],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Phosphor.receipt, size: 26, color: local.AppColors.white),
          appSizedBox(height: 4),
          appText(
            '${ordem.itens.length} serviços',
            bold: true,
            color: local.AppColors.white,
            fontSize: 10,
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    final ({String texto, Color cor}) status = _status;
    final int pagos = ordem.pagos;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icone(),
        appSizedBox(width: AppSpacing.normal + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: appText(
                      'Ordem de serviço',
                      bold: true,
                      maxLines: 1,
                      overflow: true,
                      color: local.AppColors.text,
                      fontSize: 15,
                    ),
                  ),
                  appSizedBox(width: 8),
                  _selo(status.texto, status.cor),
                ],
              ),
              // O reembolso é da ordem (um Pix só): cada serviço traz a mesma situação.
              if (ordem.primeiro.reembolsoLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _selo(
                    ordem.primeiro.reembolsoLabel!,
                    corReembolso(ordem.primeiro.statusReembolso),
                  ),
                ),
              if (ordem.primeiro.nomeBarbearia != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: appText(
                    ordem.primeiro.nomeBarbearia!,
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Phosphor.calendarBlank,
                      size: 13,
                      color: AppEstilo.campoIcone,
                    ),
                    appSizedBox(width: 4),
                    Expanded(
                      child: appText(
                        _quando,
                        maxLines: 1,
                        overflow: true,
                        color: local.AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    appText(
                      formataDinheiro(ordem.total),
                      bold: true,
                      color: local.AppColors.primary,
                      fontSize: 16,
                    ),
                    if (pagos > 0) ...[
                      appSizedBox(width: 8),
                      _selo(
                        pagos == ordem.itens.length
                            ? 'Pago'
                            : '$pagos de ${ordem.itens.length} pagos',
                        local.AppColors.statusAberto,
                      ),
                    ],
                    const Spacer(),
                    AnimatedRotation(
                      turns: _aberto ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Phosphor.caretDown,
                        size: 18,
                        color: AppEstilo.campoIcone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(AgendamentoModel item, {required bool ultimo}) {
    final bool qr = widget.onMostrarQr != null && item.codigoQr != null;
    final bool avaliar = widget.onAvaliar != null && item.podeAvaliar;

    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : AppSpacing.small),
      child: Opacity(
        opacity: item.cancelado ? 0.5 : 1,
        child: appContainer(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.normal),
          backgroundColor: local.AppColors.surface,
          radius: BorderRadius.circular(AppEstilo.raioCampo),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    appText(
                      item.horaLabel,
                      bold: true,
                      color: local.AppColors.primary,
                      fontSize: AppFontSizes.verySmall,
                    ),
                    appText(
                      item.horaFimLabel,
                      color: local.AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.normal),
                color: local.AppColors.divisor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    appText(
                      item.nomeServico ?? AppStrings.vazio,
                      bold: true,
                      maxLines: 1,
                      overflow: true,
                      color: local.AppColors.text,
                      fontSize: AppFontSizes.verySmall,
                    ),
                    appText(
                      <String>[
                        if (item.nomeFuncionario != null)
                          'com ${item.nomeFuncionario}',
                        if (item.cancelado) 'cancelado',
                        if (item.pago) 'pago',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: true,
                      color: local.AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
              if (item.preco != null)
                appText(
                  formataDinheiro(item.preco!),
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.verySmall,
                ),
              if (avaliar) ...[
                appSizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onAvaliar!(item),
                  child: appContainer(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: corEstrelaAvaliacao.withValues(
                      alpha: 0.14,
                    ),
                    radius: BorderRadius.circular(AppEstilo.raioCampo - 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          PhosphorFill.star,
                          size: 14,
                          color: corEstrelaAvaliacao,
                        ),
                        appSizedBox(width: 4),
                        appText(
                          'Avaliar',
                          bold: true,
                          color: local.AppColors.text,
                          fontSize: 11,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (item.notaAvaliacao != null) ...[
                appSizedBox(width: 6),
                const Icon(
                  PhosphorFill.star,
                  size: 14,
                  color: corEstrelaAvaliacao,
                ),
                appSizedBox(width: 2),
                appText(
                  '${item.notaAvaliacao}',
                  bold: true,
                  color: local.AppColors.text,
                  fontSize: 11,
                ),
              ],
              if (qr) ...[
                appSizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onMostrarQr!(item),
                  child: appContainer(
                    width: 32,
                    height: 32,
                    backgroundColor: local.AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    radius: BorderRadius.circular(AppEstilo.raioCampo - 2),
                    child: Center(
                      child: Icon(
                        Phosphor.qrCode,
                        size: 16,
                        color: local.AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _botao({
    required IconData icone,
    required String texto,
    required Color cor,
    required VoidCallback onTap,
    bool solido = false,
  }) {
    final Color corConteudo = solido ? local.AppColors.white : cor;

    return Material(
      color: solido ? cor : cor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 16, color: corConteudo),
              appSizedBox(width: 6),
              appText(
                texto,
                bold: true,
                color: corConteudo,
                fontSize: AppFontSizes.verySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acoes() {
    final bool pagar = widget.onPagar != null && ordem.aPagar.isNotEmpty;
    final bool chegar = widget.onComoChegar != null && ordem.aguardando;
    final bool cancelar =
        widget.onCancelar != null && ordem.cancelaveis.isNotEmpty;
    final bool editar = widget.onEditar != null;
    final double? diferenca = ordem.diferencaAPagar;

    if (!pagar && !chegar && !cancelar && !editar) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.normal),
      child: Column(
        children: [
          if (pagar)
            SizedBox(
              width: double.infinity,
              child: _botao(
                icone: Phosphor.pixLogo,
                texto: diferenca != null
                    ? 'Pagar diferença de ${formataDinheiro(diferenca)}'
                    : 'Pagar ${formataDinheiro(ordem.totalAPagar)} com Pix',
                cor: local.AppColors.statusAberto,
                solido: true,
                onTap: widget.onPagar!,
              ),
            ),
          if (pagar && (chegar || editar || cancelar))
            appSizedBox(height: AppSpacing.small),
          if (chegar || editar)
            Row(
              children: [
                if (chegar)
                  Expanded(
                    child: _botao(
                      icone: Phosphor.navigationArrow,
                      texto: 'Como chegar',
                      cor: local.AppColors.primary,
                      solido: !pagar,
                      onTap: widget.onComoChegar!,
                    ),
                  ),
                if (chegar && editar) appSizedBox(width: AppSpacing.small),
                if (editar)
                  Expanded(
                    child: _botao(
                      icone: Phosphor.pencilSimple,
                      texto: 'Editar',
                      cor: local.AppColors.primary,
                      onTap: widget.onEditar!,
                    ),
                  ),
              ],
            ),
          if ((chegar || editar) && cancelar)
            appSizedBox(height: AppSpacing.small),
          if (cancelar)
            SizedBox(
              width: double.infinity,
              child: _botao(
                icone: Phosphor.xCircle,
                texto: widget.cancelando ? 'Cancelando...' : 'Cancelar ordem',
                cor: const Color(0xFFB3261E),
                onTap: widget.cancelando ? () {} : widget.onCancelar!,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius raio = BorderRadius.circular(AppEstilo.raioCampo + 6);

    return Opacity(
      opacity: ordem.encerrada && !_avaliavel ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: AppSpacing.normal + 2),
        decoration: BoxDecoration(
          color: AppEstilo.campoFundo,
          borderRadius: raio,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _aberto = !_aberto),
            borderRadius: raio,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.normal + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: !_aberto
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: EdgeInsets.only(top: AppSpacing.normal),
                              child: Column(
                                children: [
                                  for (int i = 0; i < ordem.itens.length; i++)
                                    _item(
                                      ordem.itens[i],
                                      ultimo: i == ordem.itens.length - 1,
                                    ),
                                  _acoes(),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
