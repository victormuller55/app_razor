import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

Widget agendamentoListaCard({
  required AgendamentoModel agendamento,
  VoidCallback? onComoChegar,
  VoidCallback? onCancelar,
  VoidCallback? onMostrarQr,
  VoidCallback? onPagar,
  VoidCallback? onAvaliar,
  VoidCallback? onEditar,
  bool cancelando = false,
}) {
  return _AgendamentoListaCard(
    key: ValueKey<String>('agendamento-${agendamento.id}'),
    agendamento: agendamento,
    onComoChegar: onComoChegar,
    onCancelar: onCancelar,
    onMostrarQr: onMostrarQr,
    onPagar: onPagar,
    onAvaliar: onAvaliar,
    onEditar: onEditar,
    cancelando: cancelando,
  );
}

class _AgendamentoListaCard extends StatefulWidget {
  const _AgendamentoListaCard({
    super.key,
    required this.agendamento,
    this.onComoChegar,
    this.onCancelar,
    this.onMostrarQr,
    this.onPagar,
    this.onAvaliar,
    this.onEditar,
    required this.cancelando,
  });

  final AgendamentoModel agendamento;
  final VoidCallback? onComoChegar;
  final VoidCallback? onCancelar;
  final VoidCallback? onMostrarQr;
  final VoidCallback? onPagar;
  final VoidCallback? onAvaliar;
  final VoidCallback? onEditar;
  final bool cancelando;

  @override
  State<_AgendamentoListaCard> createState() => _AgendamentoListaCardState();
}

