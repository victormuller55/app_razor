import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

String inicialProfissional(String? nome) {
  if (nome == null || nome.trim().isEmpty) {
    return '?';
  }

  return nome.trim().substring(0, 1).toUpperCase();
}

/// Avatar redondo do profissional; o selecionado ganha anel e selo de check.
Widget profissionalSelectCard({
  required AgendamentoFuncionarioOpcao funcionario,
  required bool selecionado,
  required VoidCallback onTap,
}) {
  final String? cargo = funcionario.cargo?.trim();
  final String nome = funcionario.nome?.trim() ?? AppStrings.vazio;
  final String primeiroNome = nome.split(' ').first;

  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 80,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selecionado
                        ? local.AppColors.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: _foto(funcionario),
              ),
              if (selecionado)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: local.AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: local.AppColors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Phosphor.check,
                      size: 12,
                      color: local.AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          appSizedBox(height: 6),
          appText(
            primeiroNome,
            bold: true,
            maxLines: 1,
            overflow: true,
            textAlign: TextAlign.center,
            color: selecionado ? local.AppColors.primary : local.AppColors.text,
            fontSize: AppFontSizes.verySmall,
          ),
          if (cargo != null && cargo.isNotEmpty)
            appText(
              cargo,
              maxLines: 1,
              overflow: true,
              textAlign: TextAlign.center,
              color: local.AppColors.textSecondary,
              fontSize: 11,
            ),
        ],
      ),
    ),
  );
}

Widget _foto(AgendamentoFuncionarioOpcao funcionario) {
  const double size = 64;
  final String? imagem = funcionario.foto;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => _fotoFallback(funcionario),
            )
          : _fotoFallback(funcionario),
    ),
  );
}

Widget _fotoFallback(AgendamentoFuncionarioOpcao funcionario) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: appText(
        inicialProfissional(funcionario.nome),
        bold: true,
        fontSize: AppFontSizes.medium,
        color: local.AppColors.primary,
      ),
    ),
  );
}
