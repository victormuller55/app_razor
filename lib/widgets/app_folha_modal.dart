import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';

/// Folha padrão dos modais que sobem de baixo: alça, ícone em círculo,
/// título, subtítulo, conteúdo e os botões sempre no mesmo lugar.
class FolhaModal extends StatelessWidget {
  const FolhaModal({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icone,
    this.corIcone,
    this.centralizado = false,
    this.conteudo = const <Widget>[],
    this.acoes = const <Widget>[],
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icone;
  final Color? corIcone;

  /// Ícone em cima e textos no centro (QR Code, avaliação). Sem isso, o ícone
  /// fica ao lado do título.
  final bool centralizado;
  final List<Widget> conteudo;
  final List<Widget> acoes;

  static const double espaco = 16;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: local.AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + media.viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centralizado
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(child: _Alca()),
                const SizedBox(height: 8),
                _cabecalho(),
                for (final Widget item in conteudo) ...<Widget>[
                  const SizedBox(height: espaco),
                  item,
                ],
                if (acoes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: espaco + 8),
                  for (int i = 0; i < acoes.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: acoes[i]),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final Color cor = corIcone ?? local.AppColors.primary;
    final Widget? circulo = icone == null
        ? null
        : Container(
            width: centralizado ? 56 : 44,
            height: centralizado ? 56 : 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: centralizado ? 26 : 22, color: cor),
          );
    final TextAlign alinhamento = centralizado
        ? TextAlign.center
        : TextAlign.start;
    final Widget textos = Column(
      crossAxisAlignment: centralizado
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          textAlign: alinhamento,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: local.AppColors.text,
          ),
        ),
        if (subtitulo != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitulo!,
            textAlign: alinhamento,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13,
              height: 1.35,
              color: local.AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );

    if (centralizado) {
      return Column(
        children: <Widget>[
          if (circulo != null) ...<Widget>[circulo, const SizedBox(height: 12)],
          textos,
        ],
      );
    }

    return Row(
      children: <Widget>[
        if (circulo != null) ...<Widget>[circulo, const SizedBox(width: 14)],
        Expanded(child: textos),
      ],
    );
  }
}

class _Alca extends StatelessWidget {
  const _Alca();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 5,
        width: 44,
        decoration: BoxDecoration(
          color: AppEstilo.alca,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Aviso em bloco colorido: ícone e texto sobre um fundo leve da mesma cor.
class AvisoModal extends StatelessWidget {
  const AvisoModal({
    super.key,
    required this.texto,
    required this.icone,
    this.cor,
    this.destaque = false,
  });

  final String texto;
  final IconData icone;

  /// Sem cor, o aviso é neutro (cinza dos campos).
  final Color? cor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final Color? tom = cor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tom == null ? AppEstilo.campoFundo : tom.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icone, size: 18, color: tom ?? AppEstilo.campoIcone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13,
                height: 1.4,
                fontWeight: destaque ? FontWeight.w700 : FontWeight.w400,
                color: tom ?? local.AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