class _AgendamentoListaCardState extends State<_AgendamentoListaCard>
    with SingleTickerProviderStateMixin {
  bool _aberto = false;
  late final AnimationController _fade;
  late final Animation<double> _opacidade;

  @override
  void initState() {
    super.initState();
    // Confirmado ou encerrado começa fechado: não há mais o que fazer nele,
    // a não ser avaliar o serviço concluído.
    _aberto = widget.agendamento.aguardando || _avaliavel;
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: _aberto ? 1 : 0,
    );
    _opacidade = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _alternar() {
    setState(() {
      _aberto = !_aberto;
    });

    if (_aberto) {
      _fade.forward(from: 0);
    } else {
      _fade.reverse();
    }
  }

  bool get _avaliavel {
    return widget.onAvaliar != null && widget.agendamento.podeAvaliar;
  }

  bool get _temAcoes {
    return widget.agendamento.aguardando &&
        (widget.onMostrarQr != null ||
            widget.onPagar != null ||
            widget.onComoChegar != null ||
            widget.onCancelar != null);
  }

  Widget _detalhes() {
    final AgendamentoModel agendamento = widget.agendamento;
    final String quando = <String>[
      agendamento.dataRelativaLabel(DateTime.now()),
      agendamento.horarioFaixa,
      ?agendamento.duracaoLabel,
    ].where((String parte) => parte.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.normal + 2),
          child: Divider(
            height: 1,
            thickness: 1,
            color: local.AppColors.divisor,
          ),
        ),
        if (agendamento.nomeFuncionario != null)
          _linhaDetalhe(
            icone: Phosphor.user,
            rotulo: 'Profissional',
            valor: agendamento.nomeFuncionario!,
          ),
        if (quando.isNotEmpty)
          _linhaDetalhe(icone: Phosphor.clock, rotulo: 'Quando', valor: quando),
        if (agendamento.enderecoCompleto != null)
          _linhaDetalhe(
            icone: Phosphor.mapPin,
            rotulo: 'Endereço',
            valor: agendamento.enderecoCompleto!,
            maxLines: 3,
          ),
        if (agendamento.observacao != null)
          _linhaDetalhe(
            icone: Phosphor.notePencil,
            rotulo: 'Observação',
            valor: agendamento.observacao!,
            maxLines: 4,
          ),
        if (_avaliavel)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.small),
            child: botaoAvaliarServico(onTap: widget.onAvaliar!),
          )
        else if (agendamento.notaAvaliacao != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.small),
            child: notaDadaAvaliacao(agendamento.notaAvaliacao!),
          ),
        if (_temAcoes)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.small),
            child: _acoes(
              agendamento: agendamento,
              onComoChegar: widget.onComoChegar,
              onCancelar: widget.onCancelar,
              onMostrarQr: widget.onMostrarQr,
              onPagar: widget.onPagar,
              onEditar: widget.onEditar,
              cancelando: widget.cancelando,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius raio = BorderRadius.circular(_raioCard);

    // Encerrado (cancelado, concluído ou sem comparecimento) fica com cara de desativado,
    // mas continua abrindo para consultar os detalhes.
    return Opacity(
      opacity: widget.agendamento.encerrado && !_avaliavel
          ? _opacidadeEncerrado
          : 1,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: AppSpacing.normal + 2),
        decoration: BoxDecoration(
          color: local.AppColors.surface,
          borderRadius: raio,
          border: Border.all(color: local.AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _alternar,
            borderRadius: raio,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.normal + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(widget.agendamento, aberto: _aberto),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _aberto
                          ? FadeTransition(
                              opacity: _opacidade,
                              child: _detalhes(),
                            )
                          : const SizedBox(width: double.infinity),
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

/// Raio do card de agendamento.
const double _raioCard = AppEstilo.raioCampo + 8;

/// Opacidade do card de agendamento encerrado.
const double _opacidadeEncerrado = 0.55;

const Color _vermelho = Color(0xFFB3261E);

const List<String> _diasSemana = <String>[
  'SEG',
  'TER',
  'QUA',
  'QUI',
  'SEX',
  'SÁB',
  'DOM',
];

const List<String> _meses = <String>[
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];

/// Cor do status: a mesma no ponto do card fechado e nos selos.
Color _corStatus(AgendamentoModel agendamento) {
  if (agendamento.cancelado) {
    return _vermelho;
  }

  if (agendamento.concluido || agendamento.confirmado) {
    return local.AppColors.statusAberto;
  }

  if (agendamento.pendente) {
    return local.AppColors.primaryLight;
  }

  return local.AppColors.textSecondary;
}

Widget _cabecalho(AgendamentoModel agendamento, {required bool aberto}) {
  final String? barbearia = agendamento.nomeBarbearia;
  final String? profissional = agendamento.nomeFuncionario;
  final String subtitulo = <String>[?barbearia, ?profissional].join(' · ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _blocoData(agendamento),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  agendamento.nomeServico ?? AppStrings.vazio,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.text,
                  fontSize: 15,
                ),
                if (subtitulo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: appText(
                      subtitulo,
                      maxLines: 1,
                      overflow: true,
                      color: local.AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                appSizedBox(height: 6),
                Row(
                  children: [
                    if (agendamento.horarioFaixa.isNotEmpty) ...[
                      Icon(
                        Phosphor.clock,
                        size: 13,
                        color: AppEstilo.campoIcone,
                      ),
                      appSizedBox(width: 4),
                      appText(
                        agendamento.horarioFaixa,
                        bold: true,
                        color: local.AppColors.text,
                        fontSize: 12,
                      ),
                      appSizedBox(width: AppSpacing.small + 3),
                    ],
                    Flexible(child: _status(agendamento)),
                  ],
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (agendamento.preco != null)
                appText(
                  formataDinheiro(agendamento.preco!),
                  bold: true,
                  color: local.AppColors.primary,
                  fontSize: 15,
                ),
              if (agendamento.pago)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _selo(
                    'Pago',
                    local.AppColors.statusAberto,
                    icone: Phosphor.checkCircle,
                  ),
                ),
              appSizedBox(height: 6),
              AnimatedRotation(
                turns: aberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Phosphor.caretDown,
                  size: 16,
                  color: AppEstilo.campoIcone,
                ),
              ),
            ],
          ),
        ],
      ),
      if (agendamento.reembolsoLabel != null)
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.normal),
          child: _selo(
            agendamento.reembolsoLabel!,
            corReembolso(agendamento.statusReembolso),
          ),
        ),
      if (agendamento.cancelamentoLabel != null)
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.small + 2),
          child: _aviso(
            agendamento.canceladoPelaBarbearia &&
                    agendamento.motivoCancelamento != null
                ? '${agendamento.cancelamentoLabel}: ${agendamento.motivoCancelamento}'
                : agendamento.cancelamentoLabel!,
          ),
        ),
    ],
  );
}

/// Dia da semana, dia e mês no lugar da foto: é o que o cliente procura na agenda.
Widget _blocoData(AgendamentoModel agendamento) {
  final DateTime? data = agendamento.dataHora;
  final bool apagado = agendamento.encerrado;
  final Color fundo = apagado
      ? local.AppColors.statusFechado.withValues(alpha: 0.15)
      : local.AppColors.primary.withValues(alpha: 0.1);
  final Color cor = apagado
      ? local.AppColors.textSecondary
      : local.AppColors.primary;

  return Container(
    width: 58,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: fundo,
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 4),
    ),
    child: data == null
        ? Icon(Phosphor.calendarBlank, size: 24, color: cor)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appText(
                _diasSemana[data.weekday - 1],
                bold: true,
                color: cor,
                fontSize: 10,
              ),
              appText(
                data.day.toString().padLeft(2, '0'),
                bold: true,
                color: cor,
                fontSize: 22,
              ),
              appText(
                _meses[data.month - 1],
                bold: true,
                color: cor.withValues(alpha: 0.75),
                fontSize: 10,
              ),
            ],
          ),
  );
}

