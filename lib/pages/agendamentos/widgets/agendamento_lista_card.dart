import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamentos/widgets/avaliar_servico_modal.dart';
import 'package:app_razor/pages/barbearia_perfil/widgets/servico_grid_card.dart';
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

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.normal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (agendamento.nomeFuncionario != null)
            _destaqueProfissional(agendamento.nomeFuncionario!),
          if (agendamento.nomeFuncionario != null)
            appSizedBox(height: AppSpacing.small),
          _cardsMetricas(agendamento),
          if (agendamento.enderecoCompleto != null) ...[
            appSizedBox(height: AppSpacing.small),
            _cardInterno(
              child: _infoLinha(
                icone: Phosphor.mapPin,
                texto: agendamento.enderecoCompleto!,
                maxLines: 2,
              ),
            ),
          ],
          if (agendamento.observacao != null) ...[
            appSizedBox(height: AppSpacing.small),
            _cardInterno(child: _observacao(agendamento.observacao!)),
          ],
          if (_avaliavel)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.normal),
              child: botaoAvaliarServico(onTap: widget.onAvaliar!),
            )
          else if (agendamento.notaAvaliacao != null) ...[
            appSizedBox(height: AppSpacing.small),
            _cardInterno(child: notaDadaAvaliacao(agendamento.notaAvaliacao!)),
          ],
          if (_temAcoes)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.normal),
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
      ),
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
          color: AppEstilo.campoFundo,
          borderRadius: raio,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _alternar,
            borderRadius: raio,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.normal + 2),
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
const double _raioCard = AppEstilo.raioCampo + 6;

/// Opacidade do card de agendamento encerrado.
const double _opacidadeEncerrado = 0.55;

/// Tira a cor da foto de agendamento encerrado (luminância Rec. 709).
const ColorFilter _cinza = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

Widget _cardInterno({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(AppSpacing.normal + 2),
    decoration: BoxDecoration(
      color: local.AppColors.surface,
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    ),
    child: child,
  );
}

Widget _cabecalho(AgendamentoModel agendamento, {required bool aberto}) {
  final String quando = <String>[
    agendamento.dataLabel,
    agendamento.horarioFaixa,
  ].where((String parte) => parte.isNotEmpty).join(' · ');

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _foto(agendamento),
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
                    agendamento.nomeServico ?? AppStrings.vazio,
                    bold: true,
                    maxLines: 2,
                    overflow: true,
                    color: local.AppColors.text,
                    fontSize: 15,
                  ),
                ),
                appSizedBox(width: 8),
                if (agendamento.pago) ...[
                  _selo('Pago', local.AppColors.statusAberto),
                  appSizedBox(width: 4),
                ],
                _status(agendamento),
              ],
            ),
            if (agendamento.nomeBarbearia != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: appText(
                  agendamento.nomeBarbearia!,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            if (quando.isNotEmpty)
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
                        quando,
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
                  if (agendamento.preco != null)
                    appText(
                      formataDinheiro(agendamento.preco!),
                      bold: true,
                      color: local.AppColors.primary,
                      fontSize: 16,
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: aberto ? 0.5 : 0,
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

Widget _cardsMetricas(AgendamentoModel agendamento) {
  final List<Widget> cards = <Widget>[];

  if (agendamento.dataLabel.isNotEmpty) {
    cards.add(
      _cardMetrica(
        rotulo: 'Data',
        valor: agendamento.dataRelativaLabel(DateTime.now()),
      ),
    );
  }

  if (agendamento.horarioFaixa.isNotEmpty) {
    cards.add(_cardMetrica(rotulo: 'Horário', valor: agendamento.horarioFaixa));
  }

  if (agendamento.duracaoLabel != null) {
    cards.add(
      _cardMetrica(rotulo: 'Duração', valor: agendamento.duracaoLabel!),
    );
  }

  if (cards.isEmpty) {
    return const SizedBox.shrink();
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < cards.length; i++) ...[
        if (i > 0) appSizedBox(width: AppSpacing.small),
        Expanded(child: cards[i]),
      ],
    ],
  );
}

Widget _cardMetrica({required String rotulo, required String valor}) {
  return appContainer(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.small,
      vertical: AppSpacing.normal,
    ),
    backgroundColor: local.AppColors.surface,
    radius: BorderRadius.circular(AppEstilo.raioCampo),
    child: Column(
      children: [
        appText(
          rotulo.toUpperCase(),
          color: local.AppColors.textSecondary,
          fontSize: 10,
          bold: true,
          textAlign: TextAlign.center,
        ),
        appSizedBox(height: 6),
        appText(
          valor,
          bold: true,
          maxLines: 2,
          overflow: true,
          textAlign: TextAlign.center,
          color: local.AppColors.text,
          fontSize: AppFontSizes.verySmall,
        ),
      ],
    ),
  );
}

