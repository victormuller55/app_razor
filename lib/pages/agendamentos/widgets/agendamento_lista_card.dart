import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
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

/// Card enxuto da agenda: data, serviço, barbearia, horário, status, preço e as
/// ações. O resto (profissional, data completa, endereço, observação,
/// pagamento) fica no modal "Ver info", aberto também pelo toque no card.
class _AgendamentoListaCard extends StatelessWidget {
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

  bool get _avaliavel => onAvaliar != null && agendamento.podeAvaliar;

  /// Encerrado e sem avaliação pendente: só o toque no card abre as informações.
  bool get _soConsulta => agendamento.encerrado && !_avaliavel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius raio = BorderRadius.circular(_raioCard);
    void verInfo() =>
        showAgendamentoInfoModal(context: context, agendamento: agendamento);

    // Encerrado (cancelado, concluído ou sem comparecimento) fica com cara de desativado.
    return Opacity(
      opacity: _soConsulta ? _opacidadeEncerrado : 1,
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
            onTap: verInfo,
            borderRadius: raio,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.normal + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(agendamento, mostrarSeta: _soConsulta),
                  if (_avaliavel)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.normal + 2),
                      child: botaoAvaliarServico(onTap: onAvaliar!),
                    ),
                  if (!_soConsulta)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.normal + 2),
                      child: _acoes(
                        agendamento: agendamento,
                        onComoChegar: onComoChegar,
                        onCancelar: onCancelar,
                        onMostrarQr: onMostrarQr,
                        onPagar: onPagar,
                        onEditar: onEditar,
                        onVerInfo: verInfo,
                        cancelando: cancelando,
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

/// Informações que saíram do card: profissional, data completa, endereço,
/// observação, pagamento e avaliação dada.
void showAgendamentoInfoModal({
  required BuildContext context,
  required AgendamentoModel agendamento,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return AgendamentoInfoSheet(agendamento: agendamento);
    },
  );
}

class AgendamentoInfoSheet extends StatelessWidget {
  const AgendamentoInfoSheet({super.key, required this.agendamento});

  final AgendamentoModel agendamento;

  static const List<String> _diasExtenso = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _mesesExtenso = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// "Terça-feira, 17 de novembro de 2026".
  String? get _dataExtenso {
    final DateTime? data = agendamento.dataHora;
    if (data == null) {
      return null;
    }
    return '${_diasExtenso[data.weekday - 1]}, ${data.day} de '
        '${_mesesExtenso[data.month - 1]} de ${data.year}';
  }

  String? get _situacaoPagamento {
    if (agendamento.preco == null) {
      return null;
    }
    if (agendamento.pago) {
      return 'Pago pelo app';
    }
    if (agendamento.encerrado) {
      return null;
    }
    return 'Pagar na barbearia';
  }

