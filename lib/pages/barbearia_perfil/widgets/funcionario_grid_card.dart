import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
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
}) {
  final String? cargo = funcionario.cargo?.trim();
  final bool temCargo = cargo != null && cargo.isNotEmpty;

  return appContainer(
    width: double.infinity,
    height: double.infinity,
    padding: EdgeInsets.fromLTRB(
      AppSpacing.small,
      AppSpacing.normal,
      AppSpacing.small,
      AppSpacing.small,
    ),
    backgroundColor: local.AppColors.white,
    radius: BorderRadius.circular(AppRadii.externo),
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
  );
}

Widget funcionarioListaCard({
  required BarbeariaFuncionarioModel funcionario,
}) {
  return appContainer(
    width: 96,
    height: 124,
    padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
    backgroundColor: local.AppColors.inputBackground,
    radius: BorderRadius.circular(AppRadii.externo),
    child: Column(
      children: [
        _foto(funcionario, size: 58),
        appSizedBox(height: 8),
        appText(
          funcionario.nome ?? AppStrings.vazio,
          bold: true,
          maxLines: 2,
          overflow: true,
          textAlign: TextAlign.center,
          color: local.AppColors.text,
          fontSize: 13,
        ),
      ],
    ),
  );
}

Widget _foto(BarbeariaFuncionarioModel funcionario, {double size = 64}) {
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
              errorBuilder: (_, _, _) => _fotoFallback(funcionario, size),
            )
          : _fotoFallback(funcionario, size),
    ),
  );
}

Widget _fotoFallback(BarbeariaFuncionarioModel funcionario, double size) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: appText(
        inicialFuncionario(funcionario.nome),
        bold: true,
        fontSize: size * 0.38,
        color: local.AppColors.primary,
      ),
    ),
  );
}
