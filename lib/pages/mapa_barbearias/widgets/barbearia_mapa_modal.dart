import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Tamanho da foto do card.
const double _tamanhoFoto = 92;

/// Card da barbearia selecionada no mapa. Fica por cima do mapa, sem barreira: o mapa continua
/// arrastável e tocar em outro pino troca a barbearia.
Widget barbeariaMapaCard({
  required BarbeariaModel barbearia,
  required VoidCallback onVerBarbearia,
  required VoidCallback onComoChegar,
  required VoidCallback onFechar,
}) {
  return Material(
    color: local.AppColors.surface,
    elevation: 6,
    shadowColor: Colors.black.withValues(alpha: 0.25),
    borderRadius: BorderRadius.circular(AppRadii.externo),
    child: InkWell(
      onTap: onVerBarbearia,
      borderRadius: BorderRadius.circular(AppRadii.externo),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.normal + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _foto(barbearia),
                appSizedBox(width: AppSpacing.normal + 2),
                Expanded(child: _informacoes(barbearia)),
                _botaoFechar(onFechar),
              ],
            ),
            if (barbearia.nomeServico != null) ...[
              appSizedBox(height: AppSpacing.normal),
              _servico(barbearia),
            ],
            appSizedBox(height: AppSpacing.normal + 2),
            Row(
              children: [
                Expanded(
                  child: _botao(
                    texto: 'Como chegar',
                    icone: Phosphor.navigationArrow,
                    principal: false,
                    onTap: onComoChegar,
                  ),
                ),
                appSizedBox(width: AppSpacing.normal),
                Expanded(
                  flex: 3,
                  child: _botao(
                    texto: 'Ver barbearia',
                    icone: Phosphor.storefront,
                    principal: true,
                    onTap: onVerBarbearia,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _foto(BarbeariaModel barbearia) {
  final String? logo = barbearia.logo;
  final bool temFoto = logo != null && logo.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppEstilo.raioCampo + 4),
    child: SizedBox(
      width: _tamanhoFoto,
      height: _tamanhoFoto,
      child: temFoto
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fotoFallback(barbearia),
            )
          : _fotoFallback(barbearia),
    ),
  );
}

Widget _fotoFallback(BarbeariaModel barbearia) {
  final String nome = barbearia.nome ?? '';

  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [local.AppColors.primaryBrand, local.AppColors.primaryLight],
      ),
    ),
    alignment: Alignment.center,
    child: nome.isEmpty
        ? const Icon(Phosphor.scissors, size: 32, color: local.AppColors.white)
        : appText(
            nome.substring(0, 1).toUpperCase(),
            bold: true,
            fontSize: 36,
            color: local.AppColors.white,
          ),
  );
}

Widget _informacoes(BarbeariaModel barbearia) {
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      appText(
        barbearia.nome ?? AppStrings.vazio,
        bold: true,
        maxLines: 2,
        overflow: true,
        color: local.AppColors.text,
        fontSize: 16,
      ),
      if (barbearia.localDescricao.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: appText(
            barbearia.localDescricao,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      appSizedBox(height: 6),
      Row(
        children: [
          _nota(barbearia),
          if (distancia != null) ...[
            appSizedBox(width: AppSpacing.normal),
            Icon(Phosphor.mapPin, size: 13, color: AppEstilo.campoIcone),
            appSizedBox(width: 3),
            Flexible(
              child: appText(
                distancia,
                maxLines: 1,
                overflow: true,
                color: local.AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      appSizedBox(height: 6),
      _status(barbearia),
    ],
  );
}

Widget _nota(BarbeariaModel barbearia) {
  final int total = barbearia.totalAvaliacoes ?? 0;

  if (barbearia.nota == null || total == 0) {
    return appText(
      'Sem avaliações',
      color: local.AppColors.textSecondary,
      fontSize: 12,
    );
  }

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(PhosphorFill.star, size: 13, color: Color(0xFFF2B01E)),
      appSizedBox(width: 3),
      appText(
        barbearia.nota!.toStringAsFixed(1).replaceAll('.', ','),
        bold: true,
        color: local.AppColors.text,
        fontSize: 12,
      ),
      appText(' ($total)', color: local.AppColors.textSecondary, fontSize: 12),
    ],
  );
}

Widget _status(BarbeariaModel barbearia) {
  final bool aberto = barbearia.aberto ?? false;
  final Color cor = aberto
      ? local.AppColors.statusAberto
      : local.AppColors.statusFechado;
  final String? horario = barbearia.horarioHoje;

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            appSizedBox(width: 4),
            appText(
              aberto ? 'Aberto' : 'Fechado',
              bold: true,
              color: aberto ? cor : local.AppColors.textSecondary,
              fontSize: 11,
            ),
          ],
        ),
      ),
      if (horario != null) ...[
        appSizedBox(width: AppSpacing.small + 1),
        Icon(Phosphor.clock, size: 13, color: AppEstilo.campoIcone),
        appSizedBox(width: 3),
        Flexible(
          child: appText(
            horario,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
}

/// Serviço em destaque da barbearia, com o preço "a partir de".
Widget _servico(BarbeariaModel barbearia) {
  final double? preco = barbearia.precoServico;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.normal,
      vertical: AppSpacing.small + 3,
    ),
    decoration: BoxDecoration(
      color: AppEstilo.campoFundo,
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    ),
    child: Row(
      children: [
        Icon(Phosphor.scissors, size: 16, color: local.AppColors.primary),
        appSizedBox(width: AppSpacing.small + 3),
        Expanded(
          child: appText(
            barbearia.nomeServico!,
            bold: true,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.text,
            fontSize: 13,
          ),
        ),
        if (preco != null) ...[
          appSizedBox(width: AppSpacing.small),
          appText(
            'a partir de ',
            color: local.AppColors.textSecondary,
            fontSize: 11,
          ),
          appText(
            formataDinheiro(preco),
            bold: true,
            color: local.AppColors.primary,
            fontSize: 13,
          ),
        ],
      ],
    ),
  );
}

Widget _botaoFechar(VoidCallback onFechar) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onFechar,
    child: Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppEstilo.campoFundo,
          shape: BoxShape.circle,
        ),
        child: Icon(Phosphor.x, size: 14, color: local.AppColors.textSecondary),
      ),
    ),
  );
}

Widget _botao({
  required String texto,
  required IconData icone,
  required bool principal,
  required VoidCallback onTap,
}) {
  final Color cor = principal ? local.AppColors.white : local.AppColors.primary;
  final BorderRadius raio = BorderRadius.circular(AppEstilo.raioCampo + 2);

  final Widget botao = Material(
    color: principal ? local.AppColors.primary : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: raio,
      side: principal
          ? BorderSide.none
          : BorderSide(color: local.AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: raio,
      child: SizedBox(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 17, color: cor),
            if (principal) ...[
              appSizedBox(width: 8),
              Flexible(
                child: appText(
                  texto,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: cor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  // O secundário mostra só o ícone; o texto vai no tooltip.
  return principal ? botao : Tooltip(message: texto, child: botao);
}