  @override
  Widget build(BuildContext context) {
    final String? data = _dataExtenso;
    final String? situacao = _situacaoPagamento;
    final String? cancelamento = agendamento.cancelamentoLabel == null
        ? null
        : agendamento.canceladoPelaBarbearia &&
              agendamento.motivoCancelamento != null
        ? '${agendamento.cancelamentoLabel}: ${agendamento.motivoCancelamento}'
        : agendamento.cancelamentoLabel;

    final List<Widget> blocos = <Widget?>[
      _bloco(
        titulo: 'Atendimento',
        linhas: <Widget>[
          if (agendamento.nomeBarbearia != null)
            _linhaInfo(
              icone: Phosphor.storefront,
              rotulo: 'Barbearia',
              valor: agendamento.nomeBarbearia!,
            ),
          if (agendamento.nomeFuncionario != null)
            _linhaInfo(
              icone: Phosphor.user,
              rotulo: 'Profissional',
              valor: agendamento.nomeFuncionario!,
            ),
        ],
      ),
      _bloco(
        titulo: 'Data e horário',
        linhas: <Widget>[
          if (data != null)
            _linhaInfo(
              icone: Phosphor.calendarBlank,
              rotulo: 'Dia',
              valor: data,
            ),
          if (agendamento.horarioFaixa.isNotEmpty)
            _linhaInfo(
              icone: Phosphor.clock,
              rotulo: 'Horário',
              valor: agendamento.horarioFaixa,
            ),
          if (agendamento.duracaoLabel != null)
            _linhaInfo(
              icone: Phosphor.timer,
              rotulo: 'Duração',
              valor: agendamento.duracaoLabel!,
            ),
        ],
      ),
      _bloco(
        titulo: 'Local',
        linhas: <Widget>[
          if (agendamento.enderecoCompleto != null)
            _linhaTexto(
              icone: Phosphor.mapPin,
              texto: agendamento.enderecoCompleto!,
            ),
        ],
      ),
      _bloco(
        titulo: 'Pagamento',
        linhas: <Widget>[
          if (agendamento.preco != null)
            _linhaInfo(
              icone: Phosphor.money,
              rotulo: 'Valor',
              valor: formataDinheiro(agendamento.preco!),
              destaque: true,
            ),
          if (situacao != null)
            _linhaInfo(
              icone: agendamento.pago
                  ? Phosphor.checkCircle
                  : Phosphor.storefront,
              rotulo: 'Situação',
              valor: situacao,
              cor: agendamento.pago ? local.AppColors.statusAberto : null,
            ),
          if (agendamento.reembolsoLabel != null)
            _linhaInfo(
              icone: Phosphor.arrowCounterClockwise,
              rotulo: 'Reembolso',
              valor: agendamento.reembolsoLabel!,
              cor: corReembolso(agendamento.statusReembolso),
            ),
        ],
      ),
      _bloco(
        titulo: 'Cancelamento',
        linhas: <Widget>[
          if (cancelamento != null)
            _linhaTexto(icone: Phosphor.info, texto: cancelamento),
        ],
      ),
      _bloco(
        titulo: 'Observação',
        linhas: <Widget>[
          if (agendamento.observacao != null)
            _linhaTexto(
              icone: Phosphor.notePencil,
              texto: agendamento.observacao!,
            ),
        ],
      ),
      if (agendamento.notaAvaliacao != null)
        notaDadaAvaliacao(agendamento.notaAvaliacao!),
    ].whereType<Widget>().toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: appContainer(
        width: double.infinity,
        backgroundColor: local.AppColors.surface,
        radius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.medium,
            0,
            AppSpacing.medium,
            AppSpacing.medium + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    height: 6,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppEstilo.alca,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              appSizedBox(height: AppSpacing.small),
              _topoInfo(),
              for (final Widget bloco in blocos) ...[
                appSizedBox(height: AppSpacing.medium),
                bloco,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Data em bloco, serviço com o status e o preço, como no card.
  Widget _topoInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _blocoData(agendamento),
        appSizedBox(width: AppSpacing.normal + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              appText(
                agendamento.nomeServico ?? 'Agendamento',
                bold: true,
                maxLines: 2,
                overflow: true,
                color: local.AppColors.text,
                fontSize: 19,
              ),
              appSizedBox(height: 6),
              _selo(agendamento.statusLabel, _corStatus(agendamento)),
            ],
          ),
        ),
      ],
    );
  }

  /// Bloco cinza com título pequeno em cima e linhas separadas por divisória.
  /// Sem linhas, o bloco não aparece.
  Widget? _bloco({required String titulo, required List<Widget> linhas}) {
    if (linhas.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: appText(
            titulo.toUpperCase(),
            bold: true,
            color: local.AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppEstilo.campoFundo,
            borderRadius: BorderRadius.circular(_raioCard - 4),
          ),
          child: Column(
            children: [
              for (int i = 0; i < linhas.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 48,
                    color: local.AppColors.divisor,
                  ),
                linhas[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Ícone, rótulo à esquerda e valor à direita.
  Widget _linhaInfo({
    required IconData icone,
    required String rotulo,
    required String valor,
    bool destaque = false,
    Color? cor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppEstilo.campoIcone),
          appSizedBox(width: 16),
          appText(rotulo, color: local.AppColors.textSecondary, fontSize: 13),
          appSizedBox(width: AppSpacing.normal),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: destaque ? 15 : 13,
                fontWeight: FontWeight.w700,
                color:
                    cor ??
                    (destaque ? local.AppColors.primary : local.AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Texto longo (endereço, observação, cancelamento) ocupando a linha toda.
  Widget _linhaTexto({required IconData icone, required String texto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icone, size: 18, color: AppEstilo.campoIcone),
          ),
          appSizedBox(width: 16),
          Expanded(
            child: appText(
              texto,
              bold: true,
              maxLines: 6,
              overflow: true,
              color: local.AppColors.text,
              fontSize: 13,
            ),
          ),
        ],
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

Widget _cabecalho(AgendamentoModel agendamento, {required bool mostrarSeta}) {
  final String subtitulo = agendamento.nomeBarbearia ?? '';

  return Row(
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
                  Icon(Phosphor.clock, size: 13, color: AppEstilo.campoIcone),
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
          if (mostrarSeta) ...[
            appSizedBox(height: 6),
            Icon(Phosphor.caretRight, size: 16, color: AppEstilo.campoIcone),
          ],
        ],
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

Widget _acoes({
  required AgendamentoModel agendamento,
  VoidCallback? onComoChegar,
  VoidCallback? onCancelar,
  VoidCallback? onMostrarQr,
  VoidCallback? onPagar,
  VoidCallback? onEditar,
  required VoidCallback onVerInfo,
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
    _botaoSecundario(
      icone: Phosphor.info,
      texto: 'Ver info',
      cor: local.AppColors.primary,
      onTap: onVerInfo,
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
            color: local.AppColors.surface,
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