Widget _linhaDetalhe({
  required IconData icone,
  required String rotulo,
  required String valor,
  int maxLines = 1,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.normal),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppEstilo.campoFundo,
            shape: BoxShape.circle,
          ),
          child: Icon(icone, size: 16, color: local.AppColors.primary),
        ),
        appSizedBox(width: AppSpacing.normal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              appText(
                rotulo,
                color: local.AppColors.textSecondary,
                fontSize: 11,
              ),
              appSizedBox(height: 1),
              appText(
                valor,
                bold: true,
                maxLines: maxLines,
                overflow: true,
                color: local.AppColors.text,
                fontSize: 13,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _aviso(String texto) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Phosphor.info, size: 14, color: local.AppColors.textSecondary),
      appSizedBox(width: 6),
      Expanded(
        child: appText(
          texto,
          maxLines: 3,
          overflow: true,
          color: local.AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    ],
  );
}

Widget _acoes({
  required AgendamentoModel agendamento,
  VoidCallback? onComoChegar,
  VoidCallback? onCancelar,
  VoidCallback? onMostrarQr,
  VoidCallback? onPagar,
  VoidCallback? onEditar,
  required bool cancelando,
}) {
  final bool mostrarPagar = onPagar != null && agendamento.podePagarPeloApp;
  final bool mostrarQr = onMostrarQr != null && agendamento.codigoQr != null;
  final bool mostrarChegar = agendamento.aguardando && onComoChegar != null;
  final bool mostrarCancelar = onCancelar != null && agendamento.podeCancelar;
  final bool mostrarEditar = onEditar != null;
  final double? diferenca = agendamento.valorAPagar;

  // Ações principais ocupam a largura toda; as secundárias ficam lado a lado, só com ícone e texto.
  final List<Widget> secundarias = <Widget>[
    if (mostrarChegar)
      _botaoSecundario(
        icone: Phosphor.navigationArrow,
        texto: 'Como chegar',
        cor: local.AppColors.primary,
        onTap: onComoChegar,
      ),
    if (mostrarEditar)
      _botaoSecundario(
        icone: Phosphor.pencilSimple,
        texto: 'Editar',
        cor: local.AppColors.primary,
        onTap: onEditar,
      ),
    if (mostrarCancelar)
      _botaoSecundario(
        icone: Phosphor.xCircle,
        texto: cancelando ? 'Cancelando...' : 'Cancelar',
        cor: _vermelho,
        onTap: cancelando ? () {} : onCancelar,
      ),
  ];

  return Column(
    children: [
      if (mostrarPagar)
        _botaoPrincipal(
          icone: Phosphor.pixLogo,
          texto: diferenca != null
              ? 'Pagar diferença de ${formataDinheiro(diferenca)}'
              : 'Pagar com Pix',
          cor: local.AppColors.statusAberto,
          onTap: onPagar,
        ),
      if (mostrarPagar && mostrarQr) appSizedBox(height: AppSpacing.small),
      if (mostrarQr)
        _botaoPrincipal(
          icone: Phosphor.qrCode,
          texto: 'Mostrar QR Code',
          cor: local.AppColors.primary,
          onTap: onMostrarQr,
        ),
      if (secundarias.isNotEmpty) ...[
        if (mostrarPagar || mostrarQr) appSizedBox(height: AppSpacing.small),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
            border: Border.all(color: local.AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < secundarias.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                      color: local.AppColors.border,
                    ),
                  Expanded(child: secundarias[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

Widget _botaoPrincipal({
  required IconData icone,
  required String texto,
  required Color cor,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    child: Material(
      color: cor,
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 17, color: local.AppColors.white),
              appSizedBox(width: 8),
              Flexible(
                child: appText(
                  texto,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.white,
                  fontSize: AppFontSizes.verySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _botaoSecundario({
  required IconData icone,
  required String texto,
  required Color cor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 18, color: cor),
          appSizedBox(height: 4),
          appText(
            texto,
            bold: true,
            maxLines: 1,
            overflow: true,
            color: cor,
            fontSize: 11,
          ),
        ],
      ),
    ),
  );
}

Widget _selo(String texto, Color cor, {IconData? icone}) {
  return appContainer(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    radius: BorderRadius.circular(AppEstilo.raioCampo),
    backgroundColor: cor.withValues(alpha: 0.12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 11, color: cor),
          appSizedBox(width: 3),
        ],
        appText(texto, bold: true, color: cor, fontSize: 10),
      ],
    ),
  );
}

/// Confirmado em verde, em processamento em amarelo/neutro, falha em vermelho.
Color corReembolso(String? status) {
  return switch (status) {
    'CONFIRMADO' => local.AppColors.statusAberto,
    'FALHOU' => _vermelho,
    _ => local.AppColors.primaryLight,
  };
}

/// Ponto colorido + texto, mais leve que um selo ao lado do horário.
Widget _status(AgendamentoModel agendamento) {
  final Color cor = _corStatus(agendamento);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
      appSizedBox(width: 5),
      Flexible(
        child: appText(
          agendamento.statusLabel,
          bold: true,
          maxLines: 1,
          overflow: true,
          color: cor,
          fontSize: 12,
        ),
      ),
    ],
  );
}