Widget _destaqueProfissional(String nome) {
  return appContainer(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(AppSpacing.normal, 8, AppSpacing.normal, 8),
    backgroundColor: local.AppColors.surface,
    radius: BorderRadius.circular(AppEstilo.raioCampo),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: local.AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: appText(
            _inicial(nome),
            bold: true,
            color: local.AppColors.white,
            fontSize: AppFontSizes.verySmall,
          ),
        ),
        appSizedBox(width: AppSpacing.normal),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profissional',
                style: TextStyle(
                  color: local.AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  fontFamily: AppFonts.family,
                ),
              ),
              appSizedBox(height: 2),
              Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: local.AppColors.primary,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  fontFamily: AppFonts.family,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _inicial(String nome) {
  final String limpo = nome.trim();

  if (limpo.isEmpty) {
    return '?';
  }

  return limpo.substring(0, 1).toUpperCase();
}

Widget _infoLinha({
  required IconData icone,
  required String texto,
  int maxLines = 1,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icone, size: 14, color: local.AppColors.primary),
      appSizedBox(width: 6),
      Expanded(
        child: appText(
          texto,
          maxLines: maxLines,
          overflow: true,
          color: local.AppColors.text,
          fontSize: AppFontSizes.verySmall,
        ),
      ),
    ],
  );
}

Widget _observacao(String texto) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Phosphor.notePencil, size: 14, color: local.AppColors.textSecondary),
      appSizedBox(width: 6),
      Expanded(
        child: appText(
          texto,
          color: local.AppColors.textSecondary,
          fontSize: 11,
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

  return Column(
    children: [
      if (mostrarPagar) ...[
        SizedBox(
          width: double.infinity,
          child: _botaoAcao(
            icone: Phosphor.pixLogo,
            texto: diferenca != null
                ? 'Pagar diferença de ${formataDinheiro(diferenca)}'
                : 'Pagar com Pix',
            cor: local.AppColors.statusAberto,
            solido: true,
            onTap: onPagar,
          ),
        ),
        if (mostrarQr || mostrarChegar || mostrarEditar || mostrarCancelar)
          appSizedBox(height: AppSpacing.small),
      ],
      if (mostrarQr)
        SizedBox(
          width: double.infinity,
          child: _botaoAcao(
            icone: Phosphor.qrCode,
            texto: 'Mostrar QR Code',
            cor: local.AppColors.primary,
            solido: true,
            onTap: onMostrarQr,
          ),
        ),
      if (mostrarQr && (mostrarChegar || mostrarEditar || mostrarCancelar))
        appSizedBox(height: AppSpacing.small),
      if (mostrarChegar || mostrarEditar)
        Row(
          children: [
            if (mostrarChegar)
              Expanded(
                child: _botaoAcao(
                  icone: Phosphor.navigationArrow,
                  texto: 'Como chegar',
                  cor: local.AppColors.primary,
                  solido: !mostrarQr,
                  onTap: onComoChegar,
                ),
              ),
            if (mostrarChegar && mostrarEditar)
              appSizedBox(width: AppSpacing.small),
            if (mostrarEditar)
              Expanded(
                child: _botaoAcao(
                  icone: Phosphor.pencilSimple,
                  texto: 'Editar',
                  cor: local.AppColors.primary,
                  onTap: onEditar,
                ),
              ),
          ],
        ),
      if ((mostrarChegar || mostrarEditar) && mostrarCancelar)
        appSizedBox(height: AppSpacing.small),
      if (mostrarCancelar)
        SizedBox(
          width: double.infinity,
          child: _botaoAcao(
            icone: Phosphor.xCircle,
            texto: cancelando ? 'Cancelando...' : 'Cancelar',
            cor: const Color(0xFFB3261E),
            onTap: cancelando ? () {} : onCancelar,
          ),
        ),
    ],
  );
}

Widget _botaoAcao({
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

Widget _selo(String texto, Color cor) {
  return appContainer(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    radius: BorderRadius.circular(AppEstilo.raioCampo),
    backgroundColor: cor.withValues(alpha: 0.12),
    child: appText(texto, bold: true, color: cor, fontSize: 11),
  );
}

Widget _status(AgendamentoModel agendamento) {
  final Color cor = agendamento.cancelado
      ? const Color(0xFFB3261E)
      : agendamento.concluido || agendamento.confirmado
      ? local.AppColors.statusAberto
      : agendamento.pendente
      ? local.AppColors.primaryLight
      : local.AppColors.textSecondary;

  return appContainer(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    radius: BorderRadius.circular(AppEstilo.raioCampo),
    backgroundColor: cor.withValues(alpha: 0.12),
    child: appText(
      agendamento.statusLabel,
      bold: true,
      color: cor,
      fontSize: 11,
    ),
  );
}

Widget _foto(AgendamentoModel agendamento) {
  final String? imagem = agendamento.foto;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  final Widget foto = ClipRRect(
    borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 2),
    child: SizedBox(
      width: 76,
      height: 76,
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: 76,
              height: 76,
              errorBuilder: (_, _, _) => _fotoFallback(agendamento),
            )
          : _fotoFallback(agendamento),
    ),
  );

  return agendamento.encerrado
      ? ColorFiltered(colorFilter: _cinza, child: foto)
      : foto;
}

Widget _fotoFallback(AgendamentoModel agendamento) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [local.AppColors.primaryBrand, local.AppColors.primaryLight],
      ),
    ),
    child: Center(
      child: Icon(
        iconeServico(agendamento.nomeServico),
        size: 28,
        color: local.AppColors.white,
      ),
    ),
  );
}
