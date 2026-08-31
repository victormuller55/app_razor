import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/barbearia_perfil_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

String inicialFuncionario(String? nome) {
  if (nome == null || nome.trim().isEmpty) {
    return '?';
  }

  return nome.trim().substring(0, 1).toUpperCase();
}

Widget funcionarioGridCard({
  required BarbeariaFuncionarioModel funcionario,
  VoidCallback? onTap,
}) {
  final String? cargo = funcionario.cargo?.trim();
  final bool temCargo = cargo != null && cargo.isNotEmpty;

  return GestureDetector(
    onTap: onTap,
    child: appContainer(
    width: double.infinity,
    height: double.infinity,
    padding: EdgeInsets.fromLTRB(
      AppSpacing.small,
      AppSpacing.normal,
      AppSpacing.small,
      AppSpacing.small,
    ),
    backgroundColor: local.AppColors.white,
    radius: BorderRadius.circular(AppRadius.normal),
    shadow: local.AppColors.cardShadow,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _foto(funcionario)),
        appSizedBox(height: AppSpacing.small),
        appText(
          funcionario.nome ?? AppStrings.vazio,
          bold: true,
          maxLines: 1,
          overflow: true,
          textAlign: TextAlign.center,
          color: local.AppColors.text,
          fontSize: AppFontSizes.verySmall,
        ),
        if (temCargo)
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: appText(
              cargo,
              maxLines: 1,
              overflow: true,
              textAlign: TextAlign.center,
              color: local.AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
      ],
    ),
    ),
  );
}

Widget _foto(BarbeariaFuncionarioModel funcionario) {
  final String? imagem = funcionario.foto;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return SizedBox(
    width: 64,
    height: 64,
    child: ClipOval(
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: 64,
              height: 64,
              errorBuilder: (_, _, _) => _fotoFallback(funcionario),
            )
          : _fotoFallback(funcionario),
    ),
  );
}

Widget _fotoFallback(BarbeariaFuncionarioModel funcionario) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: appText(
        inicialFuncionario(funcionario.nome),
        bold: true,
        fontSize: AppFontSizes.medium,
        color: local.AppColors.primary,
      ),
    ),
  );
}
