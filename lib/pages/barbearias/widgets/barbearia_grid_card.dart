import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/home/widgets/home_barbearia_logo.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Raio da foto do card.
const double _raioFoto = 16;

/// Altura do bloco de texto abaixo da foto (usada pelo grid).
const double barbeariaGridCardAlturaTexto = 92;

Widget barbeariaGridCard({
  required BarbeariaModel barbearia,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: _capaCard(barbearia),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(2, AppSpacing.normal, 2, 0),
          child: _metadadosCard(barbearia),
        ),
      ],
    ),
  );
}

Widget _capaCard(BarbeariaModel barbearia) {
  final String? logo = barbearia.logo;
  final bool temFoto = logo != null && logo.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(_raioFoto),
    child: Stack(
      fit: StackFit.expand,
      children: [
        temFoto
            ? Image.network(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _capaFallback(barbearia),
              )
            : _capaFallback(barbearia),
        Positioned(
          top: AppSpacing.normal - 2,
          right: AppSpacing.normal - 2,
          child: _pillNota(barbearia),
        ),
        Positioned(
          left: AppSpacing.normal - 2,
          bottom: AppSpacing.normal - 2,
          child: _pillStatus(barbearia),
        ),
      ],
    ),
  );
}

Widget _capaFallback(BarbeariaModel barbearia) {
  final String nome = barbearia.nome ?? '';
  final String inicial =
      nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';

  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [local.AppColors.primary, local.AppColors.primaryLight],
      ),
    ),
    child: Center(
      child: nome.isEmpty
          ? const Icon(
              Phosphor.scissors,
              size: 40,
              color: local.AppColors.white,
            )
          : appText(
              inicial,
              bold: true,
              fontSize: 44,
              color: local.AppColors.white,
            ),
    ),
  );
}

Widget _pill({required List<Widget> children}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: local.AppColors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}

Widget _pillNota(BarbeariaModel barbearia) {
  final String nota =
      (barbearia.nota ?? 0).toStringAsFixed(1).replaceAll('.', ',');
  final int? total = barbearia.totalAvaliacoes;

  return _pill(
    children: [
      const Icon(
        PhosphorFill.star,
        size: 12,
        color: Color(0xFFF2B01E),
      ),
      appSizedBox(width: 4),
      appText(
        nota,
        bold: true,
        fontSize: 11,
        color: local.AppColors.text,
      ),
      if (total != null && total > 0)
        appText(
          ' ($total)',
          fontSize: 11,
          color: local.AppColors.textSecondary,
        ),
    ],
  );
}

Widget _pillStatus(BarbeariaModel barbearia) {
  final bool aberto = barbearia.aberto ?? false;
  final Color cor = aberto
      ? local.AppColors.statusAberto
      : local.AppColors.statusFechado;

  return _pill(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
      appSizedBox(width: 5),
      appText(
        aberto ? 'Aberto' : 'Fechado',
        bold: true,
        fontSize: 11,
        color: aberto ? local.AppColors.statusAberto : local.AppColors.text,
      ),
    ],
  );
}

Widget _metadadosCard(BarbeariaModel barbearia) {
  final String? servico = barbearia.nomeServico;
  final bool temServico = servico != null && servico.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      appText(
        barbearia.nome ?? AppStrings.vazio,
        bold: true,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.text,
        fontSize: 15,
      ),
      appSizedBox(height: 2),
      appText(
        barbearia.localDescricao,
        maxLines: 1,
        overflow: true,
        color: local.AppColors.textSecondary,
        fontSize: 12,
      ),
      appSizedBox(height: AppSpacing.small + 1),
      _horarioEDistancia(barbearia),
      if (temServico)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: appText(
            barbearia.precoServico != null
                ? '$servico · ${formataDinheiro(barbearia.precoServico!)}'
                : servico,
            maxLines: 1,
            overflow: true,
            color: local.AppColors.primaryLight,
            bold: true,
            fontSize: 12,
          ),
        ),
    ],
  );
}

Widget _horarioEDistancia(BarbeariaModel barbearia) {
  final String? horario = barbearia.horarioHoje;
  final String? distancia = homeTextoDistanciaKm(barbearia.distanciaKm);

  return Row(
    children: [
      if (horario != null) ...[
        const Icon(Phosphor.clock, size: 13, color: AppEstilo.campoIcone),
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
      if (horario != null && distancia != null)
        appSizedBox(width: AppSpacing.small + 1),
      if (distancia != null) ...[
        const Icon(Phosphor.mapPin, size: 13, color: AppEstilo.campoIcone),
        appSizedBox(width: 3),
        appText(
          distancia,
          maxLines: 1,
          color: local.AppColors.textSecondary,
          fontSize: 12,
        ),
      ],
    ],
  );
}
